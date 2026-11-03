#ifndef RUNNER_CLIPBOARD_FILES_H_
#define RUNNER_CLIPBOARD_FILES_H_

#include <flutter/encodable_value.h>
#include <flutter/method_result.h>
#include <windows.h>

#include <string>

// Files on the Windows clipboard (TASK-PL3: Ctrl+C / Ctrl+X / Ctrl+V
// between KFM and Explorer). Methods of the `com.kaf.kfm/windows` channel;
// the Dart side and the spec live in
// lib/core/platform/windows/windows_clipboard.dart. They run on the
// platform (window) thread: the clipboard is opened with the window as its
// owner, and every call is quick.
namespace clipboard_files {

// True for the methods [Handle] answers.
bool Handles(const std::string& method);

// Answers [method] at once.
void Handle(HWND window, const std::string& method,
            const flutter::EncodableMap& args,
            flutter::MethodResult<flutter::EncodableValue>& result);

}  // namespace clipboard_files

#endif  // RUNNER_CLIPBOARD_FILES_H_
