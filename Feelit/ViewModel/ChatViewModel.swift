import Foundation
import Combine

// MARK: - ChatViewModel
/// Logic cho `ChatViewController`: lịch sử (REST) + realtime (ChatSocketManager) + typing.
/// KHÔNG import UIKit. Là delegate của socket (callback đã ở main thread).
final class ChatViewModel: ChatSocketDelegate {

    // MARK: - Output
    @Published private(set) var messages: [Message] = []
    /// Đối phương có đang gõ không (điều khiển typing indicator ở View).
    @Published private(set) var isPartnerTyping = false
    /// Phát khi gửi tin thất bại để View báo lỗi.
    let sendDidFail = PassthroughSubject<Void, Never>()

    let myId: String
    let partnerId: String

    // MARK: - Private
    private let socketManager = ChatSocketManager()

    // Outgoing typing
    private var didSendTypingStart = false
    private var typingIdleTimer: Timer?
    private let typingIdleInterval: TimeInterval = 2.0      // giống Messenger

    // Incoming typing
    private var partnerTypingTimeout: Timer?
    private let partnerTypingTTL: TimeInterval = 5.0        // an toàn nếu mất event stop

    // MARK: - Init
    init(myId: String, partnerId: String) {
        self.myId = myId
        self.partnerId = partnerId
    }

    // MARK: - Lifecycle
    func start() {
        // Để bubble so sánh đúng "của mình".
        Message.currentUserId = myId
        socketManager.delegate = self
        socketManager.connect(userId: myId)
        loadHistory()
    }

    func loadHistory() {
        APIClient.shared.getMessages(userId1: myId, userId2: partnerId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let history): self.messages = history
                case .failure(let error):   print("⚠️ getMessages failed: \(error)")
                }
            }
        }
    }

    // MARK: - Send
    func sendMessage(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Gửi tin = ngừng gõ.
        stopTypingIfNeeded()

        APIClient.shared.sendMessage(senderId: myId, receiverId: partnerId, content: trimmed) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let message):
                    self.appendMessageIfNeeded(message)   // tránh trùng nếu socket cũng đẩy về
                case .failure(let error):
                    print("⚠️ sendMessage failed: \(error)")
                    self.sendDidFail.send(())
                }
            }
        }
    }

    // MARK: - Outgoing typing
    /// Gọi mỗi lần text thay đổi. Gửi "typing=true" 1 lần, rồi reset idle timer.
    func handleTypingActivity(text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { stopTypingIfNeeded(); return }

        if !didSendTypingStart {
            didSendTypingStart = true
            socketManager.sendTyping(senderId: myId, receiverId: partnerId, isTyping: true)
        }
        typingIdleTimer?.invalidate()
        typingIdleTimer = Timer.scheduledTimer(withTimeInterval: typingIdleInterval, repeats: false) { [weak self] _ in
            self?.stopTypingIfNeeded()
        }
    }

    func stopTypingIfNeeded() {
        typingIdleTimer?.invalidate()
        typingIdleTimer = nil
        guard didSendTypingStart else { return }
        didSendTypingStart = false
        socketManager.sendTyping(senderId: myId, receiverId: partnerId, isTyping: false)
    }

    func disconnect() { socketManager.disconnect() }

    // MARK: - Private helpers
    private func appendMessageIfNeeded(_ message: Message) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
    }

    private func setPartnerTyping(_ typing: Bool) {
        partnerTypingTimeout?.invalidate()
        partnerTypingTimeout = nil
        if typing {
            isPartnerTyping = true
            // An toàn: tự ẩn nếu không nhận được event stop.
            partnerTypingTimeout = Timer.scheduledTimer(withTimeInterval: partnerTypingTTL, repeats: false) { [weak self] _ in
                self?.isPartnerTyping = false
            }
        } else {
            isPartnerTyping = false
        }
    }

    // MARK: - ChatSocketDelegate
    func didReceiveMessage(_ message: Message) {
        // Chỉ nhận tin trong cuộc hội thoại này.
        let isInThisChat =
            (message.senderId == myId && message.receiverId == partnerId) ||
            (message.senderId == partnerId && message.receiverId == myId)
        guard isInThisChat else { return }

        if message.senderId == partnerId { setPartnerTyping(false) }   // vừa gửi tin → hết gõ
        appendMessageIfNeeded(message)
    }

    func didReceiveTyping(senderId: String, isTyping: Bool) {
        guard senderId == partnerId else { return }
        setPartnerTyping(isTyping)
    }

    deinit {
        typingIdleTimer?.invalidate()
        partnerTypingTimeout?.invalidate()
        socketManager.disconnect()
    }
}
