import Foundation

// MARK: - APIClient
/// Tất cả REST calls tới Node.js backend dùng URLSession thuần.
/// iOS Simulator → localhost:3000
/// Android Emulator → 10.0.2.2:3000
/// Device thật → IP LAN của Mac, ví dụ 192.168.1.x:3000
final class APIClient {

    static let shared = APIClient()
    private init() {}

    // ⚠️ Đổi IP này khi test trên device thật
    private let baseURL = "http://localhost:3001"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    // MARK: - Generic request helper
    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Encodable? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10

        if let body = body {
            req.httpBody = try? encoder.encode(body)
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.zeroByteResource)))
                return
            }

            // Thử decode lỗi từ server trước
            if let httpRes = response as? HTTPURLResponse,
               httpRes.statusCode >= 400 {
                if let apiError = try? self.decoder.decode(APIError.self, from: data) {
                    completion(.failure(PollError.serverError(apiError.message)))
                } else {
                    completion(.failure(PollError.serverError("HTTP \(httpRes.statusCode)")))
                }
                return
            }

            do {
                let decoded = try self.decoder.decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Endpoints

    /// GET /api/polls/active
    func getActivePoll(completion: @escaping (Result<Poll, Error>) -> Void) {
        request(path: "/api/polls/active", completion: completion)
    }

    /// GET /api/polls/:id
    func getPoll(pollId: String, completion: @escaping (Result<Poll, Error>) -> Void) {
        request(path: "/api/polls/\(pollId)", completion: completion)
    }

    /// POST /api/polls — tạo poll. durationSeconds mặc định 60 (1 phút).
    func createPoll(title: String, durationSeconds: Int = 60,
                    completion: @escaping (Result<Poll, Error>) -> Void) {
        let body = CreatePollRequest(title: title, durationSeconds: durationSeconds)
        request(path: "/api/polls", method: "POST", body: body, completion: completion)
    }

    /// POST /api/polls/:id/votes
    func submitVote(
        pollId: String,
        choice: String,
        completion: @escaping (Result<VoteResponse, Error>) -> Void
    ) {
        let body = VoteRequest(voterId: DeviceIdManager.shared.deviceId, choice: choice)
        request(path: "/api/polls/\(pollId)/votes", method: "POST", body: body, completion: completion)
    }

    /// GET /api/polls/:id/chart
    func getChart(
        pollId: String,
        completion: @escaping (Result<[ChartPoint], Error>) -> Void
    ) {
        request(path: "/api/polls/\(pollId)/chart", completion: completion)
    }
    
    /// GET /api/polls — Lấy danh sách polls
    func getPolls(completion: @escaping (Result<[Poll], Error>) -> Void) {
        request(path: "/api/polls", completion: completion)
    }

    // MARK: - Chat

    /// GET /api/messages/:userId1/:userId2 — lịch sử tin nhắn giữa 2 user
    func getMessages(
        userId1: String,
        userId2: String,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        request(path: "/api/messages/\(userId1)/\(userId2)", completion: completion)
    }

    /// POST /api/messages — gửi tin nhắn
    func sendMessage(
        senderId: String,
        receiverId: String,
        content: String,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        let body = SendMessageRequest(senderId: senderId, receiverId: receiverId, content: content)
        request(path: "/api/messages", method: "POST", body: body, completion: completion)
    }

    // MARK: - Feed Posts

    /// GET /api/posts — danh sách post cho Feed
    func getPosts(completion: @escaping (Result<[PostDTO], Error>) -> Void) {
        request(path: "/api/posts", completion: completion)
    }

    // MARK: - Feed Comments & Likes

    /// GET /api/posts/:postId/comments — lịch sử bình luận của 1 post
    func getComments(
        postId: String,
        completion: @escaping (Result<[Comment], Error>) -> Void
    ) {
        request(path: "/api/posts/\(postId)/comments", completion: completion)
    }

    /// POST /api/posts/:postId/comments — gửi bình luận
    func postComment(
        postId: String,
        userId: String,
        username: String,
        content: String,
        completion: @escaping (Result<CommentResponse, Error>) -> Void
    ) {
        let body = PostCommentRequest(userId: userId, username: username, content: content)
        request(path: "/api/posts/\(postId)/comments", method: "POST", body: body, completion: completion)
    }

    /// POST /api/posts/:postId/like — like 1 post
    func likePost(
        postId: String,
        userId: String,
        completion: @escaping (Result<LikeResponse, Error>) -> Void
    ) {
        let body = LikePostRequest(userId: userId)
        request(path: "/api/posts/\(postId)/like", method: "POST", body: body, completion: completion)
    }

    // MARK: - Notifications & Devices

    /// GET /api/notifications/:userId — danh sách thông báo + unreadCount
    func getNotifications(
        userId: String,
        unreadOnly: Bool = false,
        completion: @escaping (Result<NotificationListResponse, Error>) -> Void
    ) {
        let query = unreadOnly ? "?unread=true" : ""
        request(path: "/api/notifications/\(userId)\(query)", completion: completion)
    }

    /// POST /api/notifications/:notificationId/read — đánh dấu đã đọc 1 cái
    func markNotificationRead(
        notificationId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        requestVoid(path: "/api/notifications/\(notificationId)/read", method: "POST", completion: completion)
    }

    /// POST /api/notifications/:userId/read-all — đánh dấu đã đọc tất cả
    func markAllNotificationsRead(
        userId: String,
        completion: @escaping (Result<ReadAllResponse, Error>) -> Void
    ) {
        request(path: "/api/notifications/\(userId)/read-all", method: "POST", completion: completion)
    }

    /// POST /api/devices — đăng ký device token cho APNs push
    func registerDevice(
        userId: String,
        token: String,
        platform: String = "ios",
        completion: @escaping (Result<DeviceRegisterResponse, Error>) -> Void
    ) {
        let body = RegisterDeviceRequest(userId: userId, token: token, platform: platform)
        request(path: "/api/devices", method: "POST", body: body, completion: completion)
    }

    // MARK: - Void request (endpoint không trả body hữu ích)
    private func requestVoid(
        path: String,
        method: String,
        body: Encodable? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(URLError(.badURL))); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10
        if let body = body { req.httpBody = try? encoder.encode(body) }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 400 {
                if let data = data, let apiError = try? self.decoder.decode(APIError.self, from: data) {
                    completion(.failure(PollError.serverError(apiError.message)))
                } else {
                    completion(.failure(PollError.serverError("HTTP \(httpRes.statusCode)")))
                }
                return
            }
            completion(.success(()))
        }.resume()
    }
}

// MARK: - Poll request bodies
private struct CreatePollRequest: Codable {
    let title: String
    let durationSeconds: Int
}

// MARK: - Feed request bodies
private struct PostCommentRequest: Codable {
    let userId: String
    let username: String
    let content: String
}

private struct LikePostRequest: Codable {
    let userId: String
}

private struct RegisterDeviceRequest: Codable {
    let userId: String
    let token: String
    let platform: String
}

// MARK: - Feed responses
struct CommentResponse: Codable {
    let comment: Comment
    let commentCount: Int
}

struct LikeResponse: Codable {
    let postId: String
    let likes: Int
}

// MARK: - SendMessageRequest
// Body dạng camelCase theo spec: { senderId, receiverId, content }
private struct SendMessageRequest: Codable {
    let senderId: String
    let receiverId: String
    let content: String
}

// MARK: - Custom errors
enum PollError: LocalizedError {
    case serverError(String)
    case noActivePoll

    var errorDescription: String? {
        switch self {
        case .serverError(let msg): return msg
        case .noActivePoll:         return "Không có poll nào đang active."
        }
    }
}
