import 'dart:ffi';
import 'dart:io';

/// Windows file attributes (`GetFileAttributesW` through dart:ffi, no
/// package): KFM hides what Explorer hides by default — items with the
/// hidden attribute, which includes the system's own `System Volume
/// Information`, `$RECYCLE.BIN`, `desktop.ini`, `Thumbs.db` (desktop fixes).
/// Works in any isolate (the walker's too). Off Windows every call answers
/// "not hidden".

const _fileAttributeHidden = 0x2;
const _invalidAttributes = 0xFFFFFFFF;

typedef _GetAttrsNative = Uint32 Function(Pointer<Uint16> path);
typedef _GetAttrs = int Function(Pointer<Uint16> path);
typedef _LocalAllocNative = Pointer<Uint16> Function(Uint32 flags, IntPtr size);
typedef _LocalAlloc = Pointer<Uint16> Function(int flags, int size);
typedef _LocalFreeNative = Pointer<Void> Function(Pointer<Uint16> mem);
typedef _LocalFree = Pointer<Void> Function(Pointer<Uint16> mem);

final class _Kernel32 {
  new() : _lib = DynamicLibrary.open('kernel32.dll');

  final DynamicLibrary _lib;
  late final _GetAttrs getAttributes = _lib
      .lookupFunction<_GetAttrsNative, _GetAttrs>('GetFileAttributesW');
  late final _LocalAlloc alloc = _lib
      .lookupFunction<_LocalAllocNative, _LocalAlloc>('LocalAlloc');
  late final _LocalFree free = _lib
      .lookupFunction<_LocalFreeNative, _LocalFree>('LocalFree');
}

_Kernel32? _kernel32;

final _drivePath = RegExp(r'^[A-Za-z]:[\\/]');
final _driveRoot = RegExp(r'^[A-Za-z]:[\\/]?$');

/// The attributes of [path] ('/'- or '\'-separated), or null when Windows
/// can't tell (gone, no access) or off Windows.
int? windowsFileAttributes(String path) {
  if (!Platform.isWindows) return null;
  var p = path.replaceAll('/', r'\');
  if (p.length >= 240 && _drivePath.hasMatch(p)) p = '\\\\?\\$p';
  final units = p.codeUnits;
  try {
    final k = _kernel32 ??= _Kernel32();
    final buf = k.alloc(0, (units.length + 1) * 2); // LMEM_FIXED
    if (buf.address == 0) return null;
    try {
      buf.asTypedList(units.length + 1)
        ..setAll(0, units)
        ..[units.length] = 0;
      final attrs = k.getAttributes(buf);
      return attrs == _invalidAttributes ? null : attrs;
    } finally {
      k.free(buf);
    }
  } on Object {
    return null;
  }
}

/// True when [path] itself has the hidden attribute. Drive roots never
/// count (Windows marks `E:\` hidden + system).
bool hasHiddenAttribute(String path) {
  if (!Platform.isWindows || _driveRoot.hasMatch(path)) return false;
  final attrs = windowsFileAttributes(path);
  return attrs != null && attrs & _fileAttributeHidden != 0;
}
