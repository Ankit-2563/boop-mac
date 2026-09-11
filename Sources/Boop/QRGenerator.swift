import Cocoa
import CoreImage

/// Generates crisp vector-scaled QR code images using macOS native CoreImage APIs.
enum QRGenerator {
    /// Generates an NSImage containing a QR code for the provided string payload.
    /// - Parameters:
    ///   - string: Content to encode in the QR code.
    ///   - size: Target width and height in points.
    /// - Returns: Rendered NSImage, or nil if generation fails.
    static func generate(from string: String, size: CGFloat = 200) -> NSImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        let scale = size / ciImage.extent.width
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let rep = NSCIImageRep(ciImage: scaled)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
}
