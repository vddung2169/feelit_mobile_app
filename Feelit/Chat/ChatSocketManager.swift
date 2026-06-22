import Foundation
import Starscream

protocol ChatSocketDelegate: AnyObject {
    func didReceiveMessage(_ message: Message)
    /// Đối phương bắt đầu/ngừng gõ. senderId = người đang gõ.
    func didReceiveTyping(senderId: String, isTyping: Bool)
}

// Mặc định rỗng để delegate cũ không bắt buộc implement.
extension ChatSocketDelegate {
    func didReceiveTyping(senderId: String, isTyping: Bool) {}
}

// Mỗi ChatViewController tạo 1 instance riêng — không dùng singleton.
final class ChatSocketManager: WebSocketDelegate {

    weak var delegate: ChatSocketDelegate?

    private var socket: WebSocket?
    private var currentUserId: String?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var sid: String?

    // ⚠️ Đổi IP khi test trên device thật
    private let serverURL = "ws://localhost:3001/socket.io/?EIO=4&transport=websocket"

    // MARK: - Connect
    func connect(userId: String) {
        currentUserId = userId
        if isConnected {
            sendJoinChat(userId: userId)
            return
        }
        guard socket == nil else { return }
        guard let url = URL(string: serverURL) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
        print("🔌 ChatSocketManager: connecting...")
    }

    // MARK: - Disconnect
    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        socket?.disconnect()
        socket = nil
        isConnected = false
        currentUserId = nil
        sid = nil
        print("🔌 ChatSocketManager: disconnected")
    }

    // MARK: - WebSocketDelegate
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            print("✅ Chat WebSocket transport connected")

        case .disconnected(let reason, _):
            print("❌ Chat WebSocket disconnected: \(reason)")
            isConnected = false
            sid = nil
            if currentUserId != nil { scheduleReconnect() }

        case .text(let text):
            handleEngineIOMessage(text)

        case .error(let error):
            print("⚠️ Chat WebSocket error: \(String(describing: error))")
            isConnected = false
            socket = nil
            if currentUserId != nil { scheduleReconnect() }

        default:
            break
        }
    }

    // MARK: - Engine.IO parser
    private func handleEngineIOMessage(_ text: String) {
        guard let firstChar = text.first else { return }
        switch firstChar {
        case "0":
            // Engine.IO OPEN — gửi Socket.IO CONNECT
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
                // Socket.IO connected → join_chat
                isConnected = true
                reconnectTimer?.invalidate()
                reconnectTimer = nil
                print("✅ Chat Socket.IO connected")
                if let userId = currentUserId {
                    sendJoinChat(userId: userId)
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
        case "new_message":
            guard let obj = arr[safe: 1],
                  let jsonData = try? JSONSerialization.data(withJSONObject: obj),
                  let message = try? JSONDecoder().decode(Message.self, from: jsonData)
            else { return }
            DispatchQueue.main.async { self.delegate?.didReceiveMessage(message) }

        case "typing":
            guard let obj = arr[safe: 1] as? [String: Any],
                  let senderId = obj["senderId"] as? String else { return }
            // isTyping có thể là Bool hoặc số (0/1) tùy server.
            let isTyping = (obj["isTyping"] as? Bool)
                ?? ((obj["isTyping"] as? NSNumber)?.boolValue ?? false)
            DispatchQueue.main.async {
                self.delegate?.didReceiveTyping(senderId: senderId, isTyping: isTyping)
            }

        default: break
        }
    }

    // MARK: - Typing
    /// Báo cho server biết mình đang gõ / ngừng gõ với 1 người nhận cụ thể.
    /// Server cần broadcast lại event "typing" tới receiver.
    func sendTyping(senderId: String, receiverId: String, isTyping: Bool) {
        guard isConnected else { return }
        let payload = "{\"senderId\":\"\(senderId)\",\"receiverId\":\"\(receiverId)\",\"isTyping\":\(isTyping)}"
        sendSocketIOEvent(name: "typing", data: payload)
    }

    // MARK: - Helpers
    private func sendJoinChat(userId: String) {
        let payload = "{\"userId\":\"\(userId)\"}"
        sendSocketIOEvent(name: "join_chat", data: payload)
        print("📤 join_chat: \(userId)")
    }

    private func sendSocketIOEvent(name: String, data: String) {
        socket?.write(string: "42[\"\(name)\",\(data)]")
    }

    private func scheduleReconnect() {
        guard reconnectTimer == nil else { return }
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.reconnectTimer = nil
            self?.socket = nil
            if let userId = self?.currentUserId {
                self?.connect(userId: userId)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
