// #include <flutter/dart_project.h>
// #include <flutter/flutter_view_controller.h>
// #include <windows.h>

// #include "flutter_window.h"
// #include "utils.h"

// int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
//                       _In_ wchar_t *command_line, _In_ int show_command) {
//   // Attach to console when present (e.g., 'flutter run') or create a
//   // new console when running with a debugger.
//   if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
//     CreateAndAttachConsole();
//   }

//   // Initialize COM, so that it is available for use in the library and/or
//   // plugins.
//   ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

//   flutter::DartProject project(L"data");

//   std::vector<std::string> command_line_arguments =
//       GetCommandLineArguments();

//   project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

//   FlutterWindow window(project);
//   Win32Window::Point origin(10, 10);
//   Win32Window::Size size(1280, 720);
//   if (!window.Create(L"linglun", origin, size)) {
//     return EXIT_FAILURE;
//   }
//   window.SetQuitOnClose(true);

//   ::MSG msg;
//   while (::GetMessage(&msg, nullptr, 0, 0)) {
//     ::TranslateMessage(&msg);
//     ::DispatchMessage(&msg);
//   }

//   ::CoUninitialize();
//   return EXIT_SUCCESS;
// }

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Must match kWindowClassName in win32_window.cpp.
constexpr const wchar_t kWindowClassName[] = L"LINGLUN_WIN32_WINDOW";
constexpr const wchar_t kSingleInstanceMutex[] = L"Local\\linglun.SingleInstance";

constexpr unsigned int kDefaultWidth = 840;
constexpr unsigned int kDefaultHeight = 600;

// Brings the already-running instance's window to the foreground.
void ActivateExistingInstance() {
  HWND existing = ::FindWindowW(kWindowClassName, nullptr);
  if (existing == nullptr) {
    return;
  }
  if (!::IsWindowVisible(existing)) {
    ::ShowWindow(existing, SW_SHOW);
  }
  if (::IsIconic(existing)) {
    ::ShowWindow(existing, SW_RESTORE);
  }
  ::SetForegroundWindow(existing);
}

// Computes a default size (clamped to the work area) and a position that
// centers the window on the primary monitor. Units are logical pixels.
void GetCenteredPlacement(Win32Window::Point* origin, Win32Window::Size* size) {
  POINT zero = {0, 0};
  HMONITOR monitor = ::MonitorFromPoint(zero, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO info{};
  info.cbSize = sizeof(info);
  if (!::GetMonitorInfo(monitor, &info)) {
    *origin = Win32Window::Point(10, 10);
    *size = Win32Window::Size(kDefaultWidth, kDefaultHeight);
    return;
  }

  double scale = FlutterDesktopGetDpiForMonitor(monitor) / 96.0;
  double work_w = (info.rcWork.right - info.rcWork.left) / scale;
  double work_h = (info.rcWork.bottom - info.rcWork.top) / scale;

  unsigned int width = std::min<unsigned int>(kDefaultWidth, static_cast<unsigned int>(work_w));
  unsigned int height = std::min<unsigned int>(kDefaultHeight, static_cast<unsigned int>(work_h));

  double x = info.rcWork.left / scale + (work_w - width) / 2;
  double y = info.rcWork.top / scale + (work_h - height) / 2;

  *origin = Win32Window::Point(static_cast<unsigned int>(std::max(0.0, x)),
                               static_cast<unsigned int>(std::max(0.0, y)));
  *size = Win32Window::Size(width, height);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Single instance: if one is already running, bring it forward and exit.
  HANDLE mutex = ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutex);
  if (mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    ActivateExistingInstance();
    ::CloseHandle(mutex);
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
  // Default placement: centered on the primary monitor. A previously saved
  // placement (see win32_window.cpp) overrides this.
  Win32Window::Point origin(0, 0);
  Win32Window::Size size(kDefaultWidth, kDefaultHeight);
  GetCenteredPlacement(&origin, &size);
  if (!window.Create(L"伶伦", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (mutex != nullptr) {
    ::CloseHandle(mutex);
  }
  return EXIT_SUCCESS;
}