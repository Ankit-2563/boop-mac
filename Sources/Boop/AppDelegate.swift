import Cocoa

struct PairedDevice {
    var name: String
    var lastSeen: Date

    var isOnline: Bool {
        Date().timeIntervalSince(lastSeen) <= 15
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let httpServer = DockHTTPServer()
    private var bonjourService: NetService?
    private let tokenKey = "com.boop.pairingToken"
    private let pairedDeviceNameKey = "com.boop.pairedDeviceName"
    private var qrPanel: QRPanel?

    private var pairedDevice: PairedDevice?
    private var statusTimer: Timer?
    private var lastReportedOnlineState: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        loadOrCreateToken()
        loadPairedDevice()
        setupServerCallbacks()
        httpServer.start()
        advertiseBonjour()
        startStatusTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusTimer?.invalidate()
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

        if let device = pairedDevice {
            let isOnline = device.isOnline
            let statusText = isOnline ? "Online" : "Offline"
            let dot = isOnline ? "🟢" : "⚪"

            let deviceItem = NSMenuItem(
                title: "\(dot) \(device.name) (\(statusText))",
                action: nil,
                keyEquivalent: ""
            )
            deviceItem.isEnabled = false
            menu.addItem(deviceItem)

            let unpairItem = NSMenuItem(
                title: "Unpair",
                action: #selector(unpairDevice),
                keyEquivalent: "u"
            )
            menu.addItem(unpairItem)

            menu.addItem(NSMenuItem.separator())
            statusItem.button?.toolTip = "Boop — \(device.name) (\(statusText))"
        } else {
            statusItem.button?.toolTip = "Boop — No Device Paired"
        }

        menu.addItem(NSMenuItem(title: "Show QR Code", action: #selector(showQRWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Regenerate Code", action: #selector(regenerateAndRefresh), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Boop", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Server Callbacks & Pairing State

    private func setupServerCallbacks() {
        httpServer.onDevicePair = { [weak self] name in
            guard let self else { return }
            self.pairedDevice = PairedDevice(name: name, lastSeen: Date())
            UserDefaults.standard.set(name, forKey: self.pairedDeviceNameKey)
            self.lastReportedOnlineState = true
            self.rebuildMenu()
        }

        httpServer.onHeartbeat = { [weak self] name in
            guard let self else { return }
            let currentName = (!name.isEmpty) ? name : (self.pairedDevice?.name ?? "Android Device")
            let wasOnline = self.pairedDevice?.isOnline ?? false
            self.pairedDevice = PairedDevice(name: currentName, lastSeen: Date())
            UserDefaults.standard.set(currentName, forKey: self.pairedDeviceNameKey)
            if !wasOnline {
                self.lastReportedOnlineState = true
                self.rebuildMenu()
            }
        }

        httpServer.onDeviceUnpair = { [weak self] in
            guard let self else { return }
            self.unpairDevice()
        }
    }

    private func loadPairedDevice() {
        if let name = UserDefaults.standard.string(forKey: pairedDeviceNameKey), !name.isEmpty {
            pairedDevice = PairedDevice(name: name, lastSeen: .distantPast)
            lastReportedOnlineState = false
            rebuildMenu()
        }
    }

    private func startStatusTimer() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self, let device = self.pairedDevice else { return }
            let currentOnline = device.isOnline
            if self.lastReportedOnlineState != currentOnline {
                self.lastReportedOnlineState = currentOnline
                self.rebuildMenu()
            }
        }
    }

    @objc private func unpairDevice() {
        pairedDevice = nil
        lastReportedOnlineState = nil
        UserDefaults.standard.removeObject(forKey: pairedDeviceNameKey)
        regenerateAndRefresh()
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
        pairedDevice = nil
        lastReportedOnlineState = nil
        UserDefaults.standard.removeObject(forKey: pairedDeviceNameKey)
        rebuildMenu()
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
