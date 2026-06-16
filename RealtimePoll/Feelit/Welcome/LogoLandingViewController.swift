import UIKit

// MARK: - LogoLandingViewController
/// Màn logo feelit (Figma node 26-4). Hiện đầu tiên; sau 3s ví logo "bay" — thu nhỏ
/// + di chuyển lên đúng vị trí ví ở màn "Create a new account" (shared-element transition).
final class LogoLandingViewController: UIViewController {

    private let bg = UIColor(hex: 0xFFFFFF)
    private let darkButton = UIColor(hex: 0x0F0F0F)
    private let onDark = UIColor(hex: 0xFAFAFA)
    private let lightButton = UIColor(hex: 0xEEEEEE)
    private let lightText = UIColor(hex: 0x202020)

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    private var didSchedule = false
    private var advanceWork: DispatchWorkItem?

    // MARK: UI — ví và wordmark tách riêng để ví bay độc lập
    private let wallet: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "WalletLogo"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let wordmark: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "FeelitWordmark"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var googleButton = makeDarkButton(
        title: "Continue with Google", image: UIImage(named: "GoogleIcon"))
    private lazy var appleButton = makeDarkButton(
        title: "Continue with Apple",
        image: UIImage(systemName: "apple.logo")?.withTintColor(onDark, renderingMode: .alwaysOriginal))
    private lazy var loginButton = makeLightButton(title: "Log In")
    private lazy var signInButton = makeLightButton(title: "Sign In")

    private lazy var actionStack: UIStackView = {
        let row = UIStackView(arrangedSubviews: [loginButton, signInButton])
        row.axis = .horizontal; row.spacing = 12; row.distribution = .fillEqually
        let s = UIStackView(arrangedSubviews: [googleButton, appleButton, row])
        s.axis = .vertical; s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = bg
        setupLayout()
        [googleButton, appleButton, loginButton, signInButton].forEach {
            $0.addTarget(self, action: #selector(skipToHome), for: .touchUpInside)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didSchedule else { return }
        didSchedule = true
        let work = DispatchWorkItem { [weak self] in self?.advanceToWelcome() }
        advanceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)   // 3s
    }

    private func setupLayout() {
        view.addSubview(wallet)
        view.addSubview(wordmark)
        view.addSubview(actionStack)
        NSLayoutConstraint.activate([
            wallet.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            wallet.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            wallet.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            wallet.heightAnchor.constraint(equalTo: wallet.widthAnchor, multiplier: 288.0 / 370.0),

            wordmark.topAnchor.constraint(equalTo: wallet.bottomAnchor, constant: 8),
            wordmark.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wordmark.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            wordmark.heightAnchor.constraint(equalTo: wordmark.widthAnchor, multiplier: 86.0 / 247.0),

            actionStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            actionStack.topAnchor.constraint(greaterThanOrEqualTo: wordmark.bottomAnchor, constant: 16),

            googleButton.heightAnchor.constraint(equalToConstant: 48),
            appleButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    // MARK: Shared-element transition → Create a new account
    private func advanceToWelcome() {
        guard let window = view.window else { return }
        // 1. Mờ wordmark + buttons trước (ví vẫn giữ nguyên).
        UIView.animate(withDuration: 0.25, animations: {
            self.wordmark.alpha = 0
            self.actionStack.alpha = 0
        }, completion: { [weak self] _ in
            self?.runSharedTransition(window: window)
        })
    }

    private func runSharedTransition(window: UIWindow) {
        // 2. Flyer = ví, đặt đúng vị trí hiện tại rồi ẩn ví gốc (đổi liền mạch).
        let source = wallet.convert(wallet.bounds, to: window)
        let flyer = UIImageView(image: UIImage(named: "WalletLogo"))
        flyer.contentMode = .scaleAspectFit
        flyer.frame = source
        wallet.isHidden = true
        window.addSubview(flyer)

        // 3. Đưa Welcome thành root (nền trắng hiện sau flyer), lấy frame ví đích.
        let welcome = WelcomeViewController()
        welcome.skipAutoEntrance = true
        window.rootViewController = welcome
        welcome.view.layoutIfNeeded()
        welcome.setEntranceStartState()
        window.addSubview(flyer)   // giữ flyer trên cùng sau khi đổi root
        let target = welcome.walletFrame(in: window)

        // 4. Ví bay (thu nhỏ + lên trên) + nội dung Welcome trượt vào.
        welcome.animateContentEntrance()
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: {
            flyer.frame = target
        }, completion: { _ in
            welcome.revealWallet()
            flyer.removeFromSuperview()
        })
    }

    @objc private func skipToHome() {
        advanceWork?.cancel()
        guard let window = view.window else { return }
        let home = FeelitTabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = home
        }
    }

    // MARK: Button factories
    private func makeDarkButton(title: String, image: UIImage?) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = darkButton
        config.baseForegroundColor = onDark
        config.image = image
        config.imagePadding = 10
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .regular)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    private func makeLightButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = lightButton
        config.baseForegroundColor = lightText
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .regular)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }
}
