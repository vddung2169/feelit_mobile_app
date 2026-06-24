import Foundation

// MARK: - ChatLoginViewModel
/// Logic cho `ChatLoginViewController`: validate ID + nhớ ID lần trước.
/// KHÔNG import UIKit.
final class ChatLoginViewModel {

    enum Result {
        case ok(myId: String, partnerId: String)
        case invalid
        case same
    }

    private let allowedIds = ["test01", "test02"]
    private let myIdKey = "chat_my_id"

    /// ID đã đăng nhập lần trước (điền sẵn ô "ID của bạn").
    var savedMyId: String? { UserDefaults.standard.string(forKey: myIdKey) }

    /// Validate 2 ID; nếu hợp lệ tự lưu `myId` để dùng lại.
    func validate(myId raw1: String, partnerId raw2: String) -> Result {
        let myId = raw1.trimmingCharacters(in: .whitespacesAndNewlines)
        let partnerId = raw2.trimmingCharacters(in: .whitespacesAndNewlines)

        guard allowedIds.contains(myId), allowedIds.contains(partnerId) else { return .invalid }
        guard myId != partnerId else { return .same }

        UserDefaults.standard.set(myId, forKey: myIdKey)
        return .ok(myId: myId, partnerId: partnerId)
    }
}
