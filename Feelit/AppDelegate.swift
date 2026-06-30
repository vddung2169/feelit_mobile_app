import UIKit
import UserNotifications
import AppsFlyerLib

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestAuthorizationAndRegister()
        configureAppsFlyer()
        return true
    }

    // MARK: - AppsFlyer
    /// CHỈ cấu hình ở đây (không start). `start()` được gọi trong
    /// `SceneDelegate.sceneDidBecomeActive` vì app dùng scene-based lifecycle.
    private func configureAppsFlyer() {
        let af = AppsFlyerLib.shared()
        // Dev Key & Apple App ID đọc từ Info.plist (không hardcode trong code).
        af.appsFlyerDevKey = infoValue("AppsFlyerDevKey")
        af.appleAppID = infoValue("AppsFlyerAppleAppID")
        #if DEBUG
        af.isDebug = true
        #endif
        // Chờ kết quả ATT (tối đa 60s) trước khi gửi dữ liệu attribution — để kịp lấy IDFA.
        af.waitForATTUserAuthorization(timeoutInterval: 60)
        // Gắn sẵn Customer User ID nếu đã đăng nhập (trước khi start chạy ở scene).
        if let userId = TokenStore.shared.currentUserId {
            af.customerUserID = userId
        }
    }

    /// Đọc 1 chuỗi cấu hình từ Info.plist.
    private func infoValue(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - APNs device token
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("📱 APNs device token: \(token)")
        // AppsFlyer: bật đo gỡ cài đặt (uninstall) qua APNs token.
        AppsFlyerLib.shared().registerUninstall(deviceToken)
        APIClient.shared.registerDevice(
            userId: NotificationCoordinator.shared.currentUserId,
            token: token, platform: "ios"
        ) { result in
            if case .failure(let error) = result {
                print("⚠️ registerDevice failed: \(error)")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ Failed to register for remote notifications: \(error)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    /// App foreground: socket đã lo banner in-app rồi → ẩn push hệ thống để khỏi trùng.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([])
    }

    /// User tap vào push (app đóng/nền) → đọc pollId và điều hướng tới poll.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let pollId = (userInfo["pollId"] as? String)
            ?? ((userInfo["data"] as? [String: Any])?["pollId"] as? String) {
            NotificationCoordinator.shared.openPoll(pollId: pollId)
        }
        completionHandler()
    }
}
