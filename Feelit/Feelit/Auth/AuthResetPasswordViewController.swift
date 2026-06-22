import UIKit
import Combine

// MARK: - AuthResetPasswordViewController
/// Màn đặt lại mật khẩu (Figma node 130-7519). Bố cục căn trên với ô mã xác nhận (OTP),
/// "Nhập mật khẩu mới" và "Xác nhận mật khẩu mới", mỗi ô có dòng lỗi riêng.
/// Hợp lệ (mã 6 số + mật khẩu ≥8 ký tự & khớp nhau) → gọi /api/auth/reset-password.
final class AuthResetPasswordViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    private let minLength = 8
    private let codeLength = 6

    private let userId: String
    private let channel: String
    private let viewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()

    /// `userId` lấy từ /api/auth/forgot-password ở bước trước.
    init(userId: String, channel: String) {
        self.userId = userId
        self.channel = channel
        self.viewModel = AuthViewModel(pendingUserId: userId, otpChannel: channel)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: UI
    private lazy var backButton = AuthUI.backButton(target: self, action: #selector(backTapped))

    private let codeField: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        tf.textContentType = .oneTimeCode
        tf.returnKeyType = .next
        return tf
    }()
    private let codeContainer = AuthUI.fieldContainer()
    private let codeError = AuthResetPasswordViewController.makeErrorLabel()

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
        overrideUserInterfaceStyle = .light
        view.backgroundColor = AuthTheme.background

        codeField.attributedPlaceholder = AuthUI.placeholder("Nhập mã 6 số")
        newField.attributedPlaceholder = AuthUI.placeholder("Nhập mật khẩu mới")
        confirmField.attributedPlaceholder = AuthUI.placeholder("Nhập lại mật khẩu mới")
        AuthUI.install(codeField, in: codeContainer)
        AuthUI.install(newField, in: newContainer)
        AuthUI.install(confirmField, in: confirmContainer)
        codeField.delegate = self
        codeField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        for f in [newField, confirmField] {
            f.delegate = self
            f.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        }

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
                self.codeError.text = message
                self.codeError.isHidden = false
                self.codeContainer.layer.borderColor = AuthTheme.bad.cgColor
            }
            .store(in: &cancellables)

        // Đặt lại mật khẩu thành công → báo & quay về màn đăng nhập.
        viewModel.$didCompleteAuth
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in self?.showSuccessAndExit() }
            .store(in: &cancellables)
    }

    private func showSuccessAndExit() {
        let alert = UIAlertController(
            title: "Thành công",
            message: "Mật khẩu của bạn đã được đặt lại. Vui lòng đăng nhập lại.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func setupLayout() {
        let group0 = makeGroup(label: "Mã xác nhận", container: codeContainer, error: codeError)
        let group1 = makeGroup(label: "Nhập mật khẩu mới", container: newContainer, error: newError)
        let group2 = makeGroup(label: "Xác nhận mật khẩu mới", container: confirmContainer, error: confirmError)

        let stack = UIStackView(arrangedSubviews: [group0, group1, group2, continueButton])
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
    private var codeText: String { codeField.text ?? "" }
    private var newText: String { newField.text ?? "" }
    private var confirmText: String { confirmField.text ?? "" }

    private var codeValid: Bool { codeText.count == codeLength && codeText.allSatisfy(\.isNumber) }
    private var newValid: Bool { newText.count >= minLength }
    private var confirmValid: Bool { !confirmText.isEmpty && confirmText == newText }

    @objc private func editingChanged() {
        codeError.isHidden = true
        refreshState()
    }

    private func refreshState() {
        // Ô mã xác nhận
        border(codeContainer, valid: codeValid, error: false)

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

        AuthUI.setEnabled(continueButton, codeValid && newValid && confirmValid && !viewModel.isLoading)
    }

    private func border(_ container: UIView, valid: Bool, error: Bool) {
        let color: UIColor = error ? AuthTheme.bad : (valid ? AuthTheme.fieldBorderActive : AuthTheme.fieldBorder)
        container.layer.borderColor = color.cgColor
    }

    // MARK: Actions
    @objc private func continueTapped() {
        guard codeValid && newValid && confirmValid, !viewModel.isLoading else { return }
        view.endEditing(true)
        viewModel.resetPassword(code: codeText, newPassword: newText)
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
        if textField === codeField { newField.becomeFirstResponder() }
        else if textField === newField { confirmField.becomeFirstResponder() }
        else { continueTapped() }
        return false
    }
}
