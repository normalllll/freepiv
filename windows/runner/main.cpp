#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <string>
#include <windows.h>

#include "app_links/app_links_plugin_c_api.h"
#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr wchar_t kWindowTitle[] = L"freepiv";

Win32Window::Point GetCenteredWindowOrigin(const Win32Window::Size& size) {
  const POINT primary_monitor_point = {0, 0};
  const HMONITOR monitor =
      ::MonitorFromPoint(primary_monitor_point, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO monitor_info = {sizeof(MONITORINFO)};
  if (!::GetMonitorInfo(monitor, &monitor_info)) {
    return Win32Window::Point(10, 10);
  }

  const double scale_factor =
      FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  const int window_width = static_cast<int>(size.width * scale_factor);
  const int window_height = static_cast<int>(size.height * scale_factor);
  const RECT& work_area = monitor_info.rcWork;
  const int x = work_area.left +
                (work_area.right - work_area.left - window_width) / 2;
  const int y = work_area.top +
                (work_area.bottom - work_area.top - window_height) / 2;
  const int visible_x = x < work_area.left ? work_area.left : x;
  const int visible_y = y < work_area.top ? work_area.top : y;

  return Win32Window::Point(
      static_cast<unsigned int>(visible_x / scale_factor),
      static_cast<unsigned int>(visible_y / scale_factor));
}

bool SendAppLinkToInstance(const std::wstring& title) {
  HWND hwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", title.c_str());
  if (hwnd == nullptr) {
    return false;
  }

  SendAppLink(hwnd);

  WINDOWPLACEMENT placement = {sizeof(WINDOWPLACEMENT)};
  if (::GetWindowPlacement(hwnd, &placement)) {
    switch (placement.showCmd) {
      case SW_SHOWMAXIMIZED:
        ::ShowWindow(hwnd, SW_SHOWMAXIMIZED);
        break;
      case SW_SHOWMINIMIZED:
        ::ShowWindow(hwnd, SW_RESTORE);
        break;
      default:
        ::ShowWindow(hwnd, SW_NORMAL);
        break;
    }
  }

  ::SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0,
                 SWP_SHOWWINDOW | SWP_NOSIZE | SWP_NOMOVE);
  ::SetForegroundWindow(hwnd);
  return true;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (SendAppLinkToInstance(kWindowTitle)) {
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  const Win32Window::Size size(1280, 720);
  const Win32Window::Point origin = GetCenteredWindowOrigin(size);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
