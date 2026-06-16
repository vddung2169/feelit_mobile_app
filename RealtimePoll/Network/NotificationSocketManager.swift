import Foundation
import Starscream

protocol NotificationSocketDelegate: AnyObject {
    func didReceiveAppNotification(_ notification: AppNotification)
}

// MARK: - NotificationSocketManager
/// Socket cấp APP (singleton) — luôn kết nối để nhận event `notification` realtime.
/// Join room cá nhân `user:{userId}` qua event `join_chat` ngay khi connect/reconnect.
/// Engine.IO handshake thủ công, giống các SocketManager khác.
final class NotificationSocketManager: WebSocketDelegate {

    static let shared = NotificationSocketManager()
    private init() {}

    weak var delegate: NotificationSocketDelegate?

    private var socket: WebSocket?
    private var userId: String?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var sid: String?

    // ⚠️ Đổi IP khi test trên device thật
    private let serverURL = "ws://localhost:3001/socket.io/?EIO=4&transport=websocket"

    // MARK: - Connect
    func connect(userId: String) {
        self.userId = userId
        if isConnected {
            sendJoinChat()
            return
        }
        guard socket == nil else { return }
        guard let url = URL(string: serverURL) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
        print("🔌 NotificationSocketManager: connecting...")
    }

    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        socket?.disconnect()
        socket = nil
        isConnected = false
        sid = nil
    }

    // MARK: - WebSocketDelegate
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            print("✅ Notification WebSocket transport connected")

        case .disconnected(let reason, _):
            print("❌ Notification WebSocket disconnected: \(reason)")
            isConnected = false
            sid = nil
            scheduleReconnect()

        case .text(let text):
            handleEngineIOMessage(text)

        case .error(let error):
            print("⚠️ Notification WebSocket error: \(String(describing: error))")
            isConnected = false
            socket = nil
            scheduleReconnect()

        default:
            break
        }
    }

    // MARK: - Engine.IO parser
    private func handleEngineIOMessage(_ text: String) {
        guard let firstChar = text.first else { return }
        switch firstChar {
        case "0":
            let json = String(text.dropFirst())
            if let data = json.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sessionId = obj["sid"] as? String {
                sid = sessionId
            }
            socket?.write(string: "40")

        case "2":
            socket?.write(string: "3")   // PING → PONG

        case "4":
            let sub = text.dropFirst()
            if sub.first == "0" {
                isConnected = true
                reconnectTimer?.invalidate()
                reconnectTimer = nil
                print("✅ Notification Socket.IO connected")
                sendJoinChat()
            } else if sub.first == "2" {
                handleSocketIOEvent(String(sub.dropFirst()))
            }

        default: break
        }
    }

    private func handleSocketIOEvent(_ payload: String) {
        guard let data = payload.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let eventName = arr.first as? String else { return }

        switch eventName {
        case "notification":
            guard let obj = arr[safe: 1],
                  let jsonData = try? JSONSerialization.data(withJSONObject: obj),
                  let notification = try? JSONDecoder().decode(AppNotification.self, from: jsonData)
            else { return }
            DispatchQueue.main.async {
                self.delegate?.didReceiveAppNotification(notification)
            }

        default: break
        }
    }

    // MARK: - Helpers
    private func sendJoinChat() {
        guard let userId = userId else { return }
        socket?.write(string: "42[\"join_chat\",{\"userId\":\"\(userId)\"}]")
        print("📤 join_chat (notifications): \(userId)")
    }

    private func scheduleReconnect() {
        guard reconnectTimer == nil, userId != nil else { return }
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.reconnectTimer = nil
            self?.socket = nil
            if let userId = self?.userId { self?.connect(userId: userId) }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
