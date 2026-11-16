
import SwiftUI
import UIKit

enum DS {
    // Exact spec colors (dark) with adaptive light variants via dynamic UIColor.
    static func dynamic(dark: UInt, light: UInt) -> Color {
        Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .light ? light : dark
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
    static var background: Color { dynamic(dark: 0x08080B, light: 0xF7F7FA) }
    static var secondaryBackground: Color { dynamic(dark: 0x101015, light: 0xFFFFFF) }
    static var surface: Color { dynamic(dark: 0x191920, light: 0xECECF1) }
    static var surfaceElevated: Color { dynamic(dark: 0x1D1D25, light: 0xE2E2EA) }
    static var accent: Color { Color(red: 0xB6/255, green: 0x9C/255, blue: 0xFF/255) }
    static var accentSecondary: Color { Color(red: 0x8B/255, green: 0x78/255, blue: 0xD8/255) }
    static var textPrimary: Color { dynamic(dark: 0xFFFFFF, light: 0x111116) }
    static var textSecondary: Color { dynamic(dark: 0xA1A1AA, light: 0x5C5C66) }
    static var separator: Color { dynamic(dark: 0x303039, light: 0xD8D8E0) }

    static let cornerCard: CGFloat = 18
    static let cornerArtwork: CGFloat = 12

    static func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

extension View {
    func sonoraBackground() -> some View { background(DS.background.ignoresSafeArea()) }
    func cardStyle() -> some View {
        background(DS.surface).clipShape(RoundedRectangle(cornerRadius: DS.cornerCard))
    }
}

/// Average color of artwork data, used for Now Playing dynamic backgrounds.
enum ArtworkColor {
    static func averageColor(from data: Data?) -> Color {
        guard let data, let image = UIImage(data: data),
              let cg = image.cgImage else { return DS.accentSecondary }
        let width = 4, height = 4
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let ctx = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        ctx?.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        var r = 0, g = 0, b = 0
        for i in stride(from: 0, to: pixels.count, by: 4) { r += Int(pixels[i]); g += Int(pixels[i+1]); b += Int(pixels[i+2]) }
        let n = max(width * height, 1)
        return Color(red: Double(r / n) / 255, green: Double(g / n) / 255, blue: Double(b / n) / 255)
    }
}
