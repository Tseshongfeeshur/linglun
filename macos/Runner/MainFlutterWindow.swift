// import Cocoa
// import FlutterMacOS

// class MainFlutterWindow: NSWindow {
//   override func awakeFromNib() {
//     let flutterViewController = FlutterViewController()
//     let windowFrame = self.frame
//     self.contentViewController = flutterViewController
//     self.setFrame(windowFrame, display: true)

//     RegisterGeneratedPlugins(registry: flutterViewController)

//     super.awakeFromNib()
//   }
// }

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let autosaveName = "MainWindow"

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Minimum size, so the Flutter layout can't be crushed.
    self.contentMinSize = NSSize(width: 300, height: 400)

    // Remember position and size across launches (handled by AppKit).
    // First launch has no saved frame: use a sensible default, centered.
    let hasSavedFrame = UserDefaults.standard.string(
      forKey: "NSWindow Frame \(MainFlutterWindow.autosaveName)") != nil
    self.setFrameAutosaveName(MainFlutterWindow.autosaveName)
    if !hasSavedFrame {
      self.setContentSize(NSSize(width: 840, height: 600))
      self.center()
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}