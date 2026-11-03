#ifndef RUNNER_DRAG_DROP_H_
#define RUNNER_DRAG_DROP_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

class DropTarget;

// Method channel `com.kaf.kfm/dragdrop` (TASK-PL3 step 4). The Dart side
// and the method spec live in lib/core/platform/windows/drag_drop_channel.dart.
//
// - An OLE drop target on the Flutter view: files dragged in from Explorer
//   (CF_HDROP) are reported to Dart as `dragEnter` / `dragOver` / `dragLeave`
//   / `drop` with logical client coordinates.
// - `startDrag {paths}`: a shell drag of those files out of KFM (copy only),
//   run from the window procedure while the mouse button is still down.
class DragDropChannel {
 public:
  DragDropChannel(flutter::BinaryMessenger* messenger, HWND window, HWND view);
  ~DragDropChannel();

  DragDropChannel(const DragDropChannel&) = delete;
  DragDropChannel& operator=(const DragDropChannel&) = delete;

 private:
  friend class DropTarget;

  void HandleCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Sends a drop target event; [on_reply] gets whether Dart takes the drop.
  void Notify(const char* method, flutter::EncodableValue args,
              std::function<void(bool)> on_reply);

  // Screen pixels → the view's logical coordinates.
  flutter::EncodableValue Position(POINTL screen) const;

  HWND window_;
  HWND view_;
  bool ole_ = false;
  bool dragging_out_ = false;
  DropTarget* target_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::shared_ptr<bool> alive_;
};

#endif  // RUNNER_DRAG_DROP_H_
