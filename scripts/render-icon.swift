// Renders the app icon with the app's own palette and display font.
// Usage: swift scripts/render-icon.swift <fonts-dir> <output.png>
import AppKit
import CoreText
import SwiftUI

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    print("Usage: swift scripts/render-icon.swift <fonts-dir> <output.png>")
    exit(1)
}

let fontURL = URL(fileURLWithPath: arguments[1]).appending(path: "BricolageGrotesque-ExtraBold.ttf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let felt = Color(hex: 0x1E1A3C)
    static let crewInk = Color(hex: 0xFFD23F)
    static let imposterInk = Color(hex: 0xFF3D7F)
}

/// A card with an off-register second ink behind it, like the app's PlayingCard.
struct IconCard<Content: View>: View {
    var face: Color
    var misprint: Color
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 64, style: .continuous)
        ZStack {
            shape.fill(face)
            content
        }
        .background {
            shape.fill(misprint).offset(x: 22, y: 22)
        }
        .frame(width: 470, height: 658)
    }
}

struct AppIcon: View {
    var body: some View {
        ZStack {
            Color.felt
            IconCard(face: .crewInk, misprint: .imposterInk) { EmptyView() }
                .rotationEffect(.degrees(-13))
                .offset(x: -118, y: 18)
            IconCard(face: .imposterInk, misprint: .crewInk) {
                Text("?")
                    .font(.custom("BricolageGrotesque96ptExtraBold-ExtraBold", size: 420))
                    .foregroundStyle(Color.felt)
                    .offset(y: -10)
            }
            .rotationEffect(.degrees(9))
            .offset(x: 92, y: -6)
        }
        .frame(width: 1024, height: 1024)
    }
}

let image: CGImage? = MainActor.assumeIsolated {
    let renderer = ImageRenderer(content: AppIcon())
    renderer.scale = 1
    return renderer.cgImage
}

guard let image else {
    print("Rendering failed")
    exit(1)
}
// App icons must be opaque, so flatten onto an RGB context with no alpha channel.
guard let context = CGContext(
    data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    print("Couldn't create a drawing context")
    exit(1)
}
context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
guard let opaque = context.makeImage() else {
    print("Flattening failed")
    exit(1)
}
let bitmap = NSBitmapImageRep(cgImage: opaque)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    print("PNG encoding failed")
    exit(1)
}
try png.write(to: URL(fileURLWithPath: arguments[2]))
print("Wrote \(arguments[2])")
