import UIKit
import Combine

// MARK: - AuthPasswordViewController
/// Màn nhập mật khẩu (Figma node 161-15505; trạng thái hợp lệ 161-15570).
/// Cùng bố cục + hiệu ứng bàn phím với màn email. Có nút ẩn/hiện mật khẩu,
/// dòng gợi ý độ dài tối thiểu và link "Quên mật khẩu?".
/// Bấm Tiếp tục: chế độ đăng ký → gọi /register rồi sang màn OTP;
/// chế độ đăng nhập → gọi /login rồi vào thẳng app chính.
final class AuthPasswordViewController: AuthFormViewController {

    private let contact: String          // email hoặc SĐT (gửi lên API)
    private let displayContact: String   // bản hiển thị cho màn OTP
    private let channel: String          // "email" | "sms"
    private let isRegister: Bool
    private let minLength = 8

    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()

    init(contact: String, displayContact: String? = nil, channel: String, isRegister: Bool) {
        self.contact = contact
        self.displayContact = displayContact ?? contact
        self.channel = channel
        self.isRegister = isRegister
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
        bindViewModel()
    }

    // MARK: ViewModel binding
    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.setLoading($0) }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.viewModel.clearError()
                self?.presentAlert(message)
            }
            .store(in: &cancellables)

        // Đăng ký thành công → có userId chờ verify → sang màn nhập OTP.
        viewModel.$pendingUserId
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] userId in self?.goToOTP(userId: userId) }
            .store(in: &cancellables)

        // Đăng nhập thành công → vào thẳng app chính.
        viewModel.$didCompleteAuth
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { _ in AppRoot.switchToMain() }
            .store(in: &cancellables)
    }

    private func goToOTP(userId: String) {
        navigationController?.pushViewController(
            AuthOTPViewController(userId: userId, contact: displayContact, channel: channel),
            animated: true)
    }

    private func presentAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        let password = passwordField.text ?? ""
        if isRegister {
            viewModel.register(email: channel == "email" ? contact : nil,
                               phone:  channel == "sms"   ? contact : nil,
                               password: password)
        } else {
            viewModel.login(emailOrPhone: contact, password: password)
        }
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
