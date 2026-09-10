import Foundation
import Swifter

final class DockHTTPServer {
    private let server = HttpServer()
    let port: in_port_t = 8492
    var pairingToken: String = ""

    func start() {
        server["/ping"] = { [weak self] request in
            guard let self else { return .internalServerError }
            let body: [String: Any] = [
                "deviceName": Host.current().localizedName ?? "Mac",
                "requiresToken": true
            ]
            return .ok(.json(body))
        }

        try? server.start(port, forceIPv4: true)
    }

    func stop() {
        server.stop()
    }
}
