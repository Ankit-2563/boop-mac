import Foundation
import AppKit

struct InstalledApp: Codable, Hashable {
    let name: String
    let path: String
    let bundleId: String
}

enum AppScanner {

    /// Scans the standard locations for installed .app bundles.
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

    /// Renders an app's icon as PNG data, resized to a reasonable size for phone display.
    /// Uses NSGraphicsContext instead of the deprecated lockFocus/unlockFocus APIs.
    static func iconPNGData(forAppAtPath path: String, size: CGFloat = 256) -> Data? {
        let icon = NSWorkspace.shared.icon(forFile: path)
        let targetSize = NSSize(width: size, height: size)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size),
            pixelsHigh: Int(size),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        rep.size = targetSize

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        icon.draw(in: NSRect(origin: .zero, size: targetSize),
                  from: NSRect(origin: .zero, size: icon.size),
                  operation: .copy,
                  fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:])
    }

    /// Launches an app by path, with proper async completion handling.
    static func launch(appAtPath path: String, completion: @escaping (Bool) -> Void) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
}
