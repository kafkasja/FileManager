#include "drag_drop.h"

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <ole2.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wrl/client.h>

#include <string>
#include <vector>

#include "windows_channel.h"

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using Microsoft::WRL::ComPtr;

namespace {

std::wstring Wide(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int n = ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring out(n, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                        out.data(), n);
  return out;
}

std::string Utf8(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  int n = ::WideCharToMultiByte(CP_UTF8, 0, wide.data(),
                                static_cast<int>(wide.size()), nullptr, 0,
                                nullptr, nullptr);
  std::string out(n, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()),
                        out.data(), n, nullptr, nullptr);
  return out;
}

// The CF_HDROP file list of [data]; empty when it has none.
std::vector<std::wstring> DroppedPaths(IDataObject* data) {
  std::vector<std::wstring> out;
  if (!data) return out;
  FORMATETC format = {CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL};
  STGMEDIUM medium = {};
  if (FAILED(data->GetData(&format, &medium))) return out;
  auto drop = static_cast<HDROP>(::GlobalLock(medium.hGlobal));
  if (drop) {
    UINT count = ::DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
    for (UINT i = 0; i < count; i++) {
      UINT len = ::DragQueryFileW(drop, i, nullptr, 0);
      std::wstring path(len, L'\0');
      ::DragQueryFileW(drop, i, path.data(), len + 1);
      out.push_back(path);
    }
    ::GlobalUnlock(medium.hGlobal);
  }
  ::ReleaseStgMedium(&medium);
  return out;
}

EncodableList PathList(const std::vector<std::wstring>& paths) {
  EncodableList list;
  for (const auto& p : paths) list.push_back(EncodableValue(Utf8(p)));
  return list;
}

}  // namespace

// The OLE drop target registered on the Flutter view.
class DropTarget : public IDropTarget {
 public:
  explicit DropTarget(DragDropChannel* owner) : owner_(owner) {
    ::CoCreateInstance(CLSID_DragDropHelper, nullptr, CLSCTX_INPROC_SERVER,
                       IID_PPV_ARGS(&helper_));
  }

  void Detach() { owner_ = nullptr; }

  // IUnknown
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid,
                                           void** object) override {
    if (riid == IID_IUnknown || riid == IID_IDropTarget) {
      *object = static_cast<IDropTarget*>(this);
      AddRef();
      return S_OK;
    }
    *object = nullptr;
    return E_NOINTERFACE;
  }
  ULONG STDMETHODCALLTYPE AddRef() override {
    return ::InterlockedIncrement(&refs_);
  }
  ULONG STDMETHODCALLTYPE Release() override {
    ULONG n = ::InterlockedDecrement(&refs_);
    if (n == 0) delete this;
    return n;
  }

  // IDropTarget
  HRESULT STDMETHODCALLTYPE DragEnter(IDataObject* data, DWORD keys,
                                      POINTL pt, DWORD* effect) override {
    paths_ = (owner_ && !owner_->dragging_out_) ? DroppedPaths(data)
                                                : std::vector<std::wstring>();
    accept_ = false;
    if (!paths_.empty()) {
      EncodableMap args = Args(pt);
      args[EncodableValue("paths")] = EncodableValue(PathList(paths_));
      Send("dragEnter", EncodableValue(args));
    }
    *effect = Effect();
    if (helper_) {
      POINT p = {pt.x, pt.y};
      helper_->DragEnter(owner_ ? owner_->view_ : nullptr, data, &p, *effect);
    }
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE DragOver(DWORD keys, POINTL pt,
                                     DWORD* effect) override {
    if (!paths_.empty()) Send("dragOver", EncodableValue(Args(pt)));
    *effect = Effect();
    if (helper_) {
      POINT p = {pt.x, pt.y};
      helper_->DragOver(&p, *effect);
    }
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE DragLeave() override {
    if (!paths_.empty() && owner_) {
      owner_->Notify("dragLeave", EncodableValue(), nullptr);
    }
    paths_.clear();
    accept_ = false;
    if (helper_) helper_->DragLeave();
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE Drop(IDataObject* data, DWORD keys, POINTL pt,
                                 DWORD* effect) override {
    *effect = Effect();
    if (helper_) {
      POINT p = {pt.x, pt.y};
      helper_->Drop(data, &p, *effect);
    }
    if (!paths_.empty() && owner_) {
      EncodableMap args = Args(pt);
      args[EncodableValue("paths")] = EncodableValue(PathList(paths_));
      owner_->Notify("drop", EncodableValue(args), nullptr);
    }
    paths_.clear();
    accept_ = false;
    return S_OK;
  }

 private:
  ~DropTarget() = default;

  EncodableMap Args(POINTL pt) const {
    EncodableMap args;
    if (owner_) {
      const auto pos = std::get<EncodableList>(owner_->Position(pt));
      args[EncodableValue("x")] = pos[0];
      args[EncodableValue("y")] = pos[1];
    }
    return args;
  }

  // Dart answers each event with whether the target under the pointer
  // takes the files; the next event's effect uses the latest answer.
  void Send(const char* method, EncodableValue args) {
    if (!owner_) return;
    owner_->Notify(method, std::move(args),
                   [this](bool accept) { accept_ = accept; });
  }

  DWORD Effect() const {
    return !paths_.empty() && accept_ ? DROPEFFECT_COPY : DROPEFFECT_NONE;
  }

  LONG refs_ = 1;
  DragDropChannel* owner_;
  ComPtr<IDropTargetHelper> helper_;
  std::vector<std::wstring> paths_;
  bool accept_ = false;
};

DragDropChannel::DragDropChannel(flutter::BinaryMessenger* messenger,
                                 HWND window, HWND view)
    : window_(window), view_(view), alive_(std::make_shared<bool>(true)) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "com.kaf.kfm/dragdrop",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        HandleCall(call, std::move(result));
      });
  // OLE on top of main()'s STA COM (balanced in the destructor).
  ole_ = SUCCEEDED(::OleInitialize(nullptr));
  if (ole_ && view_) {
    target_ = new DropTarget(this);
    if (FAILED(::RegisterDragDrop(view_, target_))) {
      target_->Detach();
      target_->Release();
      target_ = nullptr;
    }
  }
}

