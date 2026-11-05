#ifndef RUNNER_WINDOWS_CHANNEL_H_
#define RUNNER_WINDOWS_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <functional>
#include <memory>

// Method channel `com.kaf.kfm/windows` (TASK-PL1). The Dart side and the
// method spec live in lib/core/platform/windows/windows_channel.dart.
//
// Every method runs on a worker thread (COM initialised STA on each worker).
// Replies are posted back to the window's thread with
// [kRunOnPlatformThreadMessage]: Flutter channel replies must happen on the
// platform thread.
class WindowsChannel {
 public:
  // Posted to [window]; LPARAM is a heap `std::function<void()>*` that
  // [RunPosted] runs and frees.
  static constexpr UINT kRunOnPlatformThreadMessage = WM_APP + 0x4B4;

  WindowsChannel(flutter::BinaryMessenger* messenger, HWND window);
  ~WindowsChannel();

  WindowsChannel(const WindowsChannel&) = delete;
  WindowsChannel& operator=(const WindowsChannel&) = delete;

  // Call from the window procedure for [kRunOnPlatformThreadMessage].
  static void RunPosted(LPARAM lparam);

  // WM_DEVICECHANGE: a volume arrived or went away → Dart `volumesChanged`.
  void OnDeviceChange(WPARAM wparam, LPARAM lparam);

  // WM_POWERBROADCAST: sleep / wake → Dart `power {state}`.
  void OnPowerBroadcast(WPARAM wparam);

 private:
  class WorkerPool;
  using Result =
      std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>;

  void HandleCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Runs [work] on [pool]; its value (or error) is replied on the platform
  // thread, unless the channel is gone by then.
  void Run(WorkerPool& pool, Result result,
           std::function<flutter::EncodableValue()> work);

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  // Bin and file operations, one at a time.
  std::unique_ptr<WorkerPool> ops_;
  // Thumbnails and quick queries, a few in parallel.
  std::unique_ptr<WorkerPool> quick_;
  // E3: shell icons and type names (a slow network path can't stall the
  // quick pool's open/thumbnail calls).
  std::unique_ptr<WorkerPool> icons_;
  // Reset in the destructor: posted replies check it before answering.
  std::shared_ptr<bool> alive_;
};

#endif  // RUNNER_WINDOWS_CHANNEL_H_
