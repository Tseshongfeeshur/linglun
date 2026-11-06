// import Cocoa
// import FlutterMacOS

// @main
// class AppDelegate: FlutterAppDelegate {
//   override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
//     return true
//   }

//   override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
//     return true
//   }
// }

import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // macOS convention: closing the last window does not quit the app
  // (Cmd+Q does). Audio keeps playing, and clicking the Dock icon reopens
  // the window.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication, hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag {
      for window in sender.windows where window is MainFlutterWindow {
        window.makeKeyAndOrderFront(self)
      }
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}