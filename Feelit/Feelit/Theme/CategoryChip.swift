import UIKit

// MARK: - CategoryChip
/// Chip danh mục ("Xu hướng", "Chứng khoán VN", ...).
/// • iOS 26+: dùng Liquid Glass (UIButton.Configuration.glass / prominentGlass).
/// • iOS < 26: giữ nguyên giao diện viên bo góc như cũ (nền tối khi chọn / trong suốt khi chưa).
enum CategoryChip {

    /// Tạo chip mới với hành động bấm.
    /// - Parameters:
    ///   - glass: dùng Liquid Glass (iOS 26+). Đặt `false` khi chip nằm trong header đã là kính.
    ///   - icon: SF Symbol hiển thị trước tiêu đề (vd "Xu hướng" có mũi tên xu hướng).
    static func make(title: String, selected: Bool, glass: Bool = true,
                     icon: String? = nil, action: UIAction) -> UIButton {
        let button = UIButton()
        apply(to: button, title: title, selected: selected, glass: glass, icon: icon)
        button.addAction(action, for: .touchUpInside)
        return button
    }

    /// Cập nhật tiêu đề + trạng thái chọn (gọi khi đổi danh mục).
    static func update(_ button: UIButton, title: String, selected: Bool,
                       glass: Bool = true, icon: String? = nil) {
        apply(to: button, title: title, selected: selected, glass: glass, icon: icon)
    }

    // MARK: - Áp dụng style theo phiên bản hệ điều hành
    private static func apply(to button: UIButton, title: String, selected: Bool,
                              glass: Bool, icon: String?) {
        if glass, #available(iOS 26.0, *) {
            button.configuration = glassConfig(title: title, selected: selected, icon: icon)
            button.backgroundColor = .clear
            button.layer.cornerRadius = 0
            button.clipsToBounds = false
        } else {
            button.configuration = legacyConfig(title: title, selected: selected, icon: icon)
            button.backgroundColor = selected ? Theme.textPrimary : .clear
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
        }
    }

    @available(iOS 26.0, *)
    private static func glassConfig(title: String, selected: Bool, icon: String?) -> UIButton.Configuration {
        // Đã chọn → glass "prominent" (đậm, có tông); chưa chọn → glass trong.
        var c = selected ? UIButton.Configuration.prominentGlass()
                         : UIButton.Configuration.glass()
        c.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: selected ? .semibold : .regular)]))
        c.baseForegroundColor = selected ? Theme.page : Theme.textPrimary
        if selected { c.baseBackgroundColor = Theme.textPrimary }   // tông kính cho viên đang chọn
        c.cornerStyle = .capsule
        c.contentInsets = .init(top: 6, leading: 16, bottom: 6, trailing: 16)
        applyIcon(icon, to: &c)
        return c
    }

    private static func legacyConfig(title: String, selected: Bool, icon: String?) -> UIButton.Configuration {
        var c = UIButton.Configuration.plain()
        c.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .regular)]))
        c.baseForegroundColor = selected ? Theme.page : Theme.textPrimary
        c.contentInsets = .init(top: 6, leading: 14, bottom: 6, trailing: 14)
        applyIcon(icon, to: &c)
        return c
    }

    private static func applyIcon(_ icon: String?, to c: inout UIButton.Configuration) {
        guard let icon else { return }
        c.image = UIImage(systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        c.imagePlacement = .leading
        c.imagePadding = 5
    }
}
