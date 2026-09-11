import Cocoa

/// Floating window panel displaying the QR code and connection fallback details.
final class QRPanel: NSPanel {
    init(payload: PairingPayload) {
        let panelWidth: CGFloat = 280
        let panelHeight: CGFloat = 360

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        title = "Boop — Pair"
        isFloatingPanel = true
        level = .floating
        isReleasedWhenClosed = false
        center()

        configureContentView(with: payload, width: panelWidth, height: panelHeight)
    }

    func update(with payload: PairingPayload) {
        configureContentView(with: payload, width: frame.width, height: frame.height)
    }

    private func configureContentView(with payload: PairingPayload, width: CGFloat, height: CGFloat) {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))

        let titleLabel = NSTextField(labelWithString: "Scan with your phone")
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 0, y: height - 40, width: width, height: 20)
        view.addSubview(titleLabel)

        if let qrImage = QRGenerator.generate(from: payload.uriString, size: 200) {
            let imageView = NSImageView(frame: NSRect(x: (width - 200) / 2, y: height - 260, width: 200, height: 200))
            imageView.image = qrImage
            imageView.imageScaling = .scaleProportionallyUpOrDown
            view.addSubview(imageView)
        }

        let infoLabel = NSTextField(labelWithString: "IP: \(payload.host):\(payload.port)")
        infoLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.alignment = .center
        infoLabel.frame = NSRect(x: 0, y: height - 290, width: width, height: 16)
        view.addSubview(infoLabel)

        let codeLabel = NSTextField(labelWithString: "Code: \(payload.token)")
        codeLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        codeLabel.textColor = .secondaryLabelColor
        codeLabel.alignment = .center
        codeLabel.frame = NSRect(x: 0, y: height - 310, width: width, height: 16)
        view.addSubview(codeLabel)

        contentView = view
    }
}
