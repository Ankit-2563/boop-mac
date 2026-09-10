import Foundation

struct InstalledApp: Codable, Hashable {
    let name: String
    let path: String
    let bundleId: String
}
