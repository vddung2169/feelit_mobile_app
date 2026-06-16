import UIKit

// MARK: - ChatViewController
/// Màn hình chat 1-1: load lịch sử qua REST, nhận realtime qua ChatSocketManager.
final class ChatViewController: UIViewController {

    private let myId: String
    private let partnerId: String

    private var messages: [Message] = []

    // Mỗi VC tạo instance riêng — không singleton
    private let socketManager = ChatSocketManager()

    // MARK: - Typing state
    private let typingIndicator = TypingIndicatorView()
    /// Đã gửi "typing=true" lên server chưa (tránh spam mỗi keystroke).
    private var didSendTypingStart = false
    /// Hết hạn sau khi ngừng gõ → gửi "typing=false".
    private var typingIdleTimer: Timer?
    /// Tự ẩn indicator nếu mất event "typing=false" từ đối phương.
    private var partnerTypingTimeout: Timer?
    private var isPartnerTyping = false

    private let typingIdleInterval: TimeInterval = 2.0      // giống Messenger
    private let partnerTypingTTL: TimeInterval = 5.0        // an toàn nếu mất event stop

    // MARK: - UI
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.allowsSelection = false
        tv.keyboardDismissMode = .interactive
        tv.backgroundColor = .systemBackground
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let messageField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Nhập tin nhắn..."
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Gửi", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private var inputBottomConstraint: NSLayoutConstraint!

    // MARK: - Init
    init(myId: String, partnerId: String) {
        self.myId = myId
        self.partnerId = partnerId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat với \(partnerId)"
        view.backgroundColor = .systemBackground

        // Để bubble so sánh đúng "của mình"
        Message.currentUserId = myId

        setupLayout()
        setupTableView()

        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        messageField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        updateSendButtonState()

        registerKeyboardNotifications()

        socketManager.delegate = self
        socketManager.connect(userId: myId)

        loadHistory()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Rời màn hình → báo ngừng gõ cho đối phương.
        stopTypingIfNeeded()
    }

    deinit {
        typingIdleTimer?.invalidate()
        partnerTypingTimeout?.invalidate()
        socketManager.disconnect()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(messageField)
        inputContainer.addSubview(sendButton)

        inputBottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint,

            messageField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            messageField.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            messageField.bottomAnchor.constraint(equalTo: inputContainer.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            sendButton.leadingAnchor.constraint(equalTo: messageField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: messageField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.reuseId)
        tableView.register(SharedPollBubbleCell.self, forCellReuseIdentifier: SharedPollBubbleCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    // MARK: - Data
    private func loadHistory() {
        APIClient.shared.getMessages(userId1: myId, userId2: partnerId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let history):
                    self.messages = history
                    self.tableView.reloadData()
                    self.scrollToBottom(animated: false)
                case .failure(let error):
                    print("⚠️ getMessages failed: \(error)")
                }
            }
        }
    }

    // MARK: - Actions
    @objc private func textChanged() {
        updateSendButtonState()
        handleTypingActivity()
    }

    // MARK: - Outgoing typing
    /// Gọi mỗi lần text thay đổi. Gửi "typing=true" 1 lần, rồi reset idle timer.
    private func handleTypingActivity() {
        let text = messageField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Xóa hết chữ → coi như ngừng gõ ngay.
        guard !text.isEmpty else {
            stopTypingIfNeeded()
            return
        }

        if !didSendTypingStart {
            didSendTypingStart = true
            socketManager.sendTyping(senderId: myId, receiverId: partnerId, isTyping: true)
        }

        // Reset idle timer: 2s không gõ → gửi stop.
        typingIdleTimer?.invalidate()
        typingIdleTimer = Timer.scheduledTimer(withTimeInterval: typingIdleInterval, repeats: false) { [weak self] _ in
            self?.stopTypingIfNeeded()
        }
    }

    /// Gửi "typing=false" nếu trước đó đã gửi start.
    private func stopTypingIfNeeded() {
        typingIdleTimer?.invalidate()
        typingIdleTimer = nil
        guard didSendTypingStart else { return }
        didSendTypingStart = false
        socketManager.sendTyping(senderId: myId, receiverId: partnerId, isTyping: false)
    }

    private func updateSendButtonState() {
        let text = messageField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        sendButton.isEnabled = !text.isEmpty
    }

