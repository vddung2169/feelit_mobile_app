import UIKit
import UserNotifications

// MARK: - NotificationManager
/// Quản lý quyền push + đăng ký remote notifications (APNs).
/// Thông báo poll-finished giờ do BACKEND tạo & gửi (socket / REST queue / APNs),
/// FE không tự schedule local notification nữa.
final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// Xin quyền push; nếu được cấp → đăng ký remote notifications để lấy device token.
    func requestAuthorizationAndRegister() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("⚠️ Notification auth error: \(error)")
            }
            guard granted else {
                print("❌ Notification denied")
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - Local notification (fallback chạy được trên Simulator + khi offline)
    /// Hẹn local notification tại thời điểm poll kết thúc. Bắn cả khi app đã đóng.
    /// Dùng làm fallback cho APNs (APNs không hoạt động trên Simulator).
    func schedulePollFinished(pollId: String, title: String, at date: Date) {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "🏁 Poll đã kết thúc!"
        content.body = "“\(title)” đã có kết quả. Mở app để xem ai thắng!"
        content.sound = .default
        content.userInfo = ["pollId": pollId]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: Self.identifier(pollId),
                                            content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("⚠️ Schedule local notification error: \(error)")
            } else {
                print("⏰ Scheduled local poll-finished notification in \(Int(interval))s")
            }
        }
    }

    /// Huỷ local notification đã hẹn (vd đang xem live nên không cần báo trùng).
    func cancel(pollId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(pollId)])
    }

    private static func identifier(_ pollId: String) -> String { "poll_finished_local_\(pollId)" }
}
