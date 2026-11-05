import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/cloud/ui/cloud_badge.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/connect/ui/remote_image_provider.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
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
  // N8: the pushed viewer swipes the same deck as the screen it came from.
  final scope = context.getInheritedWidgetOfExactType<SwipeDeckScope>();
  try {
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, _, _) {
          final viewer = FileViewer(
            file: file,
            swipeable: swipeable,
            title: title,
            actions: actions,
          );
          return scope == null
              ? viewer
              : SwipeDeckScope(
                  sourceId: scope.sourceId,
                  deviceName: scope.deviceName,
                  child: viewer,
                );
        },
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
        ? ref.watch(SwipeDeckScope.providerOf(context)).value
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
        // Video: tap = play / pause (the pill's icon mutes); images: tap
        // toggles the info bar.
        onTap: file.kind == FileKind.video
            ? () => ref.read(videoPausedProvider.notifier).toggle(file.id)
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

    final scaffold = Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (_chrome) _InfoBar(file: file, title: widget.title, endInset: 72),
          // B10: ⓘ top-end, clear of the scrub bar and the Restore buttons.
          if (_chrome)
            PositionedDirectional(
              end: 12,
              top: MediaQuery.paddingOf(context).top + 8,
              child: _DetailsButton(file: file),
            ),
          if (!widget.swipeable && widget.actions.isNotEmpty)
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  // Scrolls sideways instead of overflowing on narrow
                  // screens; never shrinks the 48 dp buttons (E4, A3).
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: widget.actions,
                    ),
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
    // Desktop: Space plays / pauses a video.
    return ref.watch(formFactorProvider).isDesktop
        ? DesktopVideoKeys(file: file, child: scaffold)
        : scaffold;
  }
}

/// What a paged viewer flips through (B7). Browse: B1's `FilePages`.
/// Selection: ids in selection order → `MediaIndexDao.byIds`, 200 per page.
abstract interface class PagedViewerSource {
  List<FileRef> get items;
  bool get hasMore;
  Future<void> loadMore();

  /// [items] / [hasMore] changed.
  Listenable get changes;
}

/// Builds the page for files that aren't images or videos (B7: text body,
/// info card with "Open with").
typedef ViewerPageBuilder = Widget Function(BuildContext context, FileRef file);

/// Bottom-end buttons for the shown page (B7: Select / Remove).
typedef ViewerActionsBuilder = List<Widget> Function(
  BuildContext context,
  FileRef file,
);

/// Opens a read-only viewer that pages through [source] from
/// [initialIndex] (B7). Same route as [openViewer]: everything underneath
/// stays mounted. Completes with the last file shown (null if none).
Future<FileRef?> openPagedViewer(
  BuildContext context, {
  required PagedViewerSource source,
  required int initialIndex,
  required ViewerPageBuilder otherPage,
  ViewerActionsBuilder? actions,
}) async {
  final open = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(viewerOpenProvider.notifier)..opened();
  FileRef? last;
  try {
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, _, _) => PagedFileViewer(
          source: source,
          initialIndex: initialIndex,
          otherPage: otherPage,
          actions: actions,
          onShown: (f) => last = f,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  } finally {
    open.closed();
  }
  return last;
}

/// B7's paged preview: swipe left/right through [source], pinch / double-tap
/// zoom per page (paging stops while zoomed), videos paused until ▶.
class PagedFileViewer extends ConsumerStatefulWidget {
  const new({
    required this.source,
    required this.initialIndex,
    required this.otherPage,
    this.actions,
    this.onShown,
    super.key,
  });

  final PagedViewerSource source;
  final int initialIndex;
  final ViewerPageBuilder otherPage;
  final ViewerActionsBuilder? actions;

  /// Every page change (and the first page).
  final ValueChanged<FileRef>? onShown;

  @override
  ConsumerState<PagedFileViewer> createState() => _PagedFileViewerState();
}

