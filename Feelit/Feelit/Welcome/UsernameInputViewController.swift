import UIKit

// MARK: - UsernameInputViewController
/// Màn nhập tên cho user mới — dựng theo Figma (node 59-53333).
/// Validate realtime: 3–16 ký tự. "Tiếp tục" → lưu tên & vào Home.
final class UsernameInputViewController: UIViewController {

    private let bg = UIColor(hex: 0x111111)
    private let subColor = UIColor(hex: 0xB3B3B3)
    private let inputColor = UIColor(hex: 0xEDEDED)
    private let errorColor = UIColor(hex: 0xF44336)
    private let green = UIColor(hex: 0x4CAF50)
    private let onGreen = UIColor(hex: 0x111111)

    private let viewModel = UsernameInputViewModel()

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: UI
    private let subtitle: UILabel = {
        let l = UILabel()
        l.text = "We should call you..."
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let placeholder: UILabel = {
        let l = UILabel()
        l.text = "username"
        l.font = .systemFont(ofSize: 40, weight: .medium)
        l.textColor = UIColor(hex: 0x4D4D4D)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let input: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 40, weight: .medium)
        tv.textAlignment = .center
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.autocapitalizationType = .none
        tv.autocorrectionType = .no
        tv.spellCheckingType = .no
        tv.returnKeyType = .continue
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .light)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = green
        config.baseForegroundColor = onGreen
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString("Tiếp tục", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .medium)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return b
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = bg
        subtitle.textColor = subColor
        input.textColor = inputColor
        input.tintColor = green
        errorLabel.textColor = errorColor
        input.delegate = self
        setupLayout()
        validate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.becomeFirstResponder()
    }

    private func setupLayout() {
        // Nhóm: [subtitle + input + error] — gap 128 — [Tiếp tục], căn giữa theo chiều dọc.
        let heading = UIStackView(arrangedSubviews: [subtitle, input, errorLabel])
        heading.axis = .vertical
        heading.alignment = .fill
        heading.spacing = 8

        let content = UIStackView(arrangedSubviews: [heading, continueButton])
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 0
        content.setCustomSpacing(128, after: heading)
        content.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(content)
        view.addSubview(placeholder)

        // Vùng khả dụng giữa status bar và bàn phím → căn giữa `content` trong vùng này.
        let region = UILayoutGuide()
        view.addLayoutGuide(region)

        NSLayoutConstraint.activate([
            region.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            region.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            content.centerYAnchor.constraint(equalTo: region.centerYAnchor),
            content.topAnchor.constraint(greaterThanOrEqualTo: region.topAnchor, constant: 8),

            continueButton.heightAnchor.constraint(equalToConstant: 44),

            placeholder.centerXAnchor.constraint(equalTo: input.centerXAnchor),
            placeholder.centerYAnchor.constraint(equalTo: input.centerYAnchor),
        ])
    }

    // MARK: Validation
    private func validate() {
        placeholder.isHidden = !input.text.isEmpty
        let message = viewModel.errorMessage(for: input.text)
        errorLabel.text = message
        errorLabel.isHidden = (message == nil)
        let valid = viewModel.isValid(input.text)
        continueButton.isEnabled = valid
        continueButton.alpha = valid ? 1.0 : 0.45
    }

    // MARK: Actions
    @objc private func continueTapped() {
        guard viewModel.isValid(input.text) else { return }
        viewModel.save(input.text)
        guard let window = view.window else { return }
        let home = FeelitTabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = home
        }
    }
}

// MARK: - UITextViewDelegate
extension UsernameInputViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) { validate() }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text == "\n" {            // Return → submit nếu hợp lệ
            continueTapped()
            return false
        }
        return true
    }
}
