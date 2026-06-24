import UIKit
import Combine

// MARK: - AuthEmailInputViewController
/// Màn nhập email (Figma node 161-5202 mặc định / 140-8096 khi có bàn phím).
/// Kế thừa `AuthFormViewController` để dùng chung bố cục + hiệu ứng bàn phím.
///
/// Ba vai trò:
///  • Đăng nhập (`isRegister == false`): nhập email → sang màn mật khẩu.
///  • Đăng ký bước đầu (`isRegister == true`): nhập email → gửi OTP → màn xác nhận.
///  • Đăng ký bước cuối (`finalContext != nil`): thu email bổ sung → hoàn tất đăng ký.
final class AuthEmailInputViewController: AuthFormViewController {

    private let isRegister: Bool
    private let finalContext: RegistrationContext?

    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var pendingContext: RegistrationContext?

    init(isRegister: Bool) {
        self.isRegister = isRegister
        self.finalContext = nil
        super.init(nibName: nil, bundle: nil)
    }
    /// Bước cuối của đăng ký bằng SĐT: thu thêm email rồi hoàn tất.
    init(finalRegistration context: RegistrationContext) {
        self.isRegister = true
        self.finalContext = context
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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

    // Bước cuối không cho đổi sang SĐT (email đã là phần bổ sung bắt buộc).
    override var headAccessoryViews: [UIView] { finalContext == nil ? [usePhoneButton] : [] }

    override func makeFieldContent() {
        emailField.attributedPlaceholder = placeholder(L10n.Auth.emailPlaceholder)
        installField(emailField)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindIfNeeded()
    }

    override var isComplete: Bool {
        let text = (emailField.text ?? "").trimmingCharacters(in: .whitespaces)
        return text.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    override func didTapContinue() {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespaces)

        if let ctx = finalContext {
            // Bước cuối: gắn email + hoàn tất đăng ký.
            ctx.email = email
            view.endEditing(true)
            setLoading(true)
            viewModel.completeRegistration(userId: ctx.userId, email: ctx.email,
                                           phone: ctx.phone, password: ctx.password)
        } else if isRegister {
            // Bước đầu đăng ký: gửi OTP tới email.
            let ctx = RegistrationContext(primaryChannel: "email")
            ctx.email = email
            pendingContext = ctx
            view.endEditing(true)
            setLoading(true)
            viewModel.sendRegistrationOTP(email: email, phone: nil)
        } else {
            // Đăng nhập: sang màn mật khẩu.
            navigationController?.pushViewController(
                AuthPasswordViewController(contact: email, channel: "email", isRegister: false),
                animated: true)
        }
    }

    // MARK: Binding (chỉ cần ở flow đăng ký)
    private func bindIfNeeded() {
        guard isRegister || finalContext != nil else { return }

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

        if finalContext == nil {
            // Gửi OTP xong → sang màn xác nhận.
            viewModel.$registrationUserId
                .receive(on: DispatchQueue.main)
                .compactMap { $0 }
                .sink { [weak self] userId in
                    guard let self, let ctx = self.pendingContext else { return }
                    ctx.userId = userId
                    self.navigationController?.pushViewController(
                        AuthOTPViewController(registration: ctx), animated: true)
                }
                .store(in: &cancellables)
        } else {
            // Hoàn tất đăng ký → màn thành công.
            viewModel.$didCompleteAuth
                .receive(on: DispatchQueue.main)
                .filter { $0 }
                .sink { [weak self] _ in
                    guard let self, let ctx = self.finalContext else { return }
                    self.navigationController?.pushViewController(
                        AuthSuccessViewController(email: ctx.email ?? "", title: "Đăng ký thành công!"),
                        animated: true)
                }
                .store(in: &cancellables)
        }
    }

    private func presentAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func usePhoneTapped() {
        navigationController?.pushViewController(
            AuthPhoneViewController(isRegister: isRegister), animated: true)
    }
}
