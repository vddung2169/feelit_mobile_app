import UIKit

// MARK: - AuthWelcomeViewController
/// Màn đầu tiên khi mở app (Figma Feelit_app, node 130-7632).
/// Hero illustration + wordmark + tagline. "Tạo tài khoản mới" / "Đăng nhập"
/// đều dẫn sang màn nhập email.
final class AuthWelcomeViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: UI
    private let illustration: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "WalletIllustration"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let logo = FeelitLogoView(fontSize: 46)

    private let tagline: UILabel = {
        let l = UILabel()
        l.text = "Thể hiện quan điểm & góc\nnhìn đầu tư"
        l.numberOfLines = 2
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 17, weight: .regular)
        l.textColor = AuthTheme.textPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var createButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = AuthTheme.green
        config.baseForegroundColor = AuthTheme.onGreen
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString("Tạo tài khoản mới", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return b
    }()

    private let haveAccountLabel: UILabel = {
        let l = UILabel()
        l.text = "Đã có tài khoản?"
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = AuthTheme.textSecondary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var signInButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("Đăng nhập", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 15, weight: .semibold)]))
        config.baseForegroundColor = AuthTheme.green
        config.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        return b
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = AuthTheme.background
        setupLayout()
    }

    private func setupLayout() {
        let signInRow = UIStackView(arrangedSubviews: [haveAccountLabel, signInButton])
        signInRow.axis = .horizontal
        signInRow.spacing = 6
        signInRow.alignment = .center

        // Khối dưới: logo → tagline → nút tạo tài khoản → dòng đăng nhập.
        let bottom = UIStackView(arrangedSubviews: [logo, tagline, createButton, signInRow])
        bottom.axis = .vertical
        bottom.alignment = .center
        bottom.spacing = 16
        bottom.setCustomSpacing(14, after: logo)
        bottom.setCustomSpacing(28, after: tagline)
        bottom.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(illustration)
        view.addSubview(bottom)

        // Vùng trống phía trên (giữa status bar và khối dưới) để căn giữa illustration.
        let region = UILayoutGuide()
        view.addLayoutGuide(region)

        NSLayoutConstraint.activate([
            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            bottom.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            createButton.heightAnchor.constraint(equalToConstant: 56),
            createButton.leadingAnchor.constraint(equalTo: bottom.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: bottom.trailingAnchor),

            region.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            region.bottomAnchor.constraint(equalTo: bottom.topAnchor),

            illustration.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            illustration.centerYAnchor.constraint(equalTo: region.centerYAnchor),
            illustration.widthAnchor.constraint(equalToConstant: 260),
            illustration.heightAnchor.constraint(equalToConstant: 240),
        ])
    }

    // MARK: Actions
    @objc private func createTapped() {
        navigationController?.pushViewController(AuthEmailInputViewController(), animated: true)
    }

    @objc private func signInTapped() {
        // Cùng màn nhập email (đăng nhập / đăng ký dùng chung bước này).
        navigationController?.pushViewController(AuthEmailInputViewController(), animated: true)
    }
}
