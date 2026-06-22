import UIKit

// MARK: - WelcomeViewController
/// Màn "Create a new account" — dựng theo Figma (Feelit_app, node 26-2770).
/// Hiện đầu tiên khi mở app. Bấm "Sign in here" (hoặc nút Continue) → vào Home.
final class WelcomeViewController: UIViewController {

    // Màu lấy trực tiếp từ Figma
    private let bg = UIColor(hex: 0xFBFBFB)
    private let heading = UIColor(hex: 0x202020)
    private let buttonGreen = UIColor(hex: 0x003512)
    private let onGreen = UIColor(hex: 0xFBFBFB)
    private let muted = UIColor(hex: 0x818181)
    private let borderGray = UIColor(hex: 0xCCCCCC)

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    // MARK: UI
    /// Dùng chung 1 ảnh ví với màn logo để shared-element transition liền mạch.
    private let illustration: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "WalletLogo"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// Bỏ qua entrance tự động khi được dẫn vào bằng shared-element transition từ màn logo.
    var skipAutoEntrance = false

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Create a\nnew account"
        l.numberOfLines = 2
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 40, weight: .heavy)   // Figma: Be Vietnam Pro 700, 48
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var googleButton = makePrimaryButton(
        title: "Continue with Google", image: UIImage(named: "GoogleIcon"))
    private lazy var appleButton = makePrimaryButton(
        title: "Continue with Apple",
        image: UIImage(systemName: "apple.logo")?.withTintColor(onGreen, renderingMode: .alwaysOriginal))

    private let alreadyLabel: UILabel = {
        let l = UILabel()
        l.text = "Already have an account?"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var signInButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Sign in here"
        config.attributedTitle = AttributedString("Sign in here", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .regular)]))
        config.baseForegroundColor = muted
        config.contentInsets = .init(top: 8, leading: 20, bottom: 8, trailing: 20)
        let b = UIButton(configuration: config)
        b.layer.cornerRadius = 20            // pill (height 40)
        b.layer.borderWidth = 2
        b.layer.borderColor = borderGray.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(goHome), for: .touchUpInside)
        return b
    }()

    private var didAnimateIn = false

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = bg
        titleLabel.textColor = heading
        alreadyLabel.textColor = muted

        // Tạo tài khoản mới → nhập tên; "Sign in here" (user cũ) → vào Home.
        googleButton.addTarget(self, action: #selector(goUsername), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(goUsername), for: .touchUpInside)

        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAnimateIn, !skipAutoEntrance else { return }
        didAnimateIn = true
        animateEntrance()
    }

    // MARK: - Shared-element transition hooks (gọi từ LogoLandingViewController)
    private var transitionMovers: [UIView] { [titleLabel, googleButton, appleButton, alreadyLabel, signInButton] }

    /// Frame của ví trong hệ toạ độ `target` — để màn logo biết bay tới đâu.
    func walletFrame(in target: UIView) -> CGRect {
        illustration.convert(illustration.bounds, to: target)
    }

    /// Trạng thái bắt đầu: ẩn ví (flyer thay thế) + nội dung trượt xuống mờ.
    func setEntranceStartState() {
        illustration.alpha = 0
        transitionMovers.forEach { $0.alpha = 0; $0.transform = CGAffineTransform(translationX: 0, y: 22) }
    }

    /// Nội dung trượt lên hiện dần (chạy song song lúc ví bay vào).
    func animateContentEntrance() {
        UIView.animate(withDuration: 0.5, delay: 0.05, options: .curveEaseOut) {
            self.transitionMovers.forEach { $0.alpha = 1; $0.transform = .identity }
        }
    }

    /// Hiện ví thật (sau khi flyer đáp đúng vị trí thì gỡ flyer).
    func revealWallet() {
        UIView.animate(withDuration: 0.2) { self.illustration.alpha = 1 }
    }

    /// Wallet "pop" vào + tiêu đề/nút trượt lên mờ dần — nối tiếp transition từ logo.
    private func animateEntrance() {
        let movers = [titleLabel, googleButton, appleButton]
        illustration.alpha = 0
        illustration.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        movers.forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: 0, y: 20)
        }
        UIView.animate(withDuration: 0.5, delay: 0.05, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.6, options: .curveEaseOut) {
            self.illustration.alpha = 1
            self.illustration.transform = .identity
        }
        UIView.animate(withDuration: 0.45, delay: 0.15, options: .curveEaseOut) {
            movers.forEach { $0.alpha = 1; $0.transform = .identity }
        }
    }

    private func setupLayout() {
        let buttons = UIStackView(arrangedSubviews: [googleButton, appleButton])
        buttons.axis = .vertical
        buttons.spacing = 16
        buttons.translatesAutoresizingMaskIntoConstraints = false

        let middle = UIStackView(arrangedSubviews: [titleLabel, buttons])
        middle.axis = .vertical
        middle.spacing = 28
        middle.translatesAutoresizingMaskIntoConstraints = false

        let bottom = UIStackView(arrangedSubviews: [alreadyLabel, signInButton])
        bottom.axis = .vertical
        bottom.spacing = 10
        bottom.alignment = .center
        bottom.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(illustration)
        view.addSubview(middle)
        view.addSubview(bottom)

        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            illustration.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            illustration.widthAnchor.constraint(equalToConstant: 174),
            illustration.heightAnchor.constraint(equalToConstant: 135),

            middle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            middle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            middle.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),

            googleButton.heightAnchor.constraint(equalToConstant: 48),
            appleButton.heightAnchor.constraint(equalToConstant: 48),

            bottom.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottom.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            signInButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    // MARK: Factory
    private func makePrimaryButton(title: String, image: UIImage?) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = buttonGreen
        config.baseForegroundColor = onGreen
        config.image = image
        config.imagePadding = 10
        config.imagePlacement = .leading
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .regular)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    // MARK: Actions
    @objc private func goUsername() {
        guard let window = view.window else { return }
        let vc = UsernameInputViewController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = vc
        }
    }

    @objc private func goHome() {
        guard let window = view.window else { return }
        let home = FeelitTabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = home
        }
    }
}
