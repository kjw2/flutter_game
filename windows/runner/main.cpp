#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

void EnableWindowedFullscreen(HWND window) {
  if (window == nullptr) {
    return;
  }

  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(MONITORINFO);
  if (!GetMonitorInfo(MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST),
                      &monitor_info)) {
    return;
  }

  const LONG_PTR style = GetWindowLongPtr(window, GWL_STYLE);
  SetWindowLongPtr(
      window, GWL_STYLE,
      (style & ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX |
                 WS_MAXIMIZEBOX | WS_SYSMENU)) |
          WS_POPUP);

  const LONG_PTR ex_style = GetWindowLongPtr(window, GWL_EXSTYLE);
  SetWindowLongPtr(window, GWL_EXSTYLE,
                   ex_style & ~(WS_EX_DLGMODALFRAME | WS_EX_CLIENTEDGE |
                                WS_EX_STATICEDGE | WS_EX_WINDOWEDGE));

  const RECT bounds = monitor_info.rcMonitor;
  SetWindowPos(window, nullptr, bounds.left, bounds.top,
               bounds.right - bounds.left, bounds.bottom - bounds.top,
               SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOOWNERZORDER |
                   SWP_NOZORDER);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
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
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"flutter_game", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  EnableWindowedFullscreen(window.GetHandle());

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