DragDropChannel::~DragDropChannel() {
  alive_.reset();
  if (target_) {
    ::RevokeDragDrop(view_);
    target_->Detach();
    target_->Release();
    target_ = nullptr;
  }
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  if (ole_) ::OleUninitialize();
}

EncodableValue DragDropChannel::Position(POINTL screen) const {
  POINT p = {screen.x, screen.y};
  ::ScreenToClient(view_, &p);
  UINT dpi = ::GetDpiForWindow(view_);
  double scale = dpi == 0 ? 1.0 : dpi / 96.0;
  return EncodableValue(EncodableList{EncodableValue(p.x / scale),
                                      EncodableValue(p.y / scale)});
}

void DragDropChannel::Notify(const char* method, EncodableValue args,
                             std::function<void(bool)> on_reply) {
  std::weak_ptr<bool> alive = alive_;
  auto reply = std::make_unique<flutter::MethodResultFunctions<EncodableValue>>(
      [alive, on_reply](const EncodableValue* value) {
        if (!alive.lock() || !on_reply) return;
        const bool* b = value ? std::get_if<bool>(value) : nullptr;
        on_reply(b && *b);
      },
      nullptr, nullptr);
  channel_->InvokeMethod(method,
                         std::make_unique<EncodableValue>(std::move(args)),
                         std::move(reply));
}

void DragDropChannel::HandleCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (call.method_name() != "startDrag") {
    result->NotImplemented();
    return;
  }
  std::vector<std::wstring> paths;
  if (const auto* args = std::get_if<EncodableMap>(call.arguments())) {
    auto it = args->find(EncodableValue("paths"));
    if (it != args->end()) {
      if (const auto* list = std::get_if<EncodableList>(&it->second)) {
        for (const auto& v : *list) {
          if (const auto* s = std::get_if<std::string>(&v)) {
            paths.push_back(Wide(*s));
          }
        }
      }
    }
  }
  if (paths.empty() || !ole_) {
    result->Success(EncodableValue(false));
    return;
  }
  // Run the modal drag loop from the window procedure, not inside the
  // engine's message callback.
  std::shared_ptr<flutter::MethodResult<EncodableValue>> reply(
      std::move(result));
  std::weak_ptr<bool> alive = alive_;
  auto* run = new std::function<void()>([this, alive, reply, paths]() {
    if (!alive.lock()) return;
    std::vector<PIDLIST_ABSOLUTE> pidls;
    for (const auto& p : paths) {
      PIDLIST_ABSOLUTE pidl = nullptr;
      if (SUCCEEDED(::SHParseDisplayName(p.c_str(), nullptr, &pidl, 0,
                                         nullptr)) &&
          pidl) {
        pidls.push_back(pidl);
      }
    }
    bool started = false;
    if (!pidls.empty()) {
      ComPtr<IDataObject> data;
      // Absolute PIDLs relative to the desktop: files may come from
      // different folders (a Sort selection).
      std::vector<PCUITEMID_CHILD> children;
      for (auto pidl : pidls) {
        children.push_back(reinterpret_cast<PCUITEMID_CHILD>(pidl));
      }
      HRESULT hr = ::SHCreateDataObject(
          nullptr, static_cast<UINT>(children.size()), children.data(),
          nullptr, IID_PPV_ARGS(&data));
      if (SUCCEEDED(hr) && data) {
        dragging_out_ = true;
        DWORD effect = DROPEFFECT_NONE;
        // Copy only: a drag out never moves the user's files behind KFM's
        // undo.
        hr = ::SHDoDragDrop(window_, data.Get(), nullptr, DROPEFFECT_COPY,
                            &effect);
        dragging_out_ = false;
        started = SUCCEEDED(hr);
      }
    }
    for (auto pidl : pidls) ::CoTaskMemFree(pidl);
    // The OLE loop ate the button release: give Flutter one so its pointer
    // isn't left pressed.
    POINT cursor;
    ::GetCursorPos(&cursor);
    ::ScreenToClient(view_, &cursor);
    ::PostMessageW(view_, WM_LBUTTONUP, 0, MAKELPARAM(cursor.x, cursor.y));
    reply->Success(EncodableValue(started));
  });
  if (!::PostMessageW(window_, WindowsChannel::kRunOnPlatformThreadMessage, 0,
                      reinterpret_cast<LPARAM>(run))) {
    delete run;
    reply->Success(EncodableValue(false));
  }
}
