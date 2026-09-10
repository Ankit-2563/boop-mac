import Foundation
import AppKit

struct InstalledApp: Codable, Hashable {
    let name: String
    let path: String
    let bundleId: String
}

enum AppScanner {
    static func scanInstalledApps() -> [InstalledApp] {
        let fileManager = FileManager.default
        let searchDirs = ["/Applications"]

        var results: [InstalledApp] = []
        for dir in searchDirs {
            guard let entries = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries where entry.hasSuffix(".app") {
                let fullPath = (dir as NSString).appendingPathComponent(entry)
                let displayName = (entry as NSString).deletingPathExtension
                let bundle = Bundle(path: fullPath)
                let bundleId = bundle?.bundleIdentifier ?? fullPath
                results.append(InstalledApp(name: displayName, path: fullPath, bundleId: bundleId))
            }
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
