import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let httpServer = DockHTTPServer()
    private var bonjourService: NetService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        regenerateToken()
        httpServer.start()
        advertiseBonjour()
    }

    func applicationWillTerminate(_ notification: Notification) {
        httpServer.stop()
        bonjourService?.stop()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: "Boop")
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let codeItem = NSMenuItem(title: "Pairing code: \(httpServer.pairingToken)", action: nil, keyEquivalent: "")
        codeItem.isEnabled = false
        menu.addItem(codeItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Regenerate Code", action: #selector(regenerateAndRefresh), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Boop", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func regenerateAndRefresh() {
        regenerateToken()
        rebuildMenu()
    }

    private func regenerateToken() {
        httpServer.pairingToken = String(format: "%06d", Int.random(in: 0..<1_000_000))
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func advertiseBonjour() {
        let service = NetService(domain: "local.", type: "_boop._tcp.", name: Host.current().localizedName ?? "Mac", port: Int32(httpServer.port))
        service.publish()
        bonjourService = service
    }
}
