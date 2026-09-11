import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let httpServer = DockHTTPServer()
    private var bonjourService: NetService?
    private let tokenKey = "com.boop.pairingToken"
    private var qrPanel: QRPanel?

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

        menu.addItem(NSMenuItem(title: "Show QR Code", action: #selector(showQRWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Regenerate Code", action: #selector(regenerateAndRefresh), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Boop", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Pairing & QR Window

    private var currentPayload: PairingPayload {
        let ip = DockHTTPServer.localIPAddress() ?? "127.0.0.1"
        return PairingPayload(host: ip, port: Int(httpServer.port), token: httpServer.pairingToken)
    }

    @objc private func showQRWindow() {
        if let panel = qrPanel {
            panel.update(with: currentPayload)
            panel.makeKeyAndOrderFront(nil)
        } else {
            let panel = QRPanel(payload: currentPayload)
            panel.makeKeyAndOrderFront(nil)
            qrPanel = panel
        }
    }

    // MARK: - Token Management

    @objc private func regenerateAndRefresh() {
        let newToken = generateToken()
        httpServer.pairingToken = newToken
        UserDefaults.standard.set(newToken, forKey: tokenKey)
        if let panel = qrPanel, panel.isVisible {
            panel.update(with: currentPayload)
        }
    }

    private func loadOrCreateToken() {
        if let saved = UserDefaults.standard.string(forKey: tokenKey), !saved.isEmpty {
            httpServer.pairingToken = saved
        } else {
            let newToken = generateToken()
            httpServer.pairingToken = newToken
            UserDefaults.standard.set(newToken, forKey: tokenKey)
        }
    }

    private func generateToken() -> String {
        String(format: "%06d", Int.random(in: 0..<1_000_000))
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Bonjour Advertising

    private func advertiseBonjour() {
        let service = NetService(
            domain: "local.",
            type: "_boop._tcp.",
            name: Host.current().localizedName ?? "Mac",
            port: Int32(httpServer.port)
        )
        service.publish()
        bonjourService = service
    }
}
