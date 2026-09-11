import Foundation

/// Represents the connection details encoded into the QR code and manual pairing payload.
struct PairingPayload {
    let host: String
    let port: Int
    let token: String

    /// Returns the standardized boop:// URI scheme recognized by the Android app.
    var uriString: String {
        "boop://\(host):\(port)?token=\(token)"
    }
}
