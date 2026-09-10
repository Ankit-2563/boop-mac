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

        server["/apps"] = { [weak self] request in
            guard let self, self.isAuthorized(request) else { return .unauthorized(headers: nil) }
            let apps = AppScanner.scanInstalledApps()
            let json = apps.map { ["name": $0.name, "path": $0.path, "bundleId": $0.bundleId] }
            return .ok(.json(json))
        }

        try? server.start(port, forceIPv4: true)
    }

    func stop() {
        server.stop()
    }

    private func isAuthorized(_ request: HttpRequest) -> Bool {
        guard !pairingToken.isEmpty else { return false }
        let header = request.headers["x-dock-token"]
        return header == pairingToken
    }
}

private extension HttpResponse {
    static func unauthorized(headers: [String: String]?) -> HttpResponse {
        .raw(401, "Unauthorized", headers, { writer in
            try? writer.write("unauthorized".data(using: .utf8)!)
        })
    }
}
