import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let httpServer = DockHTTPServer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        httpServer.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        httpServer.stop()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: "Boop")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Boop", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
