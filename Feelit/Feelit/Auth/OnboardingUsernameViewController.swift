import UIKit

// MARK: - OnboardingUsernameViewController
/// Bước onboarding 1 — chọn tên người dùng (Figma node 59-56177;
/// lỗi 59-55606 / 59-55457). Bàn phím luôn hiện; nội dung căn giữa, nút nổi trên bàn phím.
/// Hợp lệ: 3–16 ký tự, chỉ gồm chữ cái / số / "." / "_".
final class OnboardingUsernameViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    private let viewModel = OnboardingUsernameViewModel()

    // MARK: UI
    private let captionLabel: UILabel = {
        let l = UILabel()
        l.text = "Tên của bạn"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = AuthTheme.textSecondary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let input: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 22, weight: .medium)
        tf.textColor = AuthTheme.textPrimary
        tf.tintColor = AuthTheme.green
        tf.textAlignment = .center
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.returnKeyType = .continue
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .light)
        l.textColor = AuthTheme.bad
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let helperLabel: UILabel = {
        let l = UILabel()
        l.text = "Bạn có thể đổi lại tên này bất kỳ lúc nào"
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = AuthTheme.textTertiary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var continueButton = AuthUI.continueButton(target: self, action: #selector(continueTapped))

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = AuthTheme.background
        input.delegate = self
        input.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        setupLayout()
        validate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.becomeFirstResponder()
    }

    private func setupLayout() {
        let head = UIStackView(arrangedSubviews: [captionLabel, input, errorLabel])
        head.axis = .vertical
        head.alignment = .fill
        head.spacing = 12
        head.setCustomSpacing(16, after: input)
        head.translatesAutoresizingMaskIntoConstraints = false

        let bottom = UIStackView(arrangedSubviews: [helperLabel, continueButton])
        bottom.axis = .vertical
        bottom.alignment = .fill
        bottom.spacing = 14
        bottom.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(head)
        view.addSubview(bottom)

        // Vùng giữa status bar và bàn phím → căn giữa nhóm tiêu đề.
        let region = UILayoutGuide()
        view.addLayoutGuide(region)

        NSLayoutConstraint.activate([
            region.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            region.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            head.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            head.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            head.centerYAnchor.constraint(equalTo: region.centerYAnchor, constant: -20),

            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottom.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16),
            bottom.topAnchor.constraint(greaterThanOrEqualTo: head.bottomAnchor, constant: 12),
        ])
    }

    // MARK: Validation
    private var isValid: Bool { viewModel.isValid(input.text ?? "") }

    @objc private func editingChanged() { validate() }

    private func validate() {
        let message = viewModel.errorMessage(for: input.text ?? "")
        errorLabel.text = message
        errorLabel.isHidden = (message == nil)
        AuthUI.setEnabled(continueButton, isValid)
    }

    // MARK: Actions
    @objc private func continueTapped() {
        guard isValid else { return }
        viewModel.save(input.text ?? "")
        navigationController?.pushViewController(OnboardingInterestViewController(), animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension OnboardingUsernameViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isValid { continueTapped() }
        return false
    }
}
