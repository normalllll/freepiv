import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.contentMinSize = NSSize(width: 480, height: 360)
    let area = (self.screen ?? NSScreen.main)?.visibleFrame ?? windowFrame
    self.setContentSize(NSSize(width: min(1280, area.width), height: min(900, area.height - 28)))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
