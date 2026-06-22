import Foundation
import Starscream

protocol SocketManagerDelegate: AnyObject {
    func socketDidConnect()
    func socketDidDisconnect()
    func socketDidReceiveVoteUpdate(_ update: VoteResponse)
    func socketDidReceivePollFinished(_ result: PollFinished)
}

// Mỗi PollViewController tạo 1 instance riêng — không dùng singleton
final class SocketManager: WebSocketDelegate {

    weak var delegate: SocketManagerDelegate?

    private var socket: WebSocket?
    private var currentPollId: String?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var sid: String?

    // ⚠️ Đổi IP khi test trên device thật
    private let serverURL = "ws://localhost:3001/socket.io/?EIO=4&transport=websocket"

    // MARK: - Connect
    func connect() {
        guard !isConnected, socket == nil else { return }
        guard let url = URL(string: serverURL) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
        print("🔌 SocketManager: connecting...")
    }

    // MARK: - Disconnect
    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        socket?.disconnect()
        socket = nil
        isConnected = false
        currentPollId = nil
        sid = nil
        print("🔌 SocketManager: disconnected")
    }

    // MARK: - Join poll room
    func joinPoll(pollId: String) {
        currentPollId = pollId
        if isConnected {
            sendJoinPoll(pollId: pollId)
        } else {
            connect()
        }
    }

    // MARK: - Leave poll room
    func leavePoll(pollId: String) {
        guard isConnected else { return }
        let payload = "{\"pollId\":\"\(pollId)\"}"
        sendSocketIOEvent(name: "leave_poll", data: payload)
        currentPollId = nil
    }

    // MARK: - WebSocketDelegate
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            print("✅ WebSocket transport connected")

        case .disconnected(let reason, _):
            print("❌ WebSocket disconnected: \(reason)")
            isConnected = false
            sid = nil
            // Chỉ reconnect nếu vẫn còn pollId (user chưa rời màn hình)
            if currentPollId != nil {
                scheduleReconnect()
            }
            DispatchQueue.main.async { self.delegate?.socketDidDisconnect() }

        case .text(let text):
            handleEngineIOMessage(text)

        case .error(let error):
            print("⚠️ WebSocket error: \(String(describing: error))")
            isConnected = false
            socket = nil
            if currentPollId != nil {
                scheduleReconnect()
            }
            DispatchQueue.main.async { self.delegate?.socketDidDisconnect() }

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
                // Socket.IO connected
                isConnected = true
                reconnectTimer?.invalidate()
                reconnectTimer = nil
                print("✅ Socket.IO connected")
                DispatchQueue.main.async { self.delegate?.socketDidConnect() }
                if let pollId = currentPollId {
                    sendJoinPoll(pollId: pollId)
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
        case "vote_update":
            guard let obj = arr[safe: 1],
                  let jsonData = try? JSONSerialization.data(withJSONObject: obj),
                  let update = try? JSONDecoder().decode(VoteResponse.self, from: jsonData)
            else { return }
            DispatchQueue.main.async { self.delegate?.socketDidReceiveVoteUpdate(update) }

        case "poll_finished":
            guard let obj = arr[safe: 1],
                  let jsonData = try? JSONSerialization.data(withJSONObject: obj),
                  let finished = try? JSONDecoder().decode(PollFinished.self, from: jsonData)
            else { return }
            DispatchQueue.main.async { self.delegate?.socketDidReceivePollFinished(finished) }

        default: break
        }
    }

    // MARK: - Helpers
    private func sendJoinPoll(pollId: String) {
        let payload = "{\"pollId\":\"\(pollId)\"}"
        sendSocketIOEvent(name: "join_poll", data: payload)
        print("📤 join_poll: \(pollId)")
    }

    private func sendSocketIOEvent(name: String, data: String) {
        socket?.write(string: "42[\"\(name)\",\(data)]")
    }

    private func scheduleReconnect() {
        guard reconnectTimer == nil else { return }
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.reconnectTimer = nil
            self?.socket = nil
            self?.connect()
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
