import UIKit
import Combine

// MARK: - ChatViewController
/// Màn hình chat 1-1 (View). Mọi state/network/typing nằm trong `ChatViewModel`;
/// VC chỉ dựng UI, bind dữ liệu, xử lý bàn phím và điều hướng.
final class ChatViewController: UIViewController {

    private let partnerId: String
    private let viewModel: ChatViewModel
    private var cancellables = Set<AnyCancellable>()

    /// Proxy đọc cho table (nguồn: ViewModel).
    private var messages: [Message] { viewModel.messages }
    /// Trạng thái footer typing của View (tách khỏi VM để quản lý tableFooterView).
    private var showingTypingIndicator = false

    // MARK: - Typing UI
    private let typingIndicator = TypingIndicatorView()

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
        tf.placeholder = L10n.Chat.messagePlaceholder
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(L10n.Common.send, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private var inputBottomConstraint: NSLayoutConstraint!

    // MARK: - Init
    init(myId: String, partnerId: String) {
        self.partnerId = partnerId
        self.viewModel = ChatViewModel(myId: myId, partnerId: partnerId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Chat.chatWithTitle(partnerId)
        view.backgroundColor = .systemBackground

        setupLayout()
        setupTableView()

        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        messageField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        updateSendButtonState()

        registerKeyboardNotifications()
        bindViewModel()
        viewModel.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Rời màn hình → báo ngừng gõ cho đối phương.
        viewModel.stopTypingIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.scrollToBottom(animated: true)
            }
            .store(in: &cancellables)

        viewModel.$isPartnerTyping
            .receive(on: DispatchQueue.main)
            .sink { [weak self] typing in
                typing ? self?.showTypingIndicator() : self?.hideTypingIndicator()
            }
            .store(in: &cancellables)

        viewModel.sendDidFail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showSendError() }
            .store(in: &cancellables)
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

    // MARK: - Actions
    @objc private func textChanged() {
        updateSendButtonState()
        viewModel.handleTypingActivity(text: messageField.text ?? "")
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
        viewModel.sendMessage(content)
    }

    private func showSendError() {
        let alert = UIAlertController(title: L10n.Common.error, message: "Không gửi được tin nhắn.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
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
                        let a = UIAlertController(title: L10n.Common.error, message: "Không mở được poll này.", preferredStyle: .alert)
                        a.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
                        self.present(a, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: - Typing indicator (footer)
private extension ChatViewController {
    func showTypingIndicator() {
        guard !showingTypingIndicator else { return }
        showingTypingIndicator = true
        typingIndicator.sizeToFitFooter(width: tableView.bounds.width)
        tableView.tableFooterView = typingIndicator
        typingIndicator.startAnimating()
        scrollToBottom(animated: true)
    }

    func hideTypingIndicator() {
        guard showingTypingIndicator else { return }
        showingTypingIndicator = false
        typingIndicator.stopAnimating()
        tableView.tableFooterView = nil
    }
}
