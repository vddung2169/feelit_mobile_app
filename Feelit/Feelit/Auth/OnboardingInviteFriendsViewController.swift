import UIKit

// MARK: - OnboardingInviteFriendsViewController
/// Bước onboarding cuối — mời bạn bè (Figma node 481-23804 "Invite Friends").
/// Nền xanh full-bleed + minh hoạ; "Tiếp tục" hoặc "Bỏ qua" đều vào Home.
final class OnboardingInviteFriendsViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // Sắc độ xanh cho nền & các vòng trang trí.
    private let bgGreen     = UIColor(hex: 0x4CAF50)
    private let darkGreen   = UIColor(hex: 0x43A047)
    private let lightGreen  = UIColor(hex: 0x66BB6A)

    private let illustration = InviteFriendsIllustrationView()

    private let captionLabel: UILabel = {
        let l = UILabel()
        l.text = "Xem ai trong số những người\nbạn biết đang nói về tài chính"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white
        config.baseForegroundColor = AuthTheme.textPrimary
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString("Tiếp tục", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.heightAnchor.constraint(equalToConstant: 54).isActive = true
        b.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return b
    }()

    private lazy var skipButton: UIButton = {
        let b = AuthUI.skipButton(title: "Bỏ qua", target: self, action: #selector(skipTapped))
        b.configuration?.baseForegroundColor = UIColor.white.withAlphaComponent(0.9)
        return b
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = bgGreen
        illustration.configure(dark: darkGreen, light: lightGreen)
        setupLayout()
    }

    private func setupLayout() {
        illustration.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(illustration)

        let bottom = UIStackView(arrangedSubviews: [captionLabel, continueButton, skipButton])
        bottom.axis = .vertical
        bottom.alignment = .fill
        bottom.spacing = 8
        bottom.setCustomSpacing(28, after: captionLabel)
        bottom.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottom)

        NSLayoutConstraint.activate([
            illustration.topAnchor.constraint(equalTo: view.topAnchor),
            illustration.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            illustration.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            illustration.bottomAnchor.constraint(equalTo: bottom.topAnchor),

            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottom.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    // MARK: Actions
    @objc private func continueTapped() { finish() }
    @objc private func skipTapped() { finish() }

    private func finish() { AppRoot.switchToMain() }
}

// MARK: - InviteFriendsIllustrationView
/// Minh hoạ nền xanh: các vòng tròn trang trí ở 4 góc + biểu đồ đường đi lên có ghim.
private final class InviteFriendsIllustrationView: UIView {

    private let chart = UIImageView(image: UIImage(systemName: "chart.line.uptrend.xyaxis"))
    private let pin = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
    private let dollar = UIImageView(image: UIImage(systemName: "dollarsign.circle"))
    private let circleTopRight = CircleView()
    private let circleBottomLeft = CircleView()
    private let circleBottomRight = CircleView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

        [circleTopRight, circleBottomLeft, circleBottomRight].forEach { addSubview($0) }

        chart.tintColor = .white
        chart.contentMode = .scaleAspectFit
        chart.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chart)

        pin.tintColor = .white
        pin.contentMode = .scaleAspectFit
        pin.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pin)

        dollar.tintColor = UIColor.white.withAlphaComponent(0.9)
        dollar.contentMode = .scaleAspectFit
        dollar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dollar)

        NSLayoutConstraint.activate([
            chart.centerXAnchor.constraint(equalTo: centerXAnchor),
            chart.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),
            chart.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.42),
            chart.heightAnchor.constraint(equalTo: chart.widthAnchor, multiplier: 0.62),

            pin.bottomAnchor.constraint(equalTo: chart.topAnchor, constant: 14),
            pin.trailingAnchor.constraint(equalTo: chart.trailingAnchor, constant: 4),
            pin.widthAnchor.constraint(equalToConstant: 34),
            pin.heightAnchor.constraint(equalToConstant: 34),

            dollar.centerXAnchor.constraint(equalTo: leadingAnchor, constant: 56),
            dollar.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            dollar.widthAnchor.constraint(equalToConstant: 30),
            dollar.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(dark: UIColor, light: UIColor) {
        circleTopRight.color = light
        circleBottomLeft.color = light
        circleBottomRight.color = dark
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        // Vòng tròn trang trí tràn ra ngoài mép (chỉ thấy một phần).
        circleTopRight.frame = CGRect(x: w - 90, y: -70, width: 180, height: 180)
        circleBottomLeft.frame = CGRect(x: -80, y: bounds.height - 90, width: 170, height: 170)
        circleBottomRight.frame = CGRect(x: w - 70, y: bounds.height - 120, width: 150, height: 150)
    }
}

// MARK: - CircleView
/// View tròn đặc (dùng cho các vòng trang trí).
private final class CircleView: UIView {
    var color: UIColor = .clear { didSet { backgroundColor = color } }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
}
