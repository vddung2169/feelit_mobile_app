import Foundation

// MARK: - LikeStore
/// Lưu local danh sách post mà user đã tim (UserDefaults) để giữ trạng thái icon tim
/// sau khi tắt/mở lại app. Server giữ số đếm; client giữ "mình đã tim hay chưa".
final class LikeStore {

    static let shared = LikeStore()
    private init() {}

    private let key = "liked_post_ids"

    private var ids: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: key) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: key) }
    }

    func isLiked(_ postId: String) -> Bool { ids.contains(postId) }

    func setLiked(_ postId: String, _ liked: Bool) {
        var current = ids
        if liked { current.insert(postId) } else { current.remove(postId) }
        ids = current
    }
}
