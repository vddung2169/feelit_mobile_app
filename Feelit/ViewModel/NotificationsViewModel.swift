import Foundation
import Combine

// MARK: - NotificationsViewModel
/// Logic cho `NotificationsViewController`: tải danh sách thông báo + đánh dấu đã đọc.
/// KHÔNG import UIKit.
final class NotificationsViewModel {

    @Published private(set) var items: [AppNotification] = []
    @Published private(set) var isLoading = false

    var userId: String { NotificationCoordinator.shared.currentUserId }

    func load() {
        isLoading = true
        APIClient.shared.getNotifications(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let res):
                    self.items = res.notifications
                    NotificationCoordinator.shared.setUnread(res.unreadCount)
                case .failure(let error):
                    print("⚠️ getNotifications failed: \(error)")
                }
            }
        }
    }

    func markAllRead() {
        APIClient.shared.markAllNotificationsRead(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, case .success(let res) = result else { return }
                NotificationCoordinator.shared.setUnread(res.unreadCount)
                self.items = self.items.map {
                    AppNotification(id: $0.id, userId: $0.userId, type: $0.type, title: $0.title,
                                    body: $0.body, data: $0.data, pollId: $0.pollId,
                                    isRead: true, createdAt: $0.createdAt)
                }
            }
        }
    }

    /// Đánh dấu đã đọc 1 item khi tap; trả `pollId` để View điều hướng (nil nếu không có).
    func didTap(_ item: AppNotification) -> String? {
        if !item.isRead {
            APIClient.shared.markNotificationRead(notificationId: item.id) { _ in }
            NotificationCoordinator.shared.setUnread(max(0, NotificationCoordinator.shared.unreadCount - 1))
        }
        return item.resolvedPollId
    }
}
