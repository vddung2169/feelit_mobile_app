import UIKit

// MARK: - AuthSuccessViewController
/// Màn thành công (Figma node 161-15410): badge 3D + "Đăng nhập thành công!" + nút.
/// Nhóm nội dung căn giữa; bấm "Tiếp tục" → vào Home.
final class AuthSuccessViewController: UIViewController {

    private let email: String
    init(email: String) {
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: UI
    private let badge: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "AuthSuccessBadge"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Đăng nhập thành công!"
        l.font = FeelitFonts.rounded(30, weight: .bold)
        l.textColor = AuthTheme.textPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = AuthTheme.green
        config.baseForegroundColor = AuthTheme.onGreen
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString("Tiếp tục", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return b
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = AuthTheme.background
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateBadgeIn()
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [badge, titleLabel, continueButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.setCustomSpacing(32, after: badge)
        stack.setCustomSpacing(24, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            badge.heightAnchor.constraint(equalToConstant: 252),
            continueButton.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    private func animateBadgeIn() {
        badge.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        badge.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.4, options: .curveEaseOut) {
            self.badge.transform = .identity
            self.badge.alpha = 1
        }
    }

    // MARK: Actions
    @objc private func continueTapped() {
        guard let window = view.window else { return }
        let home = FeelitTabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = home
        }
    }
}
