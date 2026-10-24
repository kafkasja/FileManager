import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/reviewed/data/reviewed_repository.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/media_view.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_feedback.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/swipe/ui/swipe_toast.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/features/swipe/ui/video_surface.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_viewer.g.dart';

/// Hero tag shared by the deck card and the viewer.
String fileHeroTag(FileRef f) => 'file-${f.id}';

/// Full-resolution decode is capped on the long side (100 MP photos).
const kViewerMaxDecodePx = 4096;

/// True while the fullscreen viewer is open (the deck hides undo then).
@Riverpod(keepAlive: true)
class ViewerOpen extends _$ViewerOpen {
  @override
  bool build() => false;

  void opened() => state = true;

  void closed() => state = false;
}

/// Opens [file] fullscreen over the whole app (root navigator, so the tab
/// bar is covered). The deck stays mounted underneath (non-opaque route),
/// so nothing is lost or reloaded (S3).
Future<void> openViewer(
  BuildContext context,
  FileRef file, {
  bool swipeable = true,
  String? title,
  List<Widget> actions = const [],
}) async {
  final open = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(viewerOpenProvider.notifier)..opened();
  try {
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, _, _) => FileViewer(
          file: file,
          swipeable: swipeable,
          title: title,
          actions: actions,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  } finally {
    open.closed();
  }
}

/// Fullscreen viewer: pinch / double-tap zoom, swiping works like the deck
/// when not zoomed (and shows the next file), ✕ close button top-start that
/// never hides. Reusable read-only (B7, N7) with [swipeable] false.
class FileViewer extends ConsumerStatefulWidget {
  const new({
    required this.file,
    this.swipeable = true,
    this.title,
    this.actions = const [],
    super.key,
  });

  /// Info bar name instead of [FileRef.name] (H3: a trashed file's
  /// original name).
  final String? title;

  /// Read-only only: buttons at the bottom-end, e.g. Restore (H3).
  final List<Widget> actions;

  /// The file shown first (and always, when not [swipeable]).
  final FileRef file;

  /// Follow the swipe deck: swipes act on it and the next file appears.
  final bool swipeable;

  @override
  ConsumerState<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends ConsumerState<FileViewer> {
  final TransformationController _zoom = TransformationController();

  /// H3: the same "→ Trash" pill as on the deck.
  final SwipeToastController _toast = SwipeToastController();
  bool _chrome = true;
  double? _pinchBase;
  String? _shownId;

  static const _doubleTapScale = 2.5;
  static const _maxScale = 8.0;

  double get _scale => _zoom.value.getMaxScaleOnAxis();
  bool get _zoomed => _scale > 1.01;

  @override
  void dispose() {
    _zoom.dispose();
    _toast.dispose();
    super.dispose();
  }

  void _setZoom(double scale, Offset focal) {
    final s = scale.clamp(1.0, _maxScale);
    _zoom.value = Matrix4.diagonal3Values(s, s, 1)
      ..setTranslationRaw(-focal.dx * (s - 1), -focal.dy * (s - 1), 0);
  }

  void _toggleZoom(TapDownDetails d) {
    setState(() {
      if (_zoomed) {
        _zoom.value = Matrix4.identity();
      } else {
        _setZoom(_doubleTapScale, d.localPosition);
      }
    });
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final deck = widget.swipeable
        ? ref.watch(swipeDeckControllerProvider).value
        : null;
    // Keeps the vibration setting loaded, so a swipe never reads a default.
    if (widget.swipeable) ref.watch(hapticsEnabledProvider);
    final file = widget.swipeable ? deck?.current : widget.file;
    if (file == null) {
      // The deck ran out while the viewer was open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _close();
      });
      return const ColoredBox(color: Colors.black);
    }

    if (_shownId != file.id) {
      // Next file after a swipe: start unzoomed.
      _shownId = file.id;
      _zoom.value = Matrix4.identity();
    }

    final image = Hero(
      tag: fileHeroTag(file),
      child: _ViewerImage(key: ValueKey(file.id), file: file),
    );

