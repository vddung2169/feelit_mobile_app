import UIKit

// MARK: - AppTheme
/// Lựa chọn giao diện người dùng, lưu vào UserDefaults để giữ qua các lần mở app.
enum AppTheme: Int, CaseIterable {
    case system = 0   // Theo hệ thống
    case light  = 1   // Sáng
    case dark   = 2   // Tối

    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var title: String {
        switch self {
        case .system: return "Tự động"
        case .light:  return "Sáng"
        case .dark:   return "Tối"
        }
    }

    var subtitle: String {
        switch self {
        case .system: return "Theo cài đặt hệ thống"
        case .light:  return "Luôn dùng giao diện sáng"
        case .dark:   return "Luôn dùng giao diện tối"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - ThemeManager
/// Quản lý theme toàn cục: đọc/ghi lựa chọn và áp dụng cho mọi cửa sổ.
final class ThemeManager {
    static let shared = ThemeManager()
    private init() {}

    private let key = "app.theme.preference"

    var current: AppTheme {
        get { AppTheme(rawValue: UserDefaults.standard.integer(forKey: key)) ?? .system }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            apply()
        }
    }

    /// Áp dụng theme hiện tại cho tất cả cửa sổ đang hoạt động.
    func apply() {
        let style = current.uiStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for window in ws.windows {
                UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }
}

// MARK: - Theme palette (adaptive light/dark)
/// Bảng màu dùng chung, tự đổi theo light/dark. Màu nền/chữ/viền là adaptive;
/// màu nhấn (xanh/đỏ/vàng/vote) giữ nguyên ở cả hai chế độ.
/// Giá trị light = bảng màu Figma light; dark = bảng màu Figma dark.
enum Theme {

    private static func dyn(_ light: UInt32, _ dark: UInt32) -> UIColor {
        UIColor { tc in UIColor(hex: tc.userInterfaceStyle == .dark ? dark : light) }
    }

    // Nền & bề mặt
    static let page         = dyn(0xFFFFFF, 0x111111)
    static let surface      = dyn(0xFBFBFB, 0x181818)
    static let card         = dyn(0xF7F7F7, 0x181818)
    static let surfaceRaised = dyn(0xFBFBFB, 0x3A3A3A)   // bề mặt nổi (vd pill đang chọn trong segment)
    static let track        = dyn(0xEDEDED, 0x292929)
    static let border       = dyn(0xE6E6E6, 0x2E2E2E)
    static let borderStrong = dyn(0xCCCCCC, 0x474747)

    // Chữ
    static let textPrimary   = dyn(0x202020, 0xEDEDED)
    static let textSecondary = dyn(0x818181, 0xB3B3B3)
    static let textTertiary  = dyn(0xB9B9B9, 0x606060)

    // Màu nhấn (giữ nguyên cả light/dark)
    static let green    = UIColor(hex: 0x4CAF50)
    static let red      = UIColor(hex: 0xF44336)
    static let gold     = UIColor(hex: 0xE6C209)
    static let goldRank = UIColor(hex: 0xFFD609)
    static let voteUp   = UIColor(hex: 0x74FF7A)
    static let voteDown = UIColor(hex: 0xEF5350)
    static let redDot   = UIColor(hex: 0xFE3333)

    /// Chữ/icon nằm trên nền màu nhấn (vd "Lưu" trên nút xanh) — luôn sáng.
    static let onAccent = UIColor(hex: 0xEDEDED)
}

// MARK: - ThemeCardView
/// UIView có viền dùng `UIColor` adaptive. `layer.borderColor` (CGColor) không tự
/// đổi theo light/dark, nên view này tự resolve lại viền mỗi khi trait đổi.
class ThemeCardView: UIView {
    /// Màu viền adaptive; gán xong sẽ tự áp dụng theo chế độ hiện tại.
    var borderUIColor: UIColor? { didSet { refreshBorder() } }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previous) { refreshBorder() }
    }

    private func refreshBorder() {
        layer.borderColor = borderUIColor?.resolvedColor(with: traitCollection).cgColor
    }
}
