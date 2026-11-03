import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/domain/cloud_state.dart';
import 'package:kfm/features/cloud/ui/cloud_badge_cache.dart';

/// [file]'s badge, or null while unknown, when no upload exists or when the
/// "Show cloud icon" setting is off. Watches nothing cloud-specific beyond
/// [cloudHasUploadsProvider] until an upload exists.
CloudBadge? watchCloudBadge(WidgetRef ref, FileRef file) {
  if (!(ref.watch(cloudHasUploadsProvider).value ?? false)) return null;
  if (!(ref.watch(cloudShowBadgeProvider).value ?? false)) return null;
  final facts = ref.watch(cloudBadgeCacheProvider.select((m) => m[file.id]));
  if (facts == null) {
    ref.read(cloudBadgeCacheProvider.notifier).request(file.id);
    return null;
  }
  return cloudBadgeFor(
    uploads: facts,
    localSizeBytes: file.sizeBytes,
    localModifiedAtMs: file.modifiedAt.millisecondsSinceEpoch,
  );
}

/// X4: the small cloud icon of a file KFM uploaded (tile, list row, swipe
/// card). Nothing at all (zero size) without a badge. [tooltip] only where
/// a long press isn't the host's own gesture (not on Browse tiles: B6
/// selects there).
class CloudBadgeIcon extends ConsumerWidget {
  const new({
    required this.file,
    this.size = 16,
    this.tooltip = false,
    super.key,
  });

  final FileRef file;
  final double size;
  final bool tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = watchCloudBadge(ref, file);
    if (badge == null || badge == CloudBadge.none) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final changed = badge == CloudBadge.changedSinceUpload;
    final label = changed ? l10n.cloudBadgeChanged : l10n.cloudBadgeOnCloud;
    final scheme = Theme.of(context).colorScheme;
    Widget icon = DecoratedBox(
      key: ValueKey('cloud-badge-${badge.name}'),
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(3),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              changed ? Icons.cloud_sync_outlined : Icons.cloud_done_outlined,
              size: size,
              color: Colors.white,
            ),
            if (changed)
              PositionedDirectional(
                end: -2,
                top: -2,
                child: Container(
                  width: size / 3,
                  height: size / 3,
                  decoration: BoxDecoration(
                    color: scheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    icon = Semantics(
      label: label,
      child: ExcludeSemantics(child: icon),
    );
    return tooltip ? Tooltip(message: label, child: icon) : icon;
  }
}

/// X4: the viewer info bar's cloud lines, one per upload: "Uploaded by KFM
/// to Google Drive › Photos · 12 Oct" ("(removed)" for a removed
/// destination) or "Changed since upload to …". Shown whatever the badge
/// setting says (the user opened the info bar to see this).
class CloudInfoLines extends ConsumerWidget {
  const new({required this.file, this.style, super.key});

  final FileRef file;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(cloudHasUploadsProvider).value ?? false)) {
      return const SizedBox.shrink();
    }
    final uploads =
        ref.watch(cloudUploadsOfFileProvider(file.id)).value ?? const [];
    if (uploads.isEmpty) return const SizedBox.shrink();
    final destinations =
        ref.watch(cloudDestinationsByIdProvider).value ?? const {};
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final u in uploads)
          Text(
            () {
              final d = destinations[u.destinationId];
              final name = d == null
                  ? '?'
                  : d.isActive
                  ? d.label
                  : l10n.cloudInfoRemoved(d.label);
              final unchanged = u.matches(
                localSizeBytes: file.sizeBytes,
                localModifiedAtMs: file.modifiedAt.millisecondsSinceEpoch,
              );
              return unchanged
                  ? l10n.cloudInfoUploaded(
                      name,
                      formatDate(
                        DateTime.fromMillisecondsSinceEpoch(u.uploadedAtMs),
                        locale: locale,
                      ),
                    )
                  : l10n.cloudInfoChanged(name);
            }(),
            key: ValueKey('cloud-info-${u.destinationId}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
      ],
    );
  }
}
