import UIKit

// MARK: - AuthPasswordViewController
/// Màn nhập mật khẩu (Figma node 161-15505; trạng thái hợp lệ 161-15570).
/// Cùng bố cục + hiệu ứng bàn phím với màn email. Có nút ẩn/hiện mật khẩu,
/// dòng gợi ý độ dài tối thiểu và link "Quên mật khẩu?".
final class AuthPasswordViewController: AuthFormViewController {

    private let email: String
    private let minLength = 8

    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var formTitle: String { "Nhập mật khẩu" }

    // MARK: Field
    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.isSecureTextEntry = true
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.textContentType = .newPassword
        return tf
    }()

    private lazy var eyeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "eye.slash")
        config.baseForegroundColor = AuthTheme.textPrimary
        config.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true                       // chỉ hiện khi đã nhập
        b.addTarget(self, action: #selector(toggleSecure), for: .touchUpInside)
        return b
    }()

    // MARK: Accessory (hint + quên mật khẩu)
    private let hintLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        return l
    }()

    private lazy var forgotButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("Quên mật khẩu?", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .regular)]))
        config.baseForegroundColor = AuthTheme.green
        config.contentInsets = .init(top: 2, leading: 4, bottom: 2, trailing: 4)
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(forgotTapped), for: .touchUpInside)
        return b
    }()

    override var headAccessoryViews: [UIView] {
        let stack = UIStackView(arrangedSubviews: [hintLabel, forgotButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return [stack]
    }

    override func makeFieldContent() {
        passwordField.attributedPlaceholder = placeholder("Nhập mật khẩu của bạn")
        installField(passwordField, trailingInset: 52)
        fieldContainer.addSubview(eyeButton)
        NSLayoutConstraint.activate([
            eyeButton.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -10),
            eyeButton.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hintLabel.attributedText = makeHintText()
    }

    override var isComplete: Bool {
        (passwordField.text ?? "").count >= minLength
    }

    override func fieldDidChange() {
        super.fieldDidChange()
        eyeButton.isHidden = (passwordField.text ?? "").isEmpty
    }

    /// "Mật khẩu phải có ít nhất 8 ký tự" — xám, riêng "8 ký tự" trắng.
    private func makeHintText() -> NSAttributedString {
        let full = "Mật khẩu phải có ít nhất 8 ký tự"
        let s = NSMutableAttributedString(string: full, attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: AuthTheme.textSecondary,
        ])
        let r = (full as NSString).range(of: "8 ký tự")
        if r.location != NSNotFound {
            s.addAttribute(.foregroundColor, value: AuthTheme.textPrimary, range: r)
        }
        return s
    }

    override func didTapContinue() {
        view.endEditing(true)
        navigationController?.pushViewController(
            AuthSuccessViewController(email: email), animated: true)
    }

    // MARK: Actions
    @objc private func toggleSecure() {
        passwordField.isSecureTextEntry.toggle()
        let icon = passwordField.isSecureTextEntry ? "eye.slash" : "eye"
        eyeButton.configuration?.image = UIImage(systemName: icon)
        // Giữ con trỏ cuối khi đổi chế độ bảo mật (tránh nhảy/clear text).
        if let text = passwordField.text {
            passwordField.text = ""
            passwordField.text = text
        }
    }

    @objc private func forgotTapped() {
        view.endEditing(true)
        navigationController?.pushViewController(AuthForgotPasswordViewController(), animated: true)
    }
}
