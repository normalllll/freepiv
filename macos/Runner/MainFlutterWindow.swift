import Cocoa
import FlutterMacOS

/// Stays hidden (`visibleAtLaunch="NO"` in MainMenu.xib) until the app has
/// placed it and drawn its first frame; frost_window's `show()` orders it in.
/// The app owns its placement, so AppKit neither autosaves nor restores it.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: false)
    self.isRestorable = false
    self.setFrameAutosaveName("")
    // appMinimumWindowSize in lib/app/window/app_window.dart.
    self.contentMinSize = NSSize(width: 320, height: 480)
    // Where the window opens if the app cannot place it.
    let area = (self.screen ?? NSScreen.main)?.visibleFrame ?? windowFrame
    self.setContentSize(NSSize(width: min(1280, area.width), height: min(900, area.height - 28)))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerFolderAccess(flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  /// Security-scoped bookmarks keep a folder the user picked writable after
  /// a relaunch. The access stays open for the life of the process.
  private func registerFolderAccess(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "freepiv/folder_access", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      do {
        switch (call.method, call.arguments) {
        case ("bookmark", let path as String):
          let data = try URL(fileURLWithPath: path).bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
          )
          result(FlutterStandardTypedData(bytes: data))
        case ("open", let bookmark as FlutterStandardTypedData):
          var stale = false
          let url = try URL(
            resolvingBookmarkData: bookmark.data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
          )
          result(url.startAccessingSecurityScopedResource() ? url.path : nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "folder_access", message: error.localizedDescription, details: nil))
      }
    }
  }
}
