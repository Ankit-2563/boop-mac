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
        let searchDirs = [
            "/Applications",
            "/System/Applications",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications")
        ]

        var results: [InstalledApp] = []
        var seenPaths = Set<String>()

        for dir in searchDirs {
            guard let entries = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries where entry.hasSuffix(".app") {
                let fullPath = (dir as NSString).appendingPathComponent(entry)
                guard !seenPaths.contains(fullPath) else { continue }
                seenPaths.insert(fullPath)

                let displayName = (entry as NSString).deletingPathExtension
                let bundle = Bundle(path: fullPath)
                let bundleId = bundle?.bundleIdentifier ?? fullPath

                results.append(InstalledApp(name: displayName, path: fullPath, bundleId: bundleId))
            }
        }

        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

extension AppScanner {
    static func iconPNGData(forAppAtPath path: String, size: CGFloat = 256) -> Data? {
        let icon = NSWorkspace.shared.icon(forFile: path)
        let targetSize = NSSize(width: size, height: size)

        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: targetSize),
                  from: NSRect(origin: .zero, size: icon.size),
                  operation: .copy,
                  fraction: 1.0)
        resized.unlockFocus()

        guard let tiff = resized.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return png
    }
}
