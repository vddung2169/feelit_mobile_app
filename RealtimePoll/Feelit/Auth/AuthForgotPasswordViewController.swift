import UIKit

// MARK: - AuthForgotPasswordViewController
/// Màn quên mật khẩu — nhập email nhận liên kết đặt lại (Figma node 161-17259;
/// trạng thái lỗi 130-7365). Bố cục căn trên. Validate định dạng email; bấm Tiếp tục
/// gọi BE kiểm tra email có tồn tại không (hiện demo): chưa tồn tại → báo lỗi đỏ,
/// đã tồn tại → sang màn đặt lại mật khẩu (130-7519).
final class AuthForgotPasswordViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

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
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = AuthTheme.background
        emailField.delegate = self
        emailField.attributedPlaceholder = AuthUI.placeholder("Nhập Email của bạn")
        emailField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        AuthUI.install(emailField, in: fieldContainer)
        setupLayout()
        refreshState()

        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
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
        AuthUI.setEnabled(continueButton, isValid && !isChecking)
        fieldContainer.layer.borderColor =
            (isValid ? AuthTheme.fieldBorderActive : AuthTheme.fieldBorder).cgColor
    }

    @objc private func editingChanged() {
        errorLabel.isHidden = true
        refreshState()
    }

    // MARK: Continue + kiểm tra email (demo BE)
    private var isChecking = false

    @objc private func continueTapped() {
        guard isValid, !isChecking else { return }
        view.endEditing(true)
        isChecking = true
        refreshState()
        checkEmailRegistered(emailField.text ?? "") { [weak self] exists in
            guard let self else { return }
            self.isChecking = false
            self.refreshState()
            if exists {
                self.navigationController?.pushViewController(
                    AuthResetPasswordViewController(), animated: true)
            } else {
                self.errorLabel.isHidden = false
                self.fieldContainer.layer.borderColor = AuthTheme.bad.cgColor
            }
        }
    }

    /// TODO: thay bằng API thật kiểm tra email đã đăng ký chưa.
    /// Demo: email chứa "@feelit" coi như đã tồn tại.
    private func checkEmailRegistered(_ email: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(email.lowercased().contains("@feelit"))
        }
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
