import UIKit

// MARK: - WelcomeViewController
/// Màn Welcome — dựng theo Figma (Feelit_app, node 290-13909):
/// hero là 2 thẻ biểu đồ chồng nhau, wordmark "feelit", tagline tiếng Việt,
/// nút chính "Tạo tài khoản mới" + dòng "Đã có tài khoản? Đăng nhập".
final class WelcomeViewController: UIViewController {

    // Màu lấy trực tiếp từ Figma
    private let bg = UIColor(hex: 0xFBFBFB)
    private let heading = UIColor(hex: 0x202020)
    private let green = UIColor(hex: 0x4CAF50)
    private let onGreen = UIColor(hex: 0xFBFBFB)
    private let muted = UIColor(hex: 0x818181)

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    /// Bỏ qua entrance tự động khi được dẫn vào bằng shared-element transition từ màn logo.
    var skipAutoEntrance = false

    // MARK: UI
    /// Hero: 2 thẻ biểu đồ chồng nhau (vector SVG từ Figma).
    private let illustration: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "WelcomeIllustration"))
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

    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.text = "Thể hiện quan điểm & góc nhìn đầu tư"
        l.numberOfLines = 2
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 22, weight: .medium)   // Figma: Be Vietnam Pro 500/22
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var primaryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = green
        config.baseForegroundColor = onGreen
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString("Tạo tài khoản mới", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(goUsername), for: .touchUpInside)
        return b
    }()

    private let alreadyLabel: UILabel = {
        let l = UILabel()
        l.text = "Đã có tài khoản?"
        l.font = .systemFont(ofSize: 14, weight: .regular)   // Figma: Be Vietnam Pro 400/14
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var signInButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = green
        config.attributedTitle = AttributedString("Đăng nhập", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .medium)]))
        config.contentInsets = .init(top: 6, leading: 4, bottom: 6, trailing: 4)
        let b = UIButton(configuration: config)
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
        taglineLabel.textColor = heading
        alreadyLabel.textColor = muted
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAnimateIn, !skipAutoEntrance else { return }
        didAnimateIn = true
        animateEntrance()
    }

    private func setupLayout() {
        // wordmark + tagline (căn giữa)
        let textGroup = UIStackView(arrangedSubviews: [wordmark, taglineLabel])
        textGroup.axis = .vertical
        textGroup.spacing = 14
        textGroup.alignment = .center
        textGroup.translatesAutoresizingMaskIntoConstraints = false

        // dòng "Đã có tài khoản? Đăng nhập"
        let signInRow = UIStackView(arrangedSubviews: [alreadyLabel, signInButton])
        signInRow.axis = .horizontal
        signInRow.spacing = 4
        signInRow.alignment = .center
        signInRow.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(illustration)
        view.addSubview(textGroup)
        view.addSubview(primaryButton)
        view.addSubview(signInRow)

        NSLayoutConstraint.activate([
            // Hero biểu đồ — bám đỉnh, giữ tỉ lệ 366:327 từ Figma.
            illustration.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            illustration.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            illustration.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            illustration.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            illustration.heightAnchor.constraint(equalTo: illustration.widthAnchor, multiplier: 330.0 / 367.0),

            // wordmark theo tỉ lệ Figma 156x55.
            wordmark.heightAnchor.constraint(equalToConstant: 55),
            wordmark.widthAnchor.constraint(equalToConstant: 156),
            taglineLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300),

            // Nhóm chữ nằm phía trên nút, căn giữa khoảng trống dưới.
            textGroup.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            textGroup.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            textGroup.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textGroup.bottomAnchor.constraint(equalTo: primaryButton.topAnchor, constant: -28),

            // Nút chính — full width (margin 16), pill.
            primaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            primaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            primaryButton.heightAnchor.constraint(equalToConstant: 54),
            primaryButton.bottomAnchor.constraint(equalTo: signInRow.topAnchor, constant: -12),

            signInRow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInRow.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Shared-element transition hooks (gọi từ LogoLandingViewController)
    private var transitionMovers: [UIView] { [wordmark, taglineLabel, primaryButton, alreadyLabel, signInButton] }

    /// Frame của hero trong hệ toạ độ `target` — để màn logo biết bay tới đâu.
    func walletFrame(in target: UIView) -> CGRect {
        illustration.convert(illustration.bounds, to: target)
    }

    /// Trạng thái bắt đầu: ẩn hero + nội dung trượt xuống mờ.
    func setEntranceStartState() {
        illustration.alpha = 0
        transitionMovers.forEach { $0.alpha = 0; $0.transform = CGAffineTransform(translationX: 0, y: 22) }
    }

    /// Nội dung trượt lên hiện dần (chạy song song lúc hero bay vào).
    func animateContentEntrance() {
        UIView.animate(withDuration: 0.5, delay: 0.05, options: .curveEaseOut) {
            self.transitionMovers.forEach { $0.alpha = 1; $0.transform = .identity }
        }
    }

    /// Hiện hero thật (sau khi flyer đáp đúng vị trí thì gỡ flyer).
    func revealWallet() {
        UIView.animate(withDuration: 0.2) { self.illustration.alpha = 1 }
    }

    /// Hero "pop" vào + nội dung trượt lên mờ dần — entrance tự động khi mở thẳng màn này.
    private func animateEntrance() {
        let movers = [wordmark, taglineLabel, primaryButton]
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
