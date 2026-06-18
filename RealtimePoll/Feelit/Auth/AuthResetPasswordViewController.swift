import UIKit

// MARK: - AuthResetPasswordViewController
/// Màn đặt lại mật khẩu (Figma node 130-7519). Bố cục căn trên với 2 ô:
/// "Nhập mật khẩu mới" và "Xác nhận mật khẩu mới", mỗi ô có dòng lỗi riêng.
/// Hợp lệ (≥8 ký tự & khớp nhau) → bật nút Tiếp tục → màn thành công.
final class AuthResetPasswordViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private let minLength = 8

    // MARK: UI
    private lazy var backButton = AuthUI.backButton(target: self, action: #selector(backTapped))

    private let newField = AuthResetPasswordViewController.makeSecureField()
    private let confirmField = AuthResetPasswordViewController.makeSecureField()
    private let newContainer = AuthUI.fieldContainer()
    private let confirmContainer = AuthUI.fieldContainer()

    private let newError = AuthResetPasswordViewController.makeErrorLabel()
    private let confirmError = AuthResetPasswordViewController.makeErrorLabel()

    private lazy var continueButton = AuthUI.continueButton(target: self, action: #selector(continueTapped))

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = AuthTheme.background

        newField.attributedPlaceholder = AuthUI.placeholder("Nhập mật khẩu mới")
        confirmField.attributedPlaceholder = AuthUI.placeholder("Nhập lại mật khẩu mới")
        AuthUI.install(newField, in: newContainer)
        AuthUI.install(confirmField, in: confirmContainer)
        for f in [newField, confirmField] {
            f.delegate = self
            f.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        }

        setupLayout()
        refreshState()
        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }

    private func setupLayout() {
        let group1 = makeGroup(label: "Nhập mật khẩu mới", container: newContainer, error: newError)
        let group2 = makeGroup(label: "Xác nhận mật khẩu mới", container: confirmContainer, error: confirmError)

        let stack = UIStackView(arrangedSubviews: [group1, group2, continueButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 20
        stack.setCustomSpacing(28, after: group2)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backButton)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            stack.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func makeGroup(label: String, container: UIView, error: UILabel) -> UIStackView {
        let s = UIStackView(arrangedSubviews: [AuthUI.fieldLabel(label), container, error])
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 8
        s.setCustomSpacing(6, after: container)
        return s
    }

    // MARK: Validation
    private var newText: String { newField.text ?? "" }
    private var confirmText: String { confirmField.text ?? "" }

    private var newValid: Bool { newText.count >= minLength }
    private var confirmValid: Bool { !confirmText.isEmpty && confirmText == newText }

    @objc private func editingChanged() { refreshState() }

    private func refreshState() {
        // Ô mật khẩu mới
        let newHasError = !newText.isEmpty && !newValid
        newError.text = "Mật khẩu phải có ít nhất \(minLength) ký tự"
        newError.isHidden = !newHasError
        border(newContainer, valid: newValid, error: newHasError)

        // Ô xác nhận
        let confirmHasError = !confirmText.isEmpty && confirmText != newText
        confirmError.text = "Mật khẩu xác nhận không khớp"
        confirmError.isHidden = !confirmHasError
        border(confirmContainer, valid: confirmValid, error: confirmHasError)

        AuthUI.setEnabled(continueButton, newValid && confirmValid)
    }

    private func border(_ container: UIView, valid: Bool, error: Bool) {
        let color: UIColor = error ? AuthTheme.bad : (valid ? AuthTheme.fieldBorderActive : AuthTheme.fieldBorder)
        container.layer.borderColor = color.cgColor
    }

    // MARK: Actions
    @objc private func continueTapped() {
        guard newValid && confirmValid else { return }
        view.endEditing(true)
        // TODO: gọi BE đặt lại mật khẩu với token đặt lại.
        navigationController?.pushViewController(
            AuthSuccessViewController(email: ""), animated: true)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }
    @objc private func backTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    // MARK: Factories
    private static func makeSecureField() -> UITextField {
        let tf = UITextField()
        tf.isSecureTextEntry = true
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.textContentType = .newPassword
        tf.returnKeyType = .next
        return tf
    }

    private static func makeErrorLabel() -> UILabel {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = AuthTheme.bad
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
}

// MARK: - UITextFieldDelegate
extension AuthResetPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === newField { confirmField.becomeFirstResponder() }
        else { continueTapped() }
        return false
    }
}
