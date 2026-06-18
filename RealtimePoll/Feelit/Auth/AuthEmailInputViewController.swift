import UIKit

// MARK: - AuthEmailInputViewController
/// Màn nhập email (Figma node 161-5202 mặc định / 140-8096 khi có bàn phím).
/// Kế thừa `AuthFormViewController` để dùng chung bố cục + hiệu ứng bàn phím.
final class AuthEmailInputViewController: AuthFormViewController {

    override var formTitle: String { "Email của bạn là?" }

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.textContentType = .emailAddress
        return tf
    }()

    private lazy var usePhoneButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("Sử dụng Số Điện Thoại", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 15, weight: .medium)]))
        config.baseForegroundColor = AuthTheme.textPrimary
        config.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(usePhoneTapped), for: .touchUpInside)
        return b
    }()

    override var headAccessoryViews: [UIView] { [usePhoneButton] }

    override func makeFieldContent() {
        emailField.attributedPlaceholder = placeholder("Nhập Email của bạn")
        installField(emailField)
    }

    override var isComplete: Bool {
        let text = (emailField.text ?? "").trimmingCharacters(in: .whitespaces)
        return text.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    override func didTapContinue() {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespaces)
        navigationController?.pushViewController(AuthPasswordViewController(email: email), animated: true)
    }

    @objc private func usePhoneTapped() {
        navigationController?.pushViewController(AuthPhoneViewController(), animated: true)
    }
}
