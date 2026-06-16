import Foundation
import Starscream

protocol CommentSocketDelegate: AnyObject {
    func didReceiveNewComment(_ comment: Comment, commentCount: Int)
    func didReceivePostLiked(postId: String, likes: Int)
}

// Default rỗng — màn nào không cần thì khỏi implement.
extension CommentSocketDelegate {
    func didReceivePostLiked(postId: String, likes: Int) {}
}

// Mỗi CommentViewController tạo 1 instance riêng — không dùng singleton.
final class CommentSocketManager: WebSocketDelegate {

    weak var delegate: CommentSocketDelegate?

    private var socket: WebSocket?
    private var currentPostId: String?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var sid: String?

    // ⚠️ Đổi IP khi test trên device thật
    private let serverURL = "ws://localhost:3001/socket.io/?EIO=4&transport=websocket"

    // MARK: - Connect for post
    func connectForPost(postId: String) {
        currentPostId = postId
        if isConnected {
            sendJoinPost(postId: postId)
            return
        }
        guard socket == nil else { return }
        guard let url = URL(string: serverURL) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
        print("🔌 CommentSocketManager: connecting...")
    }

    // MARK: - Disconnect
    func disconnect(postId: String) {
        if isConnected {
            sendSocketIOEvent(name: "leave_post", data: "{\"postId\":\"\(postId)\"}")
        }
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        socket?.disconnect()
        socket = nil
        isConnected = false
        currentPostId = nil
        sid = nil
        print("🔌 CommentSocketManager: disconnected")
    }

    // MARK: - WebSocketDelegate
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            print("✅ Comment WebSocket transport connected")

        case .disconnected(let reason, _):
            print("❌ Comment WebSocket disconnected: \(reason)")
            isConnected = false
            sid = nil
            if currentPostId != nil { scheduleReconnect() }

        case .text(let text):
            handleEngineIOMessage(text)

        case .error(let error):
            print("⚠️ Comment WebSocket error: \(String(describing: error))")
            isConnected = false
            socket = nil
            if currentPostId != nil { scheduleReconnect() }

        default:
            break
        }
    }

    // MARK: - Engine.IO parser
    private func handleEngineIOMessage(_ text: String) {
        guard let firstChar = text.first else { return }
        switch firstChar {
        case "0":
            // Engine.IO OPEN → gửi Socket.IO CONNECT
            let json = String(text.dropFirst())
            if let data = json.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sessionId = obj["sid"] as? String {
                sid = sessionId
            }
            socket?.write(string: "40")

        case "2":
            // PING → PONG
            socket?.write(string: "3")

        case "4":
            let sub = text.dropFirst()
            if sub.first == "0" {
                // Socket.IO connected → join_post
                isConnected = true
                reconnectTimer?.invalidate()
                reconnectTimer = nil
                print("✅ Comment Socket.IO connected")
                if let postId = currentPostId {
                    sendJoinPost(postId: postId)
                }
            } else if sub.first == "2" {
                handleSocketIOEvent(String(sub.dropFirst()))
            }

        default: break
        }
    }

    // MARK: - Socket.IO event parser
    private func handleSocketIOEvent(_ payload: String) {
        guard let data = payload.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let eventName = arr.first as? String else { return }

        switch eventName {
        case "new_comment":
            guard let obj = arr[safe: 1],
                  let jsonData = try? JSONSerialization.data(withJSONObject: obj),
                  let res = try? JSONDecoder().decode(CommentResponse.self, from: jsonData)
            else { return }
            DispatchQueue.main.async {
                self.delegate?.didReceiveNewComment(res.comment, commentCount: res.commentCount)
            }

        case "post_liked":
            guard let obj = arr[safe: 1] as? [String: Any],
                  let postId = obj["postId"] as? String,
                  let likes = (obj["likes"] as? Int) ?? (obj["likes"] as? NSNumber)?.intValue
            else { return }
            DispatchQueue.main.async {
                self.delegate?.didReceivePostLiked(postId: postId, likes: likes)
            }

        default: break
        }
    }

    // MARK: - Helpers
    private func sendJoinPost(postId: String) {
        sendSocketIOEvent(name: "join_post", data: "{\"postId\":\"\(postId)\"}")
        print("📤 join_post: \(postId)")
    }

    private func sendSocketIOEvent(name: String, data: String) {
        socket?.write(string: "42[\"\(name)\",\(data)]")
    }

    private func scheduleReconnect() {
        guard reconnectTimer == nil else { return }
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.reconnectTimer = nil
            self?.socket = nil
            if let postId = self?.currentPostId {
                self?.connectForPost(postId: postId)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
