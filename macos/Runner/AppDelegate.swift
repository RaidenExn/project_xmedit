import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var menuChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Set up method channel for menu communication
    if let window = NSApplication.shared.windows.first,
      let flutterViewController = window.contentViewController as? FlutterViewController
    {
      menuChannel = FlutterMethodChannel(
        name: "com.xmedit.app/menu",
        binaryMessenger: flutterViewController.engine.binaryMessenger
      )

      // Handle calls from menu items to Flutter
      menuChannel?.setMethodCallHandler { [weak self] (call, result) in
        // Menu items will trigger Flutter actions
        result(nil)
      }
    }

    createMenuBar()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func createMenuBar() {
    let mainMenu = NSMenu()

    // App Menu (XMEdit)
    let appMenuItem = NSMenuItem()
    let appMenu = NSMenu()
    appMenuItem.submenu = appMenu

    appMenu.addItem(
      NSMenuItem(title: "About XMEdit", action: #selector(showAbout), keyEquivalent: ""))
    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(
      NSMenuItem(
        title: "Quit XMEdit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    mainMenu.addItem(appMenuItem)

    // File Menu
    let fileMenuItem = NSMenuItem()
    let fileMenu = NSMenu(title: "File")
    fileMenuItem.submenu = fileMenu

    let openItem = NSMenuItem(
      title: "Open...", action: #selector(menuAction(_:)), keyEquivalent: "o")
    openItem.tag = MenuAction.open.rawValue
    fileMenu.addItem(openItem)

    fileMenu.addItem(NSMenuItem.separator())

    let saveItem = NSMenuItem(title: "Save", action: #selector(menuAction(_:)), keyEquivalent: "s")
    saveItem.tag = MenuAction.save.rawValue
    fileMenu.addItem(saveItem)

    let saveAsItem = NSMenuItem(
      title: "Save As...", action: #selector(menuAction(_:)), keyEquivalent: "S")
    saveAsItem.keyEquivalentModifierMask = [.command, .shift]
    saveAsItem.tag = MenuAction.saveAs.rawValue
    fileMenu.addItem(saveAsItem)

    fileMenu.addItem(NSMenuItem.separator())
    fileMenu.addItem(
      NSMenuItem(
        title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

    mainMenu.addItem(fileMenuItem)

    // Edit Menu
    let editMenuItem = NSMenuItem()
    let editMenu = NSMenu(title: "Edit")
    editMenuItem.submenu = editMenu

    let undoItem = NSMenuItem(title: "Undo", action: #selector(menuAction(_:)), keyEquivalent: "z")
    undoItem.tag = MenuAction.undo.rawValue
    editMenu.addItem(undoItem)

    let resetItem = NSMenuItem(
      title: "Reset", action: #selector(menuAction(_:)), keyEquivalent: "r")
    resetItem.tag = MenuAction.reset.rawValue
    editMenu.addItem(resetItem)

    editMenu.addItem(NSMenuItem.separator())

    let clearItem = NSMenuItem(
      title: "Clear All", action: #selector(menuAction(_:)), keyEquivalent: "")
    clearItem.tag = MenuAction.clearAll.rawValue
    editMenu.addItem(clearItem)

    mainMenu.addItem(editMenuItem)

    // View Menu
    let viewMenuItem = NSMenuItem()
    let viewMenu = NSMenu(title: "View")
    viewMenuItem.submenu = viewMenu

    let toggleThemeItem = NSMenuItem(
      title: "Toggle Dark Mode", action: #selector(menuAction(_:)), keyEquivalent: "d")
    toggleThemeItem.keyEquivalentModifierMask = [.command, .shift]
    toggleThemeItem.tag = MenuAction.toggleTheme.rawValue
    viewMenu.addItem(toggleThemeItem)

    mainMenu.addItem(viewMenuItem)

    // Window Menu (managed by system)
    let windowMenuItem = NSMenuItem()
    let windowMenu = NSMenu(title: "Window")
    windowMenuItem.submenu = windowMenu

    windowMenu.addItem(
      NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
    )
    windowMenu.addItem(
      NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: ""))
    windowMenu.addItem(NSMenuItem.separator())
    windowMenu.addItem(
      NSMenuItem(
        title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)),
        keyEquivalent: ""))

    mainMenu.addItem(windowMenuItem)

    NSApplication.shared.mainMenu = mainMenu
  }

  @objc private func showAbout() {
    // Get version info from bundle
    let version =
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "4.1.0"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    let options: [NSApplication.AboutPanelOptionKey: Any] = [
      .applicationName: "XMEdit",
      .applicationVersion: "Version \(version)",
      .version: "Build \(buildNumber)",
    ]

    NSApplication.shared.orderFrontStandardAboutPanel(options: options)
  }

  @objc private func menuAction(_ sender: NSMenuItem) {
    guard let action = MenuAction(rawValue: sender.tag) else { return }

    // Send action to Flutter via method channel
    menuChannel?.invokeMethod("menuAction", arguments: action.stringValue)
  }

  private enum MenuAction: Int {
    case open = 1
    case save = 2
    case saveAs = 3
    case undo = 4
    case reset = 5
    case clearAll = 6
    case toggleTheme = 7

    var stringValue: String {
      switch self {
      case .open: return "open"
      case .save: return "save"
      case .saveAs: return "saveAs"
      case .undo: return "undo"
      case .reset: return "reset"
      case .clearAll: return "clearAll"
      case .toggleTheme: return "toggleTheme"
      }
    }
  }
}