class _PagedFileViewerState extends ConsumerState<PagedFileViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  String? _shownId;
  bool _zoomed = false;
  bool _chrome = true;

  /// Load the next page this close to the end.
  static const _prefetch = 3;

  List<FileRef> get _items => widget.source.items;

  @override
  void initState() {
    super.initState();
    widget.source.changes.addListener(_onSourceChanged);
    _shownId = _items.elementAtOrNull(_index)?.id;
    if (_items.elementAtOrNull(_index) case final f?) widget.onShown?.call(f);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _afterPageChange();
    });
  }

  @override
  void dispose() {
    widget.source.changes.removeListener(_onSourceChanged);
    _pages.dispose();
    super.dispose();
  }

  void _onSourceChanged() {
    if (!mounted) return;
    final items = _items;
    if (items.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    // A reload can shift the list: stay on the same file.
    final at = items.indexWhere((f) => f.id == _shownId);
    final target = at >= 0 ? at : _index.clamp(0, items.length - 1);
    setState(() => _index = target);
    if (_pages.hasClients && _pages.page?.round() != target) {
      _pages.jumpToPage(target);
    }
  }

  void _onPageChanged(int i) {
    setState(() {
      _index = i;
      _zoomed = false;
      _shownId = _items.elementAtOrNull(i)?.id;
    });
    if (_items.elementAtOrNull(i) case final f?) widget.onShown?.call(f);
    _afterPageChange();
  }

  void _afterPageChange() {
    final items = _items;
    if (widget.source.hasMore && _index >= items.length - _prefetch) {
      final messenger = ScaffoldMessenger.of(context);
      final error = context.l10n.browseLoadError;
      unawaited(
        widget.source.loadMore().catchError((Object _) {
          messenger.showSnackBar(SnackBar(content: Text(error)));
        }),
      );
    }
    // Neighbours ±1: display size only, never the 4096 px decode.
    final widthPx =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    final remote = ref.read(remoteMediaAccessProvider);
    for (final i in [_index - 1, _index + 1]) {
      if (i < 0 || i >= items.length) continue;
      final f = items[i];
      if (f.kind != FileKind.image) continue;
      unawaited(
        precacheImage(
          displayImageProvider(f, widthPx, remote: remote),
          context,
          onError: (_, _) {},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final file = items.elementAtOrNull(_index);
    final actions = file == null
        ? const <Widget>[]
        : widget.actions?.call(context, file) ?? const <Widget>[];
    final scaffold = Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pages,
            physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
            itemCount: items.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) {
              final f = items[i];
              return _ViewerPage(
                key: ValueKey(f.id),
                file: f,
                otherPage: widget.otherPage,
                onZoomChanged: (z) {
                  if (i == _index && z != _zoomed) setState(() => _zoomed = z);
                },
                onTap: () => setState(() => _chrome = !_chrome),
              );
            },
          ),
          if (_chrome && file != null && file.isMedia) _InfoBar(file: file),
          if (_chrome && file != null)
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  // Scrolls sideways instead of overflowing on narrow
                  // screens; never shrinks the 48 dp buttons (E4, A3).
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        _DetailsButton(file: file),
                        ...actions,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const ViewerCloseButton(),
        ],
      ),
    );
    // Desktop: Space plays / pauses a video.
    return ref.watch(formFactorProvider).isDesktop
        ? DesktopVideoKeys(file: file, child: scaffold)
        : scaffold;
  }
}

/// One page: zoomable image, paused video with ▶, or [otherPage]; "no
/// longer exists" when the file is gone.
class _ViewerPage extends ConsumerStatefulWidget {
  const new({
    required this.file,
    required this.otherPage,
    required this.onZoomChanged,
    required this.onTap,
    super.key,
  });

  final FileRef file;
  final ViewerPageBuilder otherPage;
  final ValueChanged<bool> onZoomChanged;
  final VoidCallback onTap;

  @override
  ConsumerState<_ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<_ViewerPage> {
  final TransformationController _zoom = TransformationController();
  bool _playing = false;
  bool _gone = false;

  static const _doubleTapScale = 2.5;
  static const _maxScale = 8.0;

  bool get _zoomed => _zoom.value.getMaxScaleOnAxis() > 1.01;

  @override
  void initState() {
    super.initState();
    // Desktop: an opened video plays at once (click / Space pause it);
    // the phone waits for ▶ (B7).
    _playing = ref.read(formFactorProvider).isDesktop;
    unawaited(_checkExists());
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _checkExists() async {
    try {
      final file = widget.file;
      // N7: a connected device's file is checked on that device.
      final source = file.origin == FileOrigin.remote
          ? ref.read(
              remoteSourceProvider(parseRemoteFileId(file.id).peerFingerprint),
            )
          : ref.read(fileSourceProvider);
      final f = await source.stat(file.id);
      if (mounted && f == null) setState(() => _gone = true);
    } on Object {
      // Can't tell: show the file as usual (its own error placeholders).
    }
  }

  void _toggleZoom(TapDownDetails d) {
    if (_zoomed) {
      _zoom.value = Matrix4.identity();
    } else {
      const s = _doubleTapScale;
      final p = d.localPosition;
      _zoom.value = Matrix4.diagonal3Values(s, s, 1)
        ..setTranslationRaw(-p.dx * (s - 1), -p.dy * (s - 1), 0);
    }
    widget.onZoomChanged(_zoomed);
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    if (_gone) {
      return Center(
        child: Text(
          context.l10n.previewFileGone,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    if (!file.isMedia) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 64),
            child: widget.otherPage(context, file),
          ),
        ),
      );
    }
    final image = Hero(
      tag: fileHeroTag(file),
      child: _ViewerImage(file: file, videoActive: _playing, paged: true),
    );
    if (file.kind == FileKind.video) {
      return GestureDetector(
        onTap: _playing
            ? () => ref.read(videoPausedProvider.notifier).toggle(file.id)
            : () => setState(() => _playing = true),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (!_playing)
              Center(
                child: Semantics(
                  button: true,
                  label: context.l10n.previewPlay,
                  child: const Icon(
                    Icons.play_circle_fill,
                    size: 72,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 8)],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return InteractiveViewer(
      transformationController: _zoom,
      maxScale: _maxScale,
      onInteractionEnd: (_) => widget.onZoomChanged(_zoomed),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTapDown: _toggleZoom,
        onDoubleTap: () {},
        child: image,
      ),
    );
  }
}

/// ⓘ: the B10 details sheet (B7 showed a short fact list).
class _DetailsButton extends StatelessWidget {
  const new({required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      tooltip: l10n.previewDetails,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.info_outline),
      onPressed: () => unawaited(showFileDetails(context, file)),
    );
  }
}

/// The file's facts as list tiles (B7's details sheet and info card).
class FileDetailsList extends StatelessWidget {
  const new({required this.file, super.key});

