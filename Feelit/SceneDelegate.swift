import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Đã đăng nhập (có token trong Keychain) → vào thẳng app chính;
        // chưa thì bắt đầu flow Auth từ màn Welcome.
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = AppRoot.makeRoot()
        window?.makeKeyAndVisible()
        // Áp dụng theme người dùng đã lưu (Sáng/Tối/Tự động).
        ThemeManager.shared.apply()

        // Refresh token cũng hết hạn → buộc đăng nhập lại.
        NotificationCenter.default.addObserver(
            self, selector: #selector(sessionExpired),
            name: .authSessionExpired, object: nil)

        // Bật thông báo cấp app: socket realtime + đồng bộ unread.
        NotificationCoordinator.shared.start()
    }

    @objc private func sessionExpired() {
        DispatchQueue.main.async { AppRoot.switchToAuth() }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Mở lại app / vào foreground → đảm bảo socket sống + lấy thông báo bị bỏ lỡ.
        NotificationCoordinator.shared.appDidBecomeActive()
    }
}

// MARK: - AppRoot
/// Quyết định & chuyển đổi root view controller giữa flow Auth và app chính.
enum AppRoot {

    /// Root ban đầu: đã đăng nhập → app chính; chưa → flow Auth.
    static func makeRoot() -> UIViewController {
        TokenStore.shared.isLoggedIn
            ? HomeTabBarController()
            : AuthNavigationController(rootViewController: AuthWelcomeViewController())
    }

    /// Đăng nhập / xác minh OTP thành công → vào app chính.
    static func switchToMain() { setRoot(HomeTabBarController()) }

    /// Hết phiên / đăng xuất → quay lại flow Auth.
    static func switchToAuth() {
        setRoot(AuthNavigationController(rootViewController: AuthWelcomeViewController()))
    }

    private static func setRoot(_ vc: UIViewController) {
        guard let window = keyWindow else { return }
        UIView.transition(with: window, duration: 0.3,
                          options: .transitionCrossDissolve) {
            window.rootViewController = vc
        }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
