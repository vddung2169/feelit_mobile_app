import UIKit

extension Notification.Name {
    /// Báo cho UI (badge chuông) biết unreadCount đổi.
    static let feelitUnreadDidChange = Notification.Name("feelitUnreadDidChange")
}

// MARK: - NotificationCoordinator
/// Điều phối thông báo cấp app: socket realtime, badge unread, banner in-app, điều hướng tới poll.
/// `userId` = voterId = DeviceIdManager.deviceId (phải trùng để nhận đúng thông báo).
final class NotificationCoordinator: NotificationSocketDelegate {

    static let shared = NotificationCoordinator()
    private init() {}

    var currentUserId: String { DeviceIdManager.shared.deviceId }

    private(set) var unreadCount = 0 {
        didSet { NotificationCenter.default.post(name: .feelitUnreadDidChange, object: nil) }
    }

    // MARK: - Lifecycle
    /// Gọi 1 lần khi app khởi động: kết nối socket + join room cá nhân.
    func start() {
        NotificationSocketManager.shared.delegate = self
        NotificationSocketManager.shared.connect(userId: currentUserId)
        refreshUnread()
    }

    /// Gọi mỗi khi app vào foreground: đảm bảo socket sống + đồng bộ unread.
    func appDidBecomeActive() {
        NotificationSocketManager.shared.connect(userId: currentUserId)
        refreshUnread()
    }

    // MARK: - Unread badge
    func refreshUnread() {
        APIClient.shared.getNotifications(userId: currentUserId, unreadOnly: true) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let res) = result {
                    self?.unreadCount = res.unreadCount
                }
            }
        }
    }

    func setUnread(_ count: Int) {
        unreadCount = max(0, count)
    }

    // MARK: - Socket delegate
    func didReceiveAppNotification(_ notification: AppNotification) {
        unreadCount += 1
        NotificationBanner.show(title: notification.title, body: notification.body) { [weak self] in
            if let pollId = notification.resolvedPollId {
                self?.openPoll(pollId: pollId)
            }
        }
    }

    // MARK: - Navigation
    /// Điều hướng tới màn hình poll (dùng khi tap banner / push / item trong list).
    func openPoll(pollId: String) {
        guard let tabBar = keyWindow?.rootViewController as? UITabBarController else { return }
        tabBar.selectedIndex = 0
        guard let nav = tabBar.selectedViewController as? UINavigationController else { return }

        APIClient.shared.getPoll(pollId: pollId) { result in
            DispatchQueue.main.async {
                guard case .success(let poll) = result else { return }
                let vc = PollViewController(poll: poll)
                vc.hidesBottomBarWhenPushed = true
                nav.popToRootViewController(animated: false)
                nav.pushViewController(vc, animated: true)
            }
        }
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
            .first
    }
}
