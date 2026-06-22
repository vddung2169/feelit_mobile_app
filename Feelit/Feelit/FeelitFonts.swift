import UIKit

// MARK: - FeelitFonts
/// Typography scale cho FEELIT. SF Pro Rounded cho Display/Heading,
/// SF Pro mặc định cho phần còn lại.
enum FeelitFonts {

    /// SF Pro Rounded với weight chỉ định (fallback về system nếu thiếu).
    static func rounded(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }

    // Display: SF Pro Rounded Bold 32
    static var display: UIFont { rounded(32, weight: .bold) }

    // Heading: SF Pro Rounded Bold 22
    static var heading: UIFont { rounded(22, weight: .bold) }

    // Title: SF Pro Display Semibold 17
    static var title: UIFont { .systemFont(ofSize: 17, weight: .semibold) }

    // Body: SF Pro Text Regular 15
    static var body: UIFont { .systemFont(ofSize: 15, weight: .regular) }

    // Caption: SF Pro Text Regular 13
    static var caption: UIFont { .systemFont(ofSize: 13, weight: .regular) }

    // Micro: SF Pro Text Medium 11 (dùng uppercase + letterSpacing 0.5 khi set text)
    static var micro: UIFont { .systemFont(ofSize: 11, weight: .medium) }
}

// MARK: - Spacing & Radius tokens
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48
}

enum Radius {
    static let badge: CGFloat = 8
    static let button: CGFloat = 12
    static let smallCard: CGFloat = 16
    static let card: CGFloat = 20
    static let largeCard: CGFloat = 24
}

enum Motion {
    static let duration: TimeInterval = 0.3
    static let damping: CGFloat = 0.75
    static let velocity: CGFloat = 0.5
}

// MARK: - Label helpers
extension UILabel {
    /// Set text dạng Micro: uppercase + letterSpacing 0.5.
    func setMicro(_ text: String, color: UIColor) {
        font = FeelitFonts.micro
        textColor = color
        attributedText = NSAttributedString(
            string: text.uppercased(),
            attributes: [.kern: 0.5]
        )
    }
}
