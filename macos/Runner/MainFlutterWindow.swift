import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Unified title bar: Extend Flutter content into title bar area
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert([.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView])

    // Keep traffic lights visible in standard position
    let customToolbar = NSToolbar()
    customToolbar.showsBaselineSeparator = false
    self.toolbar = customToolbar

    super.awakeFromNib()
  }
}
