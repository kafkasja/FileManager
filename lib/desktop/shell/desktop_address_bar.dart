import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/desktop/browse/desktop_breadcrumb.dart';
import 'package:kfm/desktop/browse/disk_folders.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/tabs/desktop_tab_strip.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_address_bar.g.dart';

/// What a typed path is on disk.
enum TypedPathKind { folder, file, missing }

typedef PathKindOf = Future<TypedPathKind> Function(String path);

/// Looks a typed path up on disk (replaced in tests).
@Riverpod(keepAlive: true)
PathKindOf desktopPathKind(Ref ref) => (path) async {
  try {
    final type = await FileSystemEntity.type(path);
    return switch (type) {
      FileSystemEntityType.directory => TypedPathKind.folder,
      FileSystemEntityType.file => TypedPathKind.file,
      _ => TypedPathKind.missing,
    };
  } on Object {
    return TypedPathKind.missing;
  }
};

/// A file to select (and scroll to) once its folder is open: the address
/// bar with a file path, "Open file location". Browse takes it.
@Riverpod(keepAlive: true)
class DesktopRevealRequest extends _$DesktopRevealRequest {
  @override
  String? build() => null;

  // A plain setter keeps the request explicit.
  // ignore: use_setters_to_change_properties
  void request(String? path) => state = path;
}

/// Bumped by F5 / the refresh button; screens re-read their lists.
@Riverpod(keepAlive: true)
class DesktopRefreshTick extends _$DesktopRefreshTick {
  @override
  int build() => 0;

  void bump() => state++;
}

/// A typed path in KFM's form: quotes stripped, `%VAR%` expanded, `\` →
/// `/`, no trailing `/` (`C:\` → `C:`). Null for empty text.
String? normalizeTypedPath(String text, Map<String, String> environment) {
  var t = text.trim();
  if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
    t = t.substring(1, t.length - 1).trim();
  }
  if (t.isEmpty) return null;
  final env = {
    for (final e in environment.entries) e.key.toUpperCase(): e.value,
  };
  t = t.replaceAllMapped(RegExp('%([^%]+)%'), (m) {
    final v = env[m[1]!.toUpperCase()];
    return v ?? m[0]!;
  });
  t = t.replaceAll(r'\', '/');
  while (t.length > 1 && t.endsWith('/') && !t.endsWith(':/')) {
    t = t.substring(0, t.length - 1);
  }
  if (t.length == 3 && t.endsWith(':/')) t = t.substring(0, 2);
  if (t.length == 2 && t.endsWith(':')) t = t.toUpperCase();
  return t;
}