    @objc private func sendTapped() {
        let content = messageField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty else { return }

        messageField.text = ""
        updateSendButtonState()
        // Gửi tin = ngừng gõ.
        stopTypingIfNeeded()

        APIClient.shared.sendMessage(senderId: myId, receiverId: partnerId, content: content) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let message):
                    // Tránh trùng nếu socket cũng đẩy về cùng id
                    self.appendMessageIfNeeded(message)
                case .failure(let error):
                    print("⚠️ sendMessage failed: \(error)")
                    self.showSendError()
                }
            }
        }
    }

    private func appendMessageIfNeeded(_ message: Message) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
        tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .automatic)
        scrollToBottom(animated: true)
    }

    private func showSendError() {
        let alert = UIAlertController(title: "Lỗi", message: "Không gửi được tin nhắn.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    // MARK: - Keyboard
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let isHiding = notification.name == UIResponder.keyboardWillHideNotification
        let bottomInset = isHiding ? 0 : -frame.height + view.safeAreaInsets.bottom
        inputBottomConstraint.constant = bottomInset

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]

        // Poll share → card cell có thể bấm để route.
        if let shared = message.sharedPoll {
            let cell = tableView.dequeueReusableCell(withIdentifier: SharedPollBubbleCell.reuseId, for: indexPath) as! SharedPollBubbleCell
            cell.configure(with: message, shared: shared)
            cell.onTap = { [weak self] pollId in
                self?.openSharedPoll(pollId: pollId)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBubbleCell.reuseId, for: indexPath) as! ChatBubbleCell
        cell.configure(with: message)
        return cell
    }
}

// MARK: - Routing tới poll được share
private extension ChatViewController {
    func openSharedPoll(pollId: String) {
        // Fetch poll mới nhất rồi push (counts/status có thể đã đổi từ lúc share).
        let loading = UIAlertController(title: nil, message: "Đang mở poll...", preferredStyle: .alert)
        present(loading, animated: true)

        PollRepository.shared.loadPoll(pollId: pollId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                loading.dismiss(animated: true) {
                    switch result {
                    case .success(let poll):
                        let vc = PollViewController(poll: poll)
                        self.navigationController?.pushViewController(vc, animated: true)
                    case .failure:
                        let a = UIAlertController(title: "Lỗi", message: "Không mở được poll này.", preferredStyle: .alert)
                        a.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(a, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: - ChatSocketDelegate
extension ChatViewController: ChatSocketDelegate {
    func didReceiveMessage(_ message: Message) {
        // Chỉ nhận tin trong cuộc hội thoại này
        let isInThisChat =
            (message.senderId == myId && message.receiverId == partnerId) ||
            (message.senderId == partnerId && message.receiverId == myId)
        guard isInThisChat else { return }

        // Đối phương vừa gửi tin → ẩn indicator ngay.
        if message.senderId == partnerId { setPartnerTyping(false) }
        appendMessageIfNeeded(message)
    }

    func didReceiveTyping(senderId: String, isTyping: Bool) {
        // Chỉ quan tâm khi chính đối phương trong cuộc chat này đang gõ.
        guard senderId == partnerId else { return }
        setPartnerTyping(isTyping)
    }
}

// MARK: - Incoming typing indicator
private extension ChatViewController {
    func setPartnerTyping(_ typing: Bool) {
        partnerTypingTimeout?.invalidate()
        partnerTypingTimeout = nil

        if typing {
            showTypingIndicator()
            // An toàn: tự ẩn nếu không nhận được event stop.
            partnerTypingTimeout = Timer.scheduledTimer(withTimeInterval: partnerTypingTTL, repeats: false) { [weak self] _ in
                self?.hideTypingIndicator()
            }
        } else {
            hideTypingIndicator()
        }
    }

    func showTypingIndicator() {
        guard !isPartnerTyping else { return }
        isPartnerTyping = true
        typingIndicator.sizeToFitFooter(width: tableView.bounds.width)
        tableView.tableFooterView = typingIndicator
        typingIndicator.startAnimating()
        scrollToBottom(animated: true)
    }

    func hideTypingIndicator() {
        guard isPartnerTyping else { return }
        isPartnerTyping = false
        typingIndicator.stopAnimating()
        tableView.tableFooterView = nil
    }
}
