import Foundation

// MARK: - SharePollViewModel
/// Logic cho `SharePollViewController`: danh sách người nhận + gửi poll-share qua API messages.
/// KHÔNG import UIKit.
final class SharePollViewModel {

    let poll: Poll

    // Demo app chỉ có 2 user cố định (xem ChatLoginViewController).
    private let allowedIds = ["test01", "test02"]
    private let myIdKey = "chat_my_id"

    private(set) var recipients: [String] = []
    var previewText: String { "📊 \(poll.title)" }

    init(poll: Poll) {
        self.poll = poll
        computeRecipients()
    }

    private func computeRecipients() {
        if let myId = UserDefaults.standard.string(forKey: myIdKey) {
            recipients = allowedIds.filter { $0 != myId }
        } else {
            recipients = allowedIds
        }
    }

    /// Người gửi: ưu tiên id đã đăng nhập; nếu chưa có thì suy ra là user còn lại.
    private func senderId(for recipient: String) -> String {
        UserDefaults.standard.string(forKey: myIdKey)
            ?? allowedIds.first(where: { $0 != recipient })
            ?? recipient
    }

    func share(to recipient: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let sender = senderId(for: recipient)
        let content = SharedPoll.encode(pollId: poll.id, title: poll.title, status: poll.status)
        APIClient.shared.sendMessage(senderId: sender, receiverId: recipient, content: content) { result in
            DispatchQueue.main.async {
                switch result {
                case .success: completion(.success(()))
                case .failure(let error): completion(.failure(error))
                }
            }
        }
    }
}
