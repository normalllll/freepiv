#include "image_clipboard.h"

#include <flutter/standard_method_codec.h>

#include <cstring>
#include <variant>
#include <vector>

namespace {
HGLOBAL CopyToGlobal(const std::vector<uint8_t>& bytes) {
  HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, bytes.size());
  if (memory == nullptr) return nullptr;
  void* target = GlobalLock(memory);
  if (target == nullptr) {
    GlobalFree(memory);
    return nullptr;
  }
  std::memcpy(target, bytes.data(), bytes.size());
  GlobalUnlock(memory);
  return memory;
}

// Places an image on the clipboard as CF_DIBV5 (understood by every Windows
// app) plus the registered "PNG" format (keeps alpha for apps that read it).
// The window owns the clipboard and empties it first, as SetClipboardData
// requires; the system takes ownership of each handle once it is set.
bool WriteImageToClipboard(HWND owner, const std::vector<uint8_t>& dib,
                           const std::vector<uint8_t>* png) {
  bool opened = false;
  for (int attempt = 0; attempt < 10 && !opened; ++attempt) {
    opened = OpenClipboard(owner) != FALSE;
    if (!opened) Sleep(10);
  }
  if (!opened) return false;
  bool written = false;
  if (EmptyClipboard()) {
    if (HGLOBAL memory = CopyToGlobal(dib)) {
      if (SetClipboardData(CF_DIBV5, memory) != nullptr) {
        written = true;
      } else {
        GlobalFree(memory);
      }
    }
    if (png != nullptr && !png->empty()) {
      const UINT png_format = RegisterClipboardFormatW(L"PNG");
      if (HGLOBAL memory = CopyToGlobal(*png)) {
        if (png_format == 0 || SetClipboardData(png_format, memory) == nullptr) {
          GlobalFree(memory);
        }
      }
    }
  }
  CloseClipboard();
  return written;
}
}  // namespace

ImageClipboard::ImageClipboard(HWND window, flutter::BinaryMessenger* messenger)
    : window_(window) {
  channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "freepiv/clipboard",
          &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() != "copyImage") {
          result->NotImplemented();
          return;
        }
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        const std::vector<uint8_t>* dib = nullptr;
        const std::vector<uint8_t>* png = nullptr;
        if (arguments != nullptr) {
          if (auto it = arguments->find(flutter::EncodableValue("dib"));
              it != arguments->end()) {
            dib = std::get_if<std::vector<uint8_t>>(&it->second);
          }
          if (auto it = arguments->find(flutter::EncodableValue("png"));
              it != arguments->end()) {
            png = std::get_if<std::vector<uint8_t>>(&it->second);
          }
        }
        if (dib == nullptr || dib->empty()) {
          result->Error("invalid_arguments", "Missing DIB image data.");
          return;
        }
        if (!WriteImageToClipboard(window_, *dib, png)) {
          result->Error("clipboard_unavailable",
                        "Could not write the image to the clipboard.");
          return;
        }
        result->Success();
      });
}

ImageClipboard::~ImageClipboard() { channel_->SetMethodCallHandler(nullptr); }
