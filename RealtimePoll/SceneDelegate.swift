import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // FEELIT — flow Auth: màn Welcome hiện đầu tiên → nhập email.
        let root = AuthNavigationController(rootViewController: AuthWelcomeViewController())

        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .dark
        window?.rootViewController = root
        window?.makeKeyAndVisible()

        // Bật thông báo cấp app: socket realtime + đồng bộ unread.
        NotificationCoordinator.shared.start()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Mở lại app / vào foreground → đảm bảo socket sống + lấy thông báo bị bỏ lỡ.
        NotificationCoordinator.shared.appDidBecomeActive()
    }
}
