import UIKit

// MARK: - HomeTabBarController
/// Tab bar Home theo chuẩn Apple Liquid Glass. Dùng API `UITab`/`UISearchTab`
/// (iOS 18+): tab Search mang role search nên iOS 26 tự render thanh kính nổi
/// và TÁCH nút Search thành "viên" kính tròn riêng bên phải — đúng như docs.
/// iOS 18-25 vẫn chạy như tab bar thường (nền tối mờ hợp theme).
final class HomeTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupTabs()
        styleTabBar()
    }

    private func setupTabs() {
        let pollTab = UITab(title: "Poll",
                            image: UIImage(systemName: "rectangle.stack.fill"),
                            identifier: "tab.poll") { _ in
            let nav = UINavigationController(rootViewController: PollFeedViewController())
            nav.isNavigationBarHidden = true
            return nav
        }

        let liveTab = UITab(title: "Live",
                            image: UIImage(systemName: "dot.radiowaves.left.and.right"),
                            identifier: "tab.live") { _ in
            let nav = UINavigationController(rootViewController: LiveViewController())
            nav.isNavigationBarHidden = true
            return nav
        }

        let ideasTab = UITab(title: "Ý tưởng",
                             image: UIImage(systemName: "lightbulb.fill"),
                             identifier: "tab.ideas") { _ in
            let nav = UINavigationController(rootViewController: IdeasViewController())
            nav.isNavigationBarHidden = true
            return nav
        }

        let profileTab = UITab(title: "Profile",
                               image: UIImage(systemName: "person.fill"),
                               identifier: "tab.profile") { _ in
            let nav = UINavigationController(rootViewController: ProfileViewController())
            nav.isNavigationBarHidden = true
            return nav
        }

        // Role search → iOS 26 tách thành nút kính tròn riêng bên phải.
        let searchTab = UISearchTab { _ in
            let nav = UINavigationController(rootViewController: ExploreViewController())
            nav.isNavigationBarHidden = true
            return nav
        }

        tabs = [pollTab, liveTab, ideasTab, profileTab, searchTab]
    }

    private func styleTabBar() {
        // Icon chọn = chữ chính (đen/sáng theo theme), chưa chọn = xám phụ.
        tabBar.tintColor = Theme.textPrimary
        tabBar.unselectedItemTintColor = Theme.textSecondary

        if #available(iOS 26.0, *) {
            // Để UIKit tự render Liquid Glass theo trait hiện tại.
        } else {
            // iOS 18-25: nền mờ adaptive theo theme.
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
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
        view.backgroundColor = Theme.page
        let iv = UIImageView(image: UIImage(systemName: icon))
        iv.tintColor = Theme.textTertiary
        iv.contentMode = .scaleAspectFit
        let l = UILabel()
        l.text = "\(titleText)\nsắp ra mắt"
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = FeelitFonts.title
        l.textColor = Theme.textSecondary
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
