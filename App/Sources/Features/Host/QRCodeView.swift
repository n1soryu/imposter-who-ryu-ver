import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// A QR code for some text: dark modules on a light square with a four-module quiet zone, scaled without blurring.
struct QRCodeView: View {
    var text: String

    var body: some View {
        Group {
            if let image = Self.render(text) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.cardStock
            }
        }
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityLabel("QR code for \(text)")
    }

    private static let context = CIContext()

    private static func render(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let code = filter.outputImage else { return nil }
        let scale: CGFloat = 12
        let quiet = 4 * scale
        let scaled = code.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let page = CIImage(color: .white).cropped(to: scaled.extent.insetBy(dx: -quiet, dy: -quiet))
        let composed = scaled.composited(over: page)
        guard let cgImage = context.createCGImage(composed, from: page.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
