import UIKit

// MARK: - AuthUI
/// Factory các thành phần UI dùng chung của flow Auth (nút Trở lại, ô nhập, nút chính),
/// cho các màn có bố cục riêng không kế thừa `AuthFormViewController`.
enum AuthUI {

    /// Nút "‹ Trở lại" góc trái.
    static func backButton(target: Any?, action: Selector) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        config.imagePadding = 4
        config.attributedTitle = AttributedString("Trở lại", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 17, weight: .regular)]))
        config.baseForegroundColor = AuthTheme.textPrimary
        config.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(target, action: action, for: .touchUpInside)
        return b
    }

    /// Ô bao quanh input (nền + viền), cao 56. Caller tự gắn textfield vào trong.
    static func fieldContainer() -> UIView {
        let v = UIView()
        v.backgroundColor = AuthTheme.inputField
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = AuthTheme.fieldBorder.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return v
    }

    /// Gắn `field` vào `container` với style + constraint chuẩn.
    static func install(_ field: UITextField, in container: UIView) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = .systemFont(ofSize: 16, weight: .regular)
        field.textColor = AuthTheme.textPrimary
        field.tintColor = AuthTheme.green
        container.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            field.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
    }

    static func placeholder(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.foregroundColor: AuthTheme.placeholder])
    }

    /// Nhãn nhỏ phía trên ô nhập (vd "Nhập mật khẩu mới").
    static func fieldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = AuthTheme.textPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    /// Nút chính "Tiếp tục" (pill), cao 54.
    static func continueButton(target: Any?, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString("Tiếp tục", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 54).isActive = true
        b.addTarget(target, action: action, for: .touchUpInside)
        return b
    }

    /// Cập nhật style nút theo trạng thái hợp lệ (xanh / xám).
    static func setEnabled(_ button: UIButton, _ enabled: Bool) {
        var config = button.configuration
        config?.baseBackgroundColor = enabled ? AuthTheme.green : AuthTheme.buttonDisabled
        config?.baseForegroundColor = enabled ? AuthTheme.onGreen : AuthTheme.placeholder
        button.configuration = config
        button.isEnabled = enabled
    }

    /// Bật/tắt spinner trên nút (khi gọi API). Caller gọi `setEnabled` lại sau khi xong.
    static func setLoading(_ button: UIButton, _ loading: Bool) {
        var config = button.configuration
        config?.showsActivityIndicator = loading
        button.configuration = config
        if loading { button.isEnabled = false }
    }

    static func isValidEmail(_ text: String?) -> Bool {
        let t = (text ?? "").trimmingCharacters(in: .whitespaces)
        return t.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }
}
