import UIKit
import Combine

// MARK: - AuthForgotPasswordViewController
/// Màn quên mật khẩu — nhập email nhận mã đặt lại (Figma node 161-17259;
/// trạng thái lỗi 130-7365). Bố cục căn trên. Validate định dạng email; bấm Tiếp tục
/// gọi /api/auth/forgot-password: lỗi → báo đỏ, thành công → sang màn đặt lại mật khẩu.
final class AuthForgotPasswordViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: UI
    private lazy var backButton = AuthUI.backButton(target: self, action: #selector(backTapped))

    private let subtitle: UILabel = {
        let l = UILabel()
        l.text = "Vui lòng nhập địa chỉ Email của bạn để nhận\nliên kết đặt lại mật khẩu."
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = AuthTheme.textPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.textContentType = .emailAddress
        tf.returnKeyType = .continue
        return tf
    }()

    private let fieldContainer = AuthUI.fieldContainer()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.text = "Email của bạn chưa hợp lệ, vui lòng thử lại."
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = AuthTheme.bad
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var continueButton = AuthUI.continueButton(target: self, action: #selector(continueTapped))

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = AuthTheme.background
        emailField.delegate = self
        emailField.attributedPlaceholder = AuthUI.placeholder(L10n.Auth.emailPlaceholder)
        emailField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        AuthUI.install(emailField, in: fieldContainer)
        setupLayout()
        refreshState()
        bindViewModel()

        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }

    // MARK: ViewModel binding
    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                AuthUI.setLoading(self.continueButton, loading)
                if !loading { self.refreshState() }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                guard let self else { return }
                self.viewModel.clearError()
                self.errorLabel.text = message
                self.errorLabel.isHidden = false
                self.fieldContainer.layer.borderColor = AuthTheme.bad.cgColor
            }
            .store(in: &cancellables)

        // forgot-password thành công → có userId + channel → sang màn đặt lại mật khẩu.
        Publishers.CombineLatest(viewModel.$pendingUserId, viewModel.$otpChannel)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userId, channel in
                guard let self, let userId, let channel else { return }
                self.navigationController?.pushViewController(
                    AuthResetPasswordViewController(userId: userId, channel: channel),
                    animated: true)
            }
            .store(in: &cancellables)
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [subtitle, fieldContainer, errorLabel, continueButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.setCustomSpacing(24, after: subtitle)
        stack.setCustomSpacing(8, after: fieldContainer)
        stack.setCustomSpacing(20, after: errorLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backButton)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            stack.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    // MARK: State
    private var isValid: Bool { AuthUI.isValidEmail(emailField.text) }

    private func refreshState() {
        AuthUI.setEnabled(continueButton, isValid && !viewModel.isLoading)
        fieldContainer.layer.borderColor =
            (isValid ? AuthTheme.fieldBorderActive : AuthTheme.fieldBorder).cgColor
    }

    @objc private func editingChanged() {
        errorLabel.isHidden = true
        refreshState()
    }

    // MARK: Continue — gọi /api/auth/forgot-password
    @objc private func continueTapped() {
        guard isValid, !viewModel.isLoading else { return }
        view.endEditing(true)
        viewModel.forgotPassword(emailOrPhone: emailField.text ?? "")
    }

    // MARK: Actions
    @objc private func dismissKeyboard() { view.endEditing(true) }
    @objc private func backTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension AuthForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isValid { continueTapped() }
        return false
    }
}
