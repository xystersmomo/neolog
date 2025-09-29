import SwiftUI

func colorHex(for name: String) -> String {
    let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !cleaned.isEmpty else { return "#888888" }
    let hash = cleaned.utf8.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1) }
    let hue = Double(abs(hash % 360)) / 360.0
    let saturation = 0.55
    let lightness = 0.55
    let rgb = hslToRGB(hue: hue, saturation: saturation, lightness: lightness)
    return String(format: "#%02X%02X%02X", Int(rgb.r * 255), Int(rgb.g * 255), Int(rgb.b * 255))
}

private func hslToRGB(hue: Double, saturation: Double, lightness: Double) -> (r: Double, g: Double, b: Double) {
    let q: Double
    if lightness < 0.5 {
        q = lightness * (1 + saturation)
    } else {
        q = lightness + saturation - lightness * saturation
    }
    let p = 2 * lightness - q

    func convert(_ t: Double) -> Double {
        var t = t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        switch t {
        case ..<1.0 / 6.0:
            return p + (q - p) * 6.0 * t
        case ..<1.0 / 2.0:
            return q
        case ..<2.0 / 3.0:
            return p + (q - p) * (2.0 / 3.0 - t) * 6.0
        default:
            return p
        }
    }

    let r = convert(hue + 1.0 / 3.0)
    let g = convert(hue)
    let b = convert(hue - 1.0 / 3.0)
    return (max(0, min(1, r)), max(0, min(1, g)), max(0, min(1, b)))
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        guard hexSanitized.count == 6,
              let intCode = Int(hexSanitized, radix: 16) else { return nil }
        let r = Double((intCode >> 16) & 0xFF) / 255.0
        let g = Double((intCode >> 8) & 0xFF) / 255.0
        let b = Double(intCode & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
