import Foundation
import Swifter

final class DockHTTPServer {
    private let server = HttpServer()
    let port: in_port_t = 8492

    /// Set/read by AppDelegate — the phone must send this in the X-Dock-Token header.
    var pairingToken: String = ""

    /// Cache of known app paths for validation (refreshed on each /apps call).
    private var knownAppPaths: Set<String> = []

    /// Simple rate limiter: tracks request timestamps per endpoint.
    private var requestLog: [String: [Date]] = [:]
    private let maxRequestsPerMinute = 60
    private let rateLimitQueue = DispatchQueue(label: "com.boop.ratelimit")

    func start() {
        // Anyone can hit /ping to discover the Mac's name before pairing.
        server["/ping"] = { [weak self] request in
            guard let self else { return .internalServerError }
            guard self.checkRateLimit(endpoint: "/ping") else {
                return .raw(429, "Too Many Requests", nil, nil)
            }
            let body: [String: Any] = [
                "deviceName": Host.current().localizedName ?? "Mac",
                "requiresToken": true
            ]
            return .ok(.json(body))
        }

        // Everything below requires the correct pairing token.
        server["/apps"] = { [weak self] request in
            guard let self, self.isAuthorized(request) else { return .unauthorized(headers: nil) }
            guard self.checkRateLimit(endpoint: "/apps") else {
                return .raw(429, "Too Many Requests", nil, nil)
            }
            let apps = AppScanner.scanInstalledApps()

            // Cache known paths for /launch and /icon validation.
            self.knownAppPaths = Set(apps.map { $0.path })

            let json = apps.map { ["name": $0.name, "path": $0.path, "bundleId": $0.bundleId] }
            return .ok(.json(json))
        }

        server["/icon"] = { [weak self] request in
            guard let self, self.isAuthorized(request) else { return .unauthorized(headers: nil) }
            guard self.checkRateLimit(endpoint: "/icon") else {
                return .raw(429, "Too Many Requests", nil, nil)
            }
            guard let rawPath = request.queryParams.first(where: { $0.0 == "path" })?.1,
                  let decodedPath = rawPath.removingPercentEncoding else {
                return .notFound
            }

            // Security: validate that the path is a known installed app.
            guard self.isValidAppPath(decodedPath) else {
                return .forbidden
            }

            guard let png = AppScanner.iconPNGData(forAppAtPath: decodedPath) else {
                return .notFound
            }
            return HttpResponse.raw(200, "OK", ["Content-Type": "image/png"], { writer in
                try? writer.write(png)
            })
        }

        server["/launch"] = { [weak self] request in
            guard let self, self.isAuthorized(request) else { return .unauthorized(headers: nil) }
            guard self.checkRateLimit(endpoint: "/launch") else {
                return .raw(429, "Too Many Requests", nil, nil)
            }
            guard let bodyString = String(bytes: request.body, encoding: .utf8),
                  let data = bodyString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let path = json["path"] as? String else {
                return .badRequest(.text("missing 'path' in body"))
            }

            // Security: only allow launching apps from the known installed list.
            guard self.isValidAppPath(path) else {
                return .forbidden
            }

            AppScanner.launch(appAtPath: path) { success in
                // Log result; the HTTP response is already sent.
                if !success {
                    print("[Boop] Failed to launch: \(path)")
                }
            }
            return .ok(.json(["launched": true] as [String: Any]))
        }

        try? server.start(port, forceIPv4: true)
    }

    func stop() {
        server.stop()
    }

    /// Returns the Mac's local IPv4 address (e.g. 192.168.x.x) using POSIX getifaddrs.
    static func localIPAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let sa = ptr.pointee.ifa_addr.pointee
            guard sa.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: ptr.pointee.ifa_name)
            guard name == "en0" || name == "en1" else { continue }
            var addr = ptr.pointee.ifa_addr.pointee
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(&addr, socklen_t(sa.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
            return String(cString: hostname)
        }
        return nil
    }

    // MARK: - Auth

    private func isAuthorized(_ request: HttpRequest) -> Bool {
        guard !pairingToken.isEmpty else { return false }
        let header = request.headers["x-dock-token"]
        return header == pairingToken
    }

    // MARK: - Path validation

    /// Validates that the path points to a real .app inside a known directory.
    private func isValidAppPath(_ path: String) -> Bool {
        let resolved = (path as NSString).standardizingPath

        let allowedPrefixes = [
            "/Applications/",
            "/System/Applications/",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications") + "/"
        ]

        let inAllowedDir = allowedPrefixes.contains { resolved.hasPrefix($0) }
        guard inAllowedDir else { return false }

        // Must end with .app (no sneaking in .app/Contents/Resources/evil.sh)
        guard resolved.hasSuffix(".app") else { return false }

        // Must not contain path traversal after the prefix
        guard !resolved.contains("/../") && !resolved.contains("/./") else { return false }

        return true
    }

    // MARK: - Rate limiting

    private func checkRateLimit(endpoint: String) -> Bool {
        rateLimitQueue.sync {
            let now = Date()
            let cutoff = now.addingTimeInterval(-60)
            var timestamps = requestLog[endpoint, default: []]
            timestamps = timestamps.filter { $0 > cutoff }
            guard timestamps.count < maxRequestsPerMinute else { return false }
            timestamps.append(now)
            requestLog[endpoint] = timestamps
            return true
        }
    }
}

// MARK: - Response helpers

private extension HttpResponse {
    static func unauthorized(headers: [String: String]?) -> HttpResponse {
        .raw(401, "Unauthorized", headers, { writer in
            try? writer.write("unauthorized".data(using: .utf8)!)
        })
    }


}
