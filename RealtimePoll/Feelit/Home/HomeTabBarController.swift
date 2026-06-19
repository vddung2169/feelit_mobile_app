import UIKit

// MARK: - FloatingTabBar
/// Thanh tab nổi (Figma 219-5411): nền tối bo tròn; mục đang chọn là "pill" trắng
/// (icon + nhãn), mục khác chỉ icon xám.
final class FloatingTabBar: UIView {

    struct Item { let icon: String; let title: String }

    var onSelect: ((Int) -> Void)?
    var selectedIndex: Int = 0 { didSet { restyle() } }

    private let items: [Item]
    private var buttons: [UIButton] = []

    init(items: [Item]) {
        self.items = items
        super.init(frame: .zero)
        backgroundColor = UIColor(hex: 0x1A1A1A)
        layer.cornerRadius = 28
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)
        translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        for (i, item) in items.enumerated() {
            let b = UIButton(configuration: .plain())
            b.tag = i
            b.addAction(UIAction { [weak self] _ in
                self?.selectedIndex = i
                self?.onSelect?(i)
            }, for: .touchUpInside)
            buttons.append(b)
            stack.addArrangedSubview(b)
        }

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        restyle()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func restyle() {
        for (i, b) in buttons.enumerated() {
            let selected = i == selectedIndex
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: items[i].icon,
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
            config.cornerStyle = .capsule
            if selected {
                config.baseBackgroundColor = UIColor(hex: 0xFBFBFB)
                config.baseForegroundColor = UIColor(hex: 0x202020)
                config.background.backgroundColor = UIColor(hex: 0xFBFBFB)
                config.imagePadding = 6
                config.attributedTitle = AttributedString(items[i].title, attributes:
                    AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
                config.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 18)
            } else {
                config.baseForegroundColor = UIColor(hex: 0xEDEDED)
                config.contentInsets = .init(top: 10, leading: 14, bottom: 10, trailing: 14)
            }
            UIView.animate(withDuration: 0.2) { b.configuration = config }
        }
    }
}

// MARK: - HomeTabBarController
/// Container Home mới: hoán đổi 4 màn con qua `FloatingTabBar`.
final class HomeTabBarController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private let childVCs: [UIViewController]
    private let tabBar = FloatingTabBar(items: [
        .init(icon: "rectangle.stack.fill", title: "Poll"),
        .init(icon: "dot.radiowaves.left.and.right", title: "Live"),
        .init(icon: "lightbulb.fill", title: "Ý tưởng"),
        .init(icon: "person.fill", title: "Profile"),
    ])

    private let container = UIView()
    private var current: UIViewController?

    init() {
        self.childVCs = [
            UINavigationController(rootViewController: PollFeedViewController()),
            HomePlaceholderViewController(title: "Live", icon: "dot.radiowaves.left.and.right"),
            HomePlaceholderViewController(title: "Ý tưởng", icon: "lightbulb.fill"),
            UINavigationController(rootViewController: ProfileViewController()),
        ]
        super.init(nibName: nil, bundle: nil)
        (childVCs[0] as? UINavigationController)?.isNavigationBarHidden = true
        (childVCs[3] as? UINavigationController)?.isNavigationBarHidden = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = FeelitColors.background

        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        view.addSubview(tabBar)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tabBar.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            tabBar.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            tabBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            tabBar.heightAnchor.constraint(equalToConstant: 56),
        ])

        tabBar.onSelect = { [weak self] index in self?.select(index) }
        select(0)
    }

    private func select(_ index: Int) {
        let vc = childVCs[index]
        guard vc !== current else { return }
        current?.willMove(toParent: nil)
        current?.view.removeFromSuperview()
        current?.removeFromParent()

        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vc.view)
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        vc.didMove(toParent: self)
        view.bringSubviewToFront(tabBar)
        current = vc
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - HomePlaceholderViewController
/// Màn tạm cho các tab chưa thiết kế (Live, Ý tưởng).
final class HomePlaceholderViewController: UIViewController {
    private let titleText: String
    private let icon: String
    init(title: String, icon: String) {
        self.titleText = title; self.icon = icon
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        let iv = UIImageView(image: UIImage(systemName: icon))
        iv.tintColor = FeelitColors.textTertiary
        iv.contentMode = .scaleAspectFit
        let l = UILabel()
        l.text = "\(titleText)\nsắp ra mắt"
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = FeelitFonts.title
        l.textColor = FeelitColors.textSecondary
        let s = UIStackView(arrangedSubviews: [iv, l])
        s.axis = .vertical; s.spacing = 16; s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(s)
        NSLayoutConstraint.activate([
            s.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            s.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 48),
            iv.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
}
