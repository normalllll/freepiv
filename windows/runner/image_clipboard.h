#ifndef RUNNER_IMAGE_CLIPBOARD_H_
#define RUNNER_IMAGE_CLIPBOARD_H_

#include <windows.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

// The "freepiv/clipboard" channel: copyImage puts an image on the Windows
// clipboard. The window frame itself belongs to frost_window.
class ImageClipboard {
 public:
  ImageClipboard(HWND window, flutter::BinaryMessenger* messenger);
  ~ImageClipboard();
  ImageClipboard(const ImageClipboard&) = delete;
  ImageClipboard& operator=(const ImageClipboard&) = delete;

 private:
  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif
