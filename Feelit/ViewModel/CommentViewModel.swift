import Foundation
import Combine

// MARK: - CommentViewModel
/// Logic cho `CommentViewController`: tải/gửi bình luận + socket realtime cho 1 post.
/// KHÔNG import UIKit.
final class CommentViewModel {

    // MARK: - Output
    @Published private(set) var comments: [Comment] = []
    @Published private(set) var commentCount: Int
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published private(set) var errorMessage: String? = nil

    /// Username hiển thị (cho avatar ô nhập). Lộ ra để View dùng.
    let currentUsername: String

    // MARK: - Private
    private let postId: String
    private let myUserId = DeviceIdManager.shared.deviceId
    private var cancellables = Set<AnyCancellable>()
    private let socketManager = CommentSocketManager()

    // MARK: - Init
    init(postId: String, initialCommentCount: Int) {
        self.postId = postId
        self.commentCount = initialCommentCount
        self.currentUsername = UserDefaults.standard.string(forKey: "feelit_username") ?? "Bạn"

        socketManager.delegate = self
        socketManager.connectForPost(postId: postId)
    }

    // MARK: - Input
    func loadComments() {
        fetchComments(showLoading: true)
    }

    func sendComment(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 1) Optimistic: hiện ngay comment của mình (id tạm).
        let now = ISO8601DateFormatter().string(from: Date())
        let temp = Comment(id: "local-\(UUID().uuidString)", postId: postId,
                           userId: myUserId, username: currentUsername, content: trimmed, createdAt: now)
        appendCommentIfNeeded(temp)
        commentCount += 1
        isSending = true

        // 2) Gửi server, xong re-fetch để đồng bộ id/thời gian/số đếm thật.
        APIClient.shared.postComment(postId: postId, userId: myUserId,
                                     username: currentUsername, content: trimmed) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSending = false
                if case .failure(let error) = result {
                    self.errorMessage = error.localizedDescription
                }
                self.fetchComments(showLoading: false)
            }
        }
    }

    func clearError() { errorMessage = nil }

    // MARK: - Private
    private func fetchComments(showLoading: Bool) {
        if showLoading { isLoading = true }
        APIClient.shared.getComments(postId: postId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let list):
                    self.comments = list
                    self.commentCount = list.count
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func appendCommentIfNeeded(_ comment: Comment) {
        guard !comments.contains(where: { $0.id == comment.id }) else { return }
        comments.append(comment)
    }

    deinit {
        cancellables.removeAll()
        socketManager.disconnect(postId: postId)
    }
}

// MARK: - CommentSocketDelegate
extension CommentViewModel: CommentSocketDelegate {
    func didReceiveNewComment(_ comment: Comment, commentCount: Int) {
        guard comment.postId == postId else { return }
        self.commentCount = commentCount
        appendCommentIfNeeded(comment)
    }
}
