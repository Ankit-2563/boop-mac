import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let httpServer = DockHTTPServer()
    private var bonjourService: NetService?
    private let tokenKey = "com.boop.pairingToken"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        loadOrCreateToken()
        httpServer.start()
        advertiseBonjour()
    }

    func applicationWillTerminate(_ notification: Notification) {
        httpServer.stop()
        bonjourService?.stop()
    }

    // MARK: - Menu bar UI

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
        let newToken = String(format: "%06d", Int.random(in: 0..<1_000_000))
        httpServer.pairingToken = newToken
        UserDefaults.standard.set(newToken, forKey: tokenKey)
        rebuildMenu()
    }

    private func loadOrCreateToken() {
        if let saved = UserDefaults.standard.string(forKey: tokenKey), !saved.isEmpty {
            httpServer.pairingToken = saved
        } else {
            let newToken = String(format: "%06d", Int.random(in: 0..<1_000_000))
            httpServer.pairingToken = newToken
            UserDefaults.standard.set(newToken, forKey: tokenKey)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Bonjour advertising

    private func advertiseBonjour() {
        let service = NetService(domain: "local.", type: "_boop._tcp.", name: Host.current().localizedName ?? "Mac", port: Int32(httpServer.port))
        service.publish()
        bonjourService = service
    }
}
