import UIKit

// MARK: - FeelitTabBarController
/// Tab bar nổi (floating): blur dark, bo góc 24px, cách đáy 20px, shadow,
/// chỉ icon (không label). Tint primary, unselected textTertiary.
final class FeelitTabBarController: UITabBarController {

    private let sideInset: CGFloat = 16
    private let bottomInset: CGFloat = 20
    private let barHeight: CGFloat = 64

    // View vẽ shadow phía sau (tabBar clip bo góc nên không tự đổ shadow được).
    private let shadowView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.30
        v.layer.shadowRadius = 20
        v.layer.shadowOffset = CGSize(width: 0, height: 8)
        v.layer.cornerRadius = Radius.largeCard
        v.isUserInteractionEnabled = false
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        setupTabs()
        styleTabBar()
        view.addSubview(shadowView)
        view.bringSubviewToFront(tabBar)
    }

    private func setupTabs() {
        // Feed bọc trong navigation controller để có nút tạo poll + push PollViewController.
        let feedNav = UINavigationController(rootViewController: FeedViewController())
        styleNav(feedNav)

        viewControllers = [
            wrap(feedNav,                   icon: "chart.line.uptrend.xyaxis"),
            wrap(ExploreViewController(),   icon: "magnifyingglass"),
            wrap(PortfolioViewController(), icon: "briefcase"),
            wrap(ProfileViewController(),   icon: "person"),
        ]
    }

    private func styleNav(_ nav: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = FeelitColors.background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: FeelitColors.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: FeelitColors.textPrimary]
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = FeelitColors.primary
    }

    private func wrap(_ vc: UIViewController, icon: String) -> UIViewController {
        vc.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: icon), selectedImage: nil)
        vc.tabBarItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return vc
    }

    private func styleTabBar() {
        if #available(iOS 26.0, *) {
            styleTabBarLiquidGlass()
        } else {
            styleTabBarLegacy()
        }
    }

    @available(iOS 26.0, *)
    private func styleTabBarLiquidGlass() {
        // Để UIKit tự render Liquid Glass mặc định — KHÔNG set backgroundEffect,
        // KHÔNG set backgroundColor, KHÔNG set cornerRadius thủ công.
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()  // để hệ thống tự quyết định glass

        for state in [appearance.stackedLayoutAppearance,
                      appearance.inlineLayoutAppearance,
                      appearance.compactInlineLayoutAppearance] {
            state.normal.iconColor = FeelitColors.textTertiary
            state.selected.iconColor = FeelitColors.primary
            state.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
            state.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        }

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = FeelitColors.primary
        tabBar.unselectedItemTintColor = FeelitColors.textTertiary
        // KHÔNG set cornerRadius/clipsToBounds — để UIKit tự xử lý floating shape
    }

    private func styleTabBarLegacy() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .dark)
        appearance.backgroundColor = FeelitColors.surface.withAlphaComponent(0.85)
        appearance.shadowColor = .clear

        // Ẩn label, set tint icon
        for state in [appearance.stackedLayoutAppearance,
                      appearance.inlineLayoutAppearance,
                      appearance.compactInlineLayoutAppearance] {
            state.normal.iconColor = FeelitColors.textTertiary
            state.selected.iconColor = FeelitColors.primary
            state.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
            state.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        }

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = FeelitColors.primary
        tabBar.unselectedItemTintColor = FeelitColors.textTertiary
        tabBar.layer.cornerRadius = Radius.largeCard
        tabBar.clipsToBounds = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 26.0, *) {
            // Không cần set frame thủ công — UITabBarController trên iOS 26
            // tự floating đúng vị trí. Ẩn shadowView vì không cần nữa.
            shadowView.isHidden = true
            return
        }
        let width = view.bounds.width - sideInset * 2
        let y = view.bounds.height - view.safeAreaInsets.bottom - barHeight - bottomInset + view.safeAreaInsets.bottom * 0.3
        let frame = CGRect(x: sideInset, y: y, width: width, height: barHeight)
        tabBar.frame = frame
        shadowView.frame = frame
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: Radius.largeCard).cgPath
    }

    // MARK: - Haptic khi đổi tab + icon scale
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let index = tabBar.items?.firstIndex(of: item),
              let iconView = tabBar.subviews[safe: index + 1]?.subviews.first(where: { $0 is UIImageView }) else { return }
        iconView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        UIView.animate(withDuration: Motion.duration, delay: 0,
                       usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
            iconView.transform = .identity
        }
    }
}

// Bottom inset gợi ý cho các scroll view con để không bị floating bar che.
enum FeelitLayout {
    static let scrollBottomInset: CGFloat = 110
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