    final Widget content;
    if (_zoomed) {
      content = InteractiveViewer(
        transformationController: _zoom,
        maxScale: _maxScale,
        onInteractionEnd: (_) => setState(() {}),
        child: GestureDetector(
          onTap: () => setState(() => _chrome = !_chrome),
          onDoubleTapDown: _toggleZoom,
          onDoubleTap: () {},
          child: image,
        ),
      );
    } else {
      content = SwipeCard(
        key: ValueKey('viewer:${file.id}'),
        canSwipe: (d) => deck != null && SwipeFeedback.canSwipe(ref, deck, d),
        onBlocked: (d) => SwipeFeedback.blocked(context, ref, d),
        verticalEnabled: deck?.session.layout.hasVertical ?? false,
        // H3: label, vibration, hint and tick like on the deck (S4).
        hintFor: deck == null
            ? null
            : (d) => SwipeFeedback.hintFor(context, ref, deck, d),
        onThresholdCrossed: () => SwipeFeedback.tick(ref),
        onSwiped: (d) {
          if (deck?.session.layout.actionFor(d) case final action?) {
            SwipeFeedback.apply(context, ref, deck!, _toast, action);
          }
        },
        // Video: tap = sound (S5); images: tap toggles the info bar.
        onTap: file.kind == FileKind.video
            ? ref.read(videoMutedProvider.notifier).toggle
            : () => setState(() => _chrome = !_chrome),
        onDoubleTapDown: _toggleZoom,
        onPinchUpdate: (d) {
          _pinchBase ??= _scale;
          _setZoom(_pinchBase! * d.scale, d.localFocalPoint);
        },
        onPinchEnd: () => setState(() => _pinchBase = null),
        child: AnimatedBuilder(
          animation: _zoom,
          builder: (_, child) =>
              Transform(transform: _zoom.value, child: child),
          child: image,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (_chrome) _InfoBar(file: file, title: widget.title),
          if (!widget.swipeable && widget.actions.isNotEmpty)
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: widget.actions,
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 72),
                child: SwipeToast(controller: _toast),
              ),
            ),
          ),
          const ViewerCloseButton(),
        ],
      ),
    );
  }
}

/// The display-size image (already cached by the deck → instant), then the
/// full-resolution one fading in over it. Undecodable → thumbnail / icon.
class _ViewerImage extends StatelessWidget {
  const new({required this.file, super.key});

  final FileRef file;

  @override
  Widget build(BuildContext context) {
    if (file.kind == FileKind.video) {
      // Same pooled player as the card: playback continues (S5).
      return VideoSurface(file: file, active: true);
    }
    if (file.kind != FileKind.image) {
      return Thumbnail(
        file: file,
        fit: BoxFit.contain,
        background: Colors.black,
      );
    }
    final widthPx =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    return Stack(
      fit: StackFit.expand,
      children: [
        Thumbnail(file: file, fit: BoxFit.contain, background: Colors.black),
        Image(
          image: displayImageProvider(file, widthPx),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        Image(
          image: ResizeImage(
            FileImage(File(file.path)),
            width: kViewerMaxDecodePx,
            height: kViewerMaxDecodePx,
            policy: ResizeImagePolicy.fit,
          ),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSync) => AnimatedOpacity(
            opacity: wasSync || frame != null ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: child,
          ),
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _InfoBar extends ConsumerWidget {
  const new({required this.file, this.title});

  final FileRef file;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Colors.white);
    final labels = ref.watch(reviewedLabelsForProvider(file)).value ?? const [];
    final presets = ref.watch(presetsProvider).value ?? const [];
    String presetName(int key) => key == 0
        ? l10n.presetBasic
        : presets.where((p) => p.id == key).firstOrNull?.name ?? '?';
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Container(
        width: double.infinity,
        color: Colors.black54,
        padding: EdgeInsetsDirectional.fromSTEB(
          72,
          MediaQuery.paddingOf(context).top + 12,
          16,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              [
                title ?? file.name,
                formatBytes(file.sizeBytes, locale: locale),
                formatDate(file.sortDate, locale: locale),
              ].join('  ·  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text,
            ),
            for (final label in labels)
              Text(
                l10n.reviewedInfoLine(
                  presetName(label.presetKey),
                  _actionText(l10n, label),
                  formatDate(label.reviewedAt, locale: locale),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text,
              ),
          ],
        ),
      ),
    );
  }

  static String _actionText(AppLocalizations l, ReviewedLabel label) {
    final type = SwipeActionType.values.asNameMap()[label.actionType];
    if (type == null) return label.actionType;
    return actionLabel(
      l,
      SwipeAction(type, targetFolder: label.actionDetail),
      tagName: label.actionDetail,
    );
  }
}

/// ✕ at the top-start corner: white on a dark circle (visible on any photo),
/// ≥48 dp target, never hidden, and nothing like the undo arrow (S3).
class ViewerCloseButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 12,
      top: MediaQuery.paddingOf(context).top + 8,
      child: Semantics(
        button: true,
        label: context.l10n.viewerClose,
        child: IconButton(
          tooltip: context.l10n.viewerClose,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}
