import Foundation
import Combine

// MARK: - FeedViewModel
/// Logic cho `FeedViewController`: tải posts (GET /api/posts) và like post.
/// KHÔNG import UIKit.
///
/// Ghi chú lệch so với README: màn Feed thực tế KHÔNG có socket (join_feed/post_liked)
/// và phần "Đang Hot" dùng `FEMock.polls` tĩnh (giữ ở View). Để không đổi behavior,
/// ViewModel chỉ quản lý `posts` async + like; không thêm socket.
final class FeedViewModel {

    // MARK: - Output
    @Published private(set) var posts: [FEPost] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = nil

    // MARK: - Static (mock) — section "Đang Hot" + Market Pulse chưa có backend
    let trendingPolls = FEMock.polls
    let marketPulseBullish = FEMock.marketPulseBullish
    let marketPulseVoters = FEMock.marketPulseVoters

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Input
    /// Tải posts; `completion` để View kết thúc pull-to-refresh.
    func loadFeed(completion: (() -> Void)? = nil) {
        isLoading = true
        getPostsPublisher()
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    if case .failure(let err) = result {
                        self?.errorMessage = err.localizedDescription
                    }
                    completion?()
                },
                receiveValue: { [weak self] posts in
                    self?.errorMessage = nil
                    self?.posts = posts
                    completion?()
                }
            )
            .store(in: &cancellables)
    }

    /// Like post: optimistic UI nằm ở cell. Ở đây gọi API + đồng bộ số tim;
    /// thất bại → revert `LikeStore` và phát lại `posts` để View reload cell.
    func likePost(postId: String) {
        let userId = DeviceIdManager.shared.deviceId
        APIClient.shared.likePost(postId: postId, userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let res):
                    if let idx = self.posts.firstIndex(where: { $0.id == postId }) {
                        self.posts[idx].likes = res.likes        // đồng bộ với server
                    }
                case .failure:
                    LikeStore.shared.setLiked(postId, !LikeStore.shared.isLiked(postId))
                    self.posts = self.posts                       // phát lại để View reload (revert)
                }
            }
        }
    }

    /// Tạo poll mới (mặc định 1 phút). Trả poll cho View để điều hướng.
    func createPoll(title: String, completion: @escaping (Result<Poll, Error>) -> Void) {
        APIClient.shared.createPoll(title: title, durationSeconds: 60) { result in
            DispatchQueue.main.async { completion(result) }
        }
    }

    func clearError() { errorMessage = nil }

    // MARK: - Publisher
    private func getPostsPublisher() -> AnyPublisher<[FEPost], Error> {
        Future<[PostDTO], Error> { promise in
            APIClient.shared.getPosts { promise($0) }
        }
        .map { dtos in dtos.map { $0.toFEPost() } }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    deinit { cancellables.removeAll() }
}