  final FileRef file;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final (w, h, ms) = (file.width, file.height, file.durationMs);
    final taken = file.takenAt;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(file.name)),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: Text(formatBytes(file.sizeBytes, locale: locale)),
          ),
          if (w != null && h != null && w > 0 && h > 0)
            ListTile(
              leading: const Icon(Icons.aspect_ratio),
              title: Text(l10n.previewDimensions(w, h)),
            ),
          if (ms != null && ms > 0)
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(formatDuration(Duration(milliseconds: ms))),
            ),
          if (taken != null)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.previewTaken(formatDate(taken, locale: locale))),
            ),
          ListTile(
            leading: const Icon(Icons.edit_calendar_outlined),
            title: Text(
              l10n.previewModified(formatDate(file.modifiedAt, locale: locale)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(file.folderPath),
          ),
        ],
      ),
    );
  }
}

/// The display-size image (already cached by the deck → instant), then the
/// full-resolution one fading in over it. Undecodable → thumbnail / icon.
class _ViewerImage extends ConsumerWidget {
  const new({
    required this.file,
    this.videoActive = true,
    this.paged = false,
    super.key,
  });

  final FileRef file;

  /// B7: false = prepared, paused on the first frame.
  final bool videoActive;

  /// B7: say why an image can't be shown (HEIC before Android 9).
  final bool paged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (file.kind == FileKind.video) {
      // Same pooled player as the card: playback continues (S5).
      return VideoSurface(file: file, active: videoActive, fullscreen: true);
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
    final isRemote = file.origin == FileOrigin.remote;
    final remote = isRemote ? ref.watch(remoteMediaAccessProvider) : null;
    // N7: the original comes over the connection (never `File(...)`).
    ImageProvider<Object>? original;
    if (!isRemote) {
      original = ResizeImage(
        FileImage(File(file.path)),
        width: kViewerMaxDecodePx,
        height: kViewerMaxDecodePx,
        policy: ResizeImagePolicy.fit,
      );
    } else if (file.sizeBytes <= kMaxRemoteOriginalBytes) {
      original = remoteOriginalImage(remote!, file, maxPx: kViewerMaxDecodePx);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Thumbnail(file: file, fit: BoxFit.contain, background: Colors.black),
        Image(
          image: displayImageProvider(file, widthPx, remote: remote),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, _, _) => paged && _isHeic(file)
              ? Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 96),
                    child: Text(
                      context.l10n.previewHeicUnsupported,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4)],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (original != null)
          Image(
            image: original,
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

  /// HEIC decodes natively from Android 9; before that only the thumbnail.
  static bool _isHeic(FileRef f) {
    final ext = extensionOf(f.name);
    return ext == 'heic' || ext == 'heif';
  }
}

class _InfoBar extends ConsumerWidget {
  const new({required this.file, this.title, this.endInset = 16});

  final FileRef file;
  final String? title;

  /// Room at the end for a button over the bar (B10 ⓘ).
  final double endInset;

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
          endInset,
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
            // E4: where the file is ("Camera · Internal storage").
            if (file.origin != FileOrigin.remote)
              Text(
                folderLabel(l10n, file.folderPath),
                maxLines: 1,
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
            // X4: "Uploaded by KFM to …" per upload.
            CloudInfoLines(file: file, style: text),
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