/// The path as Windows shows it (backslashes, `C:\` for a drive).
String windowsPathOf(String path) {
  final p = path.length == 2 && path.endsWith(':') ? '$path/' : path;
  return p.replaceAll('/', r'\');
}

/// The environment `%VAR%` expands from (replaced in tests).
@Riverpod(keepAlive: true)
Map<String, String> desktopEnvironment(Ref ref) => Platform.environment;

/// Back · Forward · Up · Refresh, the breadcrumb (click empty space or
/// Alt+D / Ctrl+L / F4 to type a path) and the search box scoped to the
/// open location (TASK-E3).
class DesktopAddressBar extends ConsumerStatefulWidget {
  const new({required this.searchFocus, required this.addressFocus, super.key});

  final FocusNode searchFocus;
  final FocusNode addressFocus;

  @override
  ConsumerState<DesktopAddressBar> createState() => DesktopAddressBarState();
}

class DesktopAddressBarState extends ConsumerState<DesktopAddressBar> {
  final _path = TextEditingController();
  final _search = TextEditingController();
  var _editing = false;
  String? _error;

  DesktopTabsController get _tabs =>
      ref.read(desktopTabsControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    widget.addressFocus.addListener(_onAddressFocus);
  }

  @override
  void dispose() {
    widget.addressFocus.removeListener(_onAddressFocus);
    _path.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onAddressFocus() {
    if (!widget.addressFocus.hasFocus && _editing && _error == null) {
      setState(() => _editing = false);
    }
  }

  /// Alt+D / Ctrl+L / F4: the path as text, selected.
  void edit() {
    final loc = ref.read(desktopTabsControllerProvider).current.location;
    _path.text = switch (loc) {
      FolderLocation(:final path) => windowsPathOf(path),
      _ => '',
    };
    _path.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _path.text.length,
    );
    setState(() {
      _editing = true;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.addressFocus.requestFocus();
    });
  }

  void _cancel() {
    setState(() {
      _editing = false;
      _error = null;
    });
    widget.addressFocus.unfocus();
  }

  Future<void> _submit(String text) async {
    final path = normalizeTypedPath(text, ref.read(desktopEnvironmentProvider));
    if (path == null) {
      _cancel();
      return;
    }
    final kind = await ref.read(desktopPathKindProvider)(path);
    if (!mounted) return;
    switch (kind) {
      case TypedPathKind.folder:
        _tabs.navigate(FolderLocation(path));
        _cancel();
      case TypedPathKind.file:
        final slash = path.lastIndexOf('/');
        ref.read(desktopRevealRequestProvider.notifier).request(path);
        _tabs.navigate(FolderLocation(path.substring(0, slash)));
        _cancel();
      case TypedPathKind.missing:
        setState(
          () => _error = context.l10n.desktopAddressNotFound(text.trim()),
        );
        _path.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _path.text.length,
        );
        widget.addressFocus.requestFocus();
    }
  }

  /// Up to 12 subfolders of the typed path's parent whose names start
  /// with what's typed after the last `\`.
  Future<Iterable<String>> _suggest(String text) async {
    final t = text.replaceAll(r'\', '/');
    final slash = t.lastIndexOf('/');
    if (slash < 0 || _error != null) return const [];
    final parent = normalizeTypedPath(
      t.substring(0, slash == 2 && t[1] == ':' ? 2 : slash),
      ref.read(desktopEnvironmentProvider),
    );
    if (parent == null) return const [];
    final prefix = t.substring(slash + 1).toLowerCase();
    final folders = await ref.read(diskFolderListerProvider)(parent);
    final out = [
      for (final d in folders)
        if (!d.hidden &&
            d.path
                .substring(d.path.lastIndexOf('/') + 1)
                .toLowerCase()
                .startsWith(prefix))
          d.path,
    ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out.take(12);
  }

  void _searchSubmit(String text) {
    final q = text.trim();
    if (q.isEmpty) return;
    final loc = ref.read(desktopTabsControllerProvider).current.location;
    _tabs.navigate(
      SearchLocation(
        q,
        scope: switch (loc) {
          FolderLocation(:final path) => path,
          SearchLocation(:final scope) => scope,
          _ => null,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tab = ref.watch(desktopTabsControllerProvider).current;
    final loc = tab.location;
    final colors = theme.colorScheme;
    final field = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    );
    final crumbs = switch (loc) {
      FolderLocation(:final path) => DesktopBreadcrumb(
        folder: path,
        subfoldersOf: (f) async => [
          for (final d in await ref.read(diskFolderListerProvider)(f))
            if (!d.hidden) d.path,
        ],
        onOpen: (f) => _tabs.navigate(
          f == null ? const HomeLocation() : FolderLocation(f),
        ),
      ),
      _ => Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        child: Row(
          children: [
            desktopLocationIcon(loc),
            const SizedBox(width: 8),
            Text(desktopLocationTitle(l10n, loc)),
          ],
        ),
      ),
    };
    final address = _editing
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): _cancel,
                },
                child: RawAutocomplete<String>(
                  textEditingController: _path,
                  focusNode: widget.addressFocus,
                  optionsBuilder: (v) => _suggest(v.text),
                  displayStringForOption: windowsPathOf,
                  optionsViewBuilder: (context, onSelected, options) =>
                      _Suggestions(options: options, onSelected: onSelected),
                  fieldViewBuilder: (context, controller, focusNode, _) =>
                      TextField(
                        key: const ValueKey('desktop-address-field'),
                        controller: controller,
                        focusNode: focusNode,
                        style: theme.textTheme.bodyMedium,
                        decoration: field.copyWith(
                          errorText: _error,
                          errorMaxLines: 1,
                        ),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        // Enter keeps the field focused (an error shows in it).
                        onEditingComplete: () {},
                        onSubmitted: (t) => unawaited(_submit(t)),
                      ),
                ),
              ),
            ],
          )
        : Tooltip(
            message: shortcutHint(
              l10n,
              l10n.desktopAddressLabel,
              DesktopKeys.label(DesktopKeys.addressBar),
            ),
            waitDuration: const Duration(milliseconds: 800),
            child: Semantics(
              button: true,
              label: l10n.desktopAddressLabel,
              child: GestureDetector(
                key: const ValueKey('desktop-address-crumbs'),
                behavior: HitTestBehavior.opaque,
                onTap: edit,
                child: Container(
                  height: scaledExtent(context, 32),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: AlignmentDirectional.centerStart,
                  child: crumbs,
                ),
              ),
            ),
          );
    final scopeName = switch (loc) {
      FolderLocation(:final path) => folderTitle(path),
      _ => null,
    };
    return SizedBox(
      height: scaledExtent(context, _error == null ? 44 : 64),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('browse-back'),
              tooltip: shortcutHint(
                l10n,
                l10n.desktopBrowseBack,
                DesktopKeys.label(DesktopKeys.back),
              ),
              icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: tab.back.isEmpty ? null : _tabs.back,
            ),
            IconButton(
              key: const ValueKey('browse-forward'),
              tooltip: shortcutHint(
                l10n,
                l10n.desktopBrowseForward,
                DesktopKeys.label(DesktopKeys.forward),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              onPressed: tab.forward.isEmpty ? null : _tabs.forward,
            ),
            IconButton(
              key: const ValueKey('browse-up'),
              tooltip: shortcutHint(
                l10n,
                l10n.desktopBrowseUp,
                DesktopKeys.label(DesktopKeys.up),
              ),
              icon: const Icon(Icons.arrow_upward, size: 18),
              onPressed: DesktopTabsController.parentOf(loc) == null
                  ? null
                  : _tabs.up,
            ),
            IconButton(
              key: const ValueKey('desktop-refresh'),
              tooltip: shortcutHint(
                l10n,
                l10n.desktopRefresh,
                DesktopKeys.label(DesktopKeys.refresh),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => refreshDesktop(ref),
            ),
            const SizedBox(width: 4),
            Expanded(child: address),
            const SizedBox(width: 8),
            SizedBox(
              width: 260,
              height: scaledExtent(context, 32),
              child: Tooltip(
                message: shortcutHint(
                  l10n,
                  l10n.searchHint,
                  DesktopKeys.label(DesktopKeys.find),
                ),
                waitDuration: const Duration(milliseconds: 800),
                child: TextField(
                  key: const ValueKey('desktop-search'),
                  controller: _search,
                  focusNode: widget.searchFocus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _searchSubmit,
                  style: theme.textTheme.bodyMedium,
                  decoration: field.copyWith(
                    hintText: scopeName == null
                        ? l10n.searchHint
                        : l10n.desktopSearchIn(scopeName),
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// F5: lists are read again (disk folders, the trash).
void refreshDesktop(WidgetRef ref) {
  final loc = ref.read(desktopTabsControllerProvider).current.location;
  if (loc is FolderLocation) {
    ref.invalidate(desktopDiskFoldersProvider(loc.path));
  }
  ref.read(desktopRefreshTickProvider.notifier).bump();
}

/// The typed-path suggestions under the address field.
class _Suggestions extends StatelessWidget {
  const new({required this.options, required this.onSelected});

  final Iterable<String> options;
  final AutocompleteOnSelected<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final highlighted = AutocompleteHighlightedOption.of(context);
    final list = options.toList();
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Material(
        key: const ValueKey('desktop-address-suggestions'),
        elevation: 4,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360, maxWidth: 560),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, i) => ListTile(
              dense: true,
              selected: i == highlighted,
              leading: const Icon(Icons.folder_outlined, size: 18),
              title: Text(windowsPathOf(list[i])),
              onTap: () => onSelected(list[i]),
            ),
          ),
        ),
      ),
    );
  }
}
