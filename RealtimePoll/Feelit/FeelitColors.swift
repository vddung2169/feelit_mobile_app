import UIKit

// MARK: - UIColor + Hex
extension UIColor {
    /// Khởi tạo từ hex dạng 0xRRGGBB hoặc 0xRRGGBBAA.
    convenience init(hex: UInt32, alpha: CGFloat? = nil) {
        let hasAlpha = hex > 0xFFFFFF
        let r, g, b, a: CGFloat
        if hasAlpha {
            r = CGFloat((hex >> 24) & 0xFF) / 255
            g = CGFloat((hex >> 16) & 0xFF) / 255
            b = CGFloat((hex >> 8) & 0xFF) / 255
            a = CGFloat(hex & 0xFF) / 255
        } else {
            r = CGFloat((hex >> 16) & 0xFF) / 255
            g = CGFloat((hex >> 8) & 0xFF) / 255
            b = CGFloat(hex & 0xFF) / 255
            a = 1
        }
        self.init(red: r, green: g, blue: b, alpha: alpha ?? a)
    }
}

// MARK: - FeelitColors
/// Design system palette cho FEELIT. Dùng `FeelitColors.primary`, ...
enum FeelitColors {
    static let background      = UIColor(hex: 0x0A0A0F)
    static let surface         = UIColor(hex: 0x13131A)
    static let surfaceElevated = UIColor(hex: 0x1C1C27)

    static let primary         = UIColor(hex: 0x6C63FF)
    static let primarySoft     = UIColor(hex: 0x6C63FF, alpha: 0.10)

    static let bullish         = UIColor(hex: 0x00D085)
    static let bullishSoft     = UIColor(hex: 0x00D085, alpha: 0.10)

    static let bearish         = UIColor(hex: 0xFF4D6A)
    static let bearishSoft     = UIColor(hex: 0xFF4D6A, alpha: 0.10)

    static let gold            = UIColor(hex: 0xFFB547)
    static let goldSoft        = UIColor(hex: 0xFFB547, alpha: 0.10)

    static let textPrimary     = UIColor(hex: 0xF0F0FF)
    static let textSecondary   = UIColor(hex: 0x8888AA)
    static let textTertiary    = UIColor(hex: 0x44445A)

    static let border          = UIColor(hex: 0xFFFFFF, alpha: 0.06)
    static let overlay         = UIColor(hex: 0x000000, alpha: 0.50)

    /// Gradient brand mặc định (primary → bullish) cho avatar.
    static let avatarGradient: [CGColor] = [primary.cgColor, bullish.cgColor]
}
