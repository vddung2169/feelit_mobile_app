import UIKit

// MARK: - NotificationBanner
/// Banner in-app trượt từ trên xuống khi app đang mở và nhận socket `notification`.
/// Tự ẩn sau vài giây; tap → onTap.
final class NotificationBanner: UIView {

    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private var onTap: (() -> Void)?
    private var dismissWork: DispatchWorkItem?

    private init() {
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        backgroundColor = FeelitColors.surfaceElevated
        layer.cornerRadius = Radius.smallCard
        layer.borderWidth = 1
        layer.borderColor = FeelitColors.primary.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 6)
        translatesAutoresizingMaskIntoConstraints = false

        iconLabel.text = "🏁"
        iconLabel.font = .systemFont(ofSize: 26)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = FeelitFonts.title
        titleLabel.textColor = FeelitColors.textPrimary
        titleLabel.numberOfLines = 1

        bodyLabel.font = FeelitFonts.caption
        bodyLabel.textColor = FeelitColors.textSecondary
        bodyLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconLabel)
        addSubview(textStack)
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(dismiss))
        swipe.direction = .up
        addGestureRecognizer(swipe)
    }

    @objc private func tapped() {
        onTap?()
        dismiss()
    }

    /// Hiện banner trên key window.
    static func show(title: String, body: String, onTap: @escaping () -> Void) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first else { return }

        let banner = NotificationBanner()
        banner.titleLabel.text = title
        banner.bodyLabel.text = body
        banner.onTap = onTap
        window.addSubview(banner)

        let topConstraint = banner.bottomAnchor.constraint(equalTo: window.topAnchor)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 12),
            banner.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -12),
            topConstraint,
        ])
        window.layoutIfNeeded()

        // Trượt xuống dưới safe area top.
        topConstraint.isActive = false
        banner.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 8).isActive = true
        UIView.animate(withDuration: Motion.duration, delay: 0,
                       usingSpringWithDamping: Motion.damping, initialSpringVelocity: Motion.velocity) {
            window.layoutIfNeeded()
        }

        let work = DispatchWorkItem { [weak banner] in banner?.dismiss() }
        banner.dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: work)
    }

    @objc private func dismiss() {
        dismissWork?.cancel()
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -40)
        }, completion: { _ in self.removeFromSuperview() })
    }
}

// keyWindow helper cho iOS 15+
private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: { $0.isKeyWindow }) }
}
