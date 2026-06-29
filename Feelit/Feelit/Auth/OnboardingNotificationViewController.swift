import UIKit

// MARK: - OnboardingNotificationViewController
/// Bước onboarding 2 — bật thông báo (Figma node 481-23779 "Notification").
/// "Bật thông báo" → xin quyền push rồi sang chọn chủ đề; "Bỏ qua" → sang luôn.
final class OnboardingNotificationViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    // MARK: UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Stay in the loop"
        l.font = FeelitFonts.rounded(30, weight: .bold)
        l.textColor = AuthTheme.textPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Nhận thông báo khi có các cuộc thảo luận tài\nchính, và nhiều hơn nữa"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = AuthTheme.textSecondary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// Ảnh mô phỏng một banner thông báo (placeholder bo tròn, theo Figma).
    private let preview: UIView = {
        let v = UIView()
        v.backgroundColor = AuthTheme.inputField
        v.layer.cornerRadius = 18
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return v
    }()

    private lazy var enableButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = AuthTheme.green
        config.baseForegroundColor = AuthTheme.onGreen
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString("Bật thông báo", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 54).isActive = true
        b.addTarget(self, action: #selector(enableTapped), for: .touchUpInside)
        return b
    }()

    private lazy var skipButton = AuthUI.skipButton(title: "Bỏ qua", target: self, action: #selector(skipTapped))

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = AuthTheme.background
        setupLayout()
    }

    private func setupLayout() {
        let top = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, preview])
        top.axis = .vertical
        top.alignment = .fill
        top.spacing = 32
        top.setCustomSpacing(12, after: titleLabel)
        top.translatesAutoresizingMaskIntoConstraints = false

        let bottom = UIStackView(arrangedSubviews: [enableButton, skipButton])
        bottom.axis = .vertical
        bottom.alignment = .fill
        bottom.spacing = 8
        bottom.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(top)
        view.addSubview(bottom)
        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            top.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            top.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottom.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    // MARK: Actions
    @objc private func enableTapped() {
        // Xin quyền push; dù cấp hay từ chối vẫn tiếp tục onboarding.
        NotificationManager.shared.requestAuthorizationAndRegister()
        goNext()
    }

    @objc private func skipTapped() { goNext() }

    private func goNext() {
        navigationController?.pushViewController(OnboardingInterestViewController(), animated: true)
    }
}
