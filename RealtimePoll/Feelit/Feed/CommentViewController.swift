import UIKit

// MARK: - CommentViewController
/// Bottom sheet xem + gửi bình luận realtime cho 1 post.
/// Present bằng pageSheet (detents) từ FeedViewController.
final class CommentViewController: UIViewController {

    private let postId: String
    private let postTitle: String
    private var commentCount: Int

    private var comments: [Comment] = []

    // Identity tạm cho MVP
    private let myUserId = DeviceIdManager.shared.deviceId
    private let myUsername = UserDefaults.standard.string(forKey: "feelit_username") ?? "Bạn"

    private let socketManager = CommentSocketManager()

    // MARK: UI
    private let handleBar = UIView()
    private let titleLabel = UILabel()
    private let divider = UIView()
    private let tableView = UITableView()
    private let emptyStateView = UIView()
    private let spinner = UIActivityIndicatorView(style: .large)

    private let inputBar = UIView()
    private let inputAvatar = AvatarView(size: 32, fontSize: 13)
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var inputBottomConstraint: NSLayoutConstraint!

    // MARK: Init
    init(postId: String, postTitle: String, initialCommentCount: Int) {
        self.postId = postId
        self.postTitle = postTitle
        self.commentCount = initialCommentCount
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        setupHeader()
        setupInputBar()
        setupTableView()
        setupEmptyState()
        setupSpinner()
        registerKeyboard()
        updateTitle()
        updateSendState()

        socketManager.delegate = self
        socketManager.connectForPost(postId: postId)
        loadComments()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            socketManager.disconnect(postId: postId)
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: Header
    private func setupHeader() {
        handleBar.backgroundColor = FeelitColors.surfaceElevated
        handleBar.layer.cornerRadius = 2
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        handleBar.isUserInteractionEnabled = true
        handleBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissTapped)))
        view.addSubview(handleBar)

        titleLabel.font = FeelitFonts.title
        titleLabel.textColor = FeelitColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        divider.backgroundColor = FeelitColors.border
        divider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(divider)

        NSLayoutConstraint.activate([
            handleBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            handleBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 36),
            handleBar.heightAnchor.constraint(equalToConstant: 4),

            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    // MARK: Input bar
    private func setupInputBar() {
        inputBar.backgroundColor = FeelitColors.surface
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBar)

        let topBorder = UIView()
        topBorder.backgroundColor = FeelitColors.border
        topBorder.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(topBorder)

        inputAvatar.configure(username: myUsername)

        textField.backgroundColor = FeelitColors.surfaceElevated
        textField.layer.cornerRadius = 18
        textField.font = FeelitFonts.body
        textField.textColor = FeelitColors.textPrimary
        textField.attributedPlaceholder = NSAttributedString(
            string: "Viết bình luận...",
            attributes: [.foregroundColor: FeelitColors.textTertiary])
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        textField.rightViewMode = .always
        textField.returnKeyType = .send
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.setContentHuggingPriority(.required, for: .horizontal)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 32)
        sendButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)

        inputBar.addSubview(inputAvatar)
        inputBar.addSubview(textField)
        inputBar.addSubview(sendButton)

        inputBottomConstraint = inputBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint,

            topBorder.topAnchor.constraint(equalTo: inputBar.topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: 1),

            inputAvatar.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 12),
            inputAvatar.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 10),

            textField.leadingAnchor.constraint(equalTo: inputAvatar.trailingAnchor, constant: 8),
            textField.centerYAnchor.constraint(equalTo: inputAvatar.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 36),

            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),

            // Pin avatar bottom (EQUAL) vào safe area → quyết định chiều cao inputBar,
            // nhờ đó tableView ở trên có chiều cao xác định (không bị co về 0).
            inputAvatar.bottomAnchor.constraint(equalTo: inputBar.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])
    }

    // MARK: TableView
    private func setupTableView() {
        tableView.backgroundColor = FeelitColors.background
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true

        let emoji = UILabel()
        emoji.text = "💬"
        emoji.font = .systemFont(ofSize: 40)
        emoji.textAlignment = .center

        let line1 = UILabel()
        line1.text = "Chưa có bình luận nào"
        line1.font = FeelitFonts.body
        line1.textColor = FeelitColors.textSecondary
        line1.textAlignment = .center

        let line2 = UILabel()
        line2.text = "Hãy là người đầu tiên!"
        line2.font = FeelitFonts.caption
        line2.textColor = FeelitColors.textTertiary
        line2.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [emoji, line1, line2])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(stack)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),
            stack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
        ])
    }

    private func setupSpinner() {
        spinner.color = FeelitColors.textSecondary
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
        ])
    }

    // MARK: Data
    private func loadComments() {
        fetchComments(showSpinner: true)
    }

    private func fetchComments(showSpinner: Bool) {
        if showSpinner { spinner.startAnimating() }
        APIClient.shared.getComments(postId: postId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.spinner.stopAnimating()
                switch result {
                case .success(let list):
                    self.comments = list
                    self.commentCount = list.count
                    self.updateTitle()
                    self.tableView.reloadData()
                    self.updateEmptyState()
                    self.scrollToBottom(animated: false)
                case .failure(let error):
                    print("⚠️ getComments failed: \(error)")
                    self.updateEmptyState()
                }
            }
        }
    }

    @objc private func sendTapped() {
        let content = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty else { return }

        textField.text = ""
        updateSendState()

        // 1) Optimistic: hiện ngay comment của mình (id tạm) để UX mượt,
        //    không phụ thuộc response của BE.
        let now = ISO8601DateFormatter().string(from: Date())
        let temp = Comment(id: "local-\(UUID().uuidString)", postId: postId,
                           userId: myUserId, username: myUsername, content: content, createdAt: now)
        appendCommentIfNeeded(temp)
        commentCount += 1
        updateTitle()

        // 2) Gửi lên server; xong thì đồng bộ lại để có id/thời gian/số đếm thật
        //    (đồng thời thay thế comment tạm). Re-fetch cả khi fail vì BE có thể đã lưu
        //    nhưng trả response khác shape.
        APIClient.shared.postComment(postId: postId, userId: myUserId,
                                     username: myUsername, content: content) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case .failure(let error) = result {
                    print("⚠️ postComment failed/decode: \(error) — reconciling from server")
                }
                self.fetchComments(showSpinner: false)
            }
        }
    }

    private func appendCommentIfNeeded(_ comment: Comment) {
        guard !comments.contains(where: { $0.id == comment.id }) else { return }
        let wasNearBottom = isNearBottom
        comments.append(comment)
        updateEmptyState()
        tableView.insertRows(at: [IndexPath(row: comments.count - 1, section: 0)], with: .automatic)
        if wasNearBottom { scrollToBottom(animated: true) }
    }

    // MARK: Helpers
    private func updateTitle() {
        titleLabel.text = "\(commentCount) bình luận"
    }

    private func updateEmptyState() {
        emptyStateView.isHidden = !comments.isEmpty
    }

    @objc private func textChanged() { updateSendState() }

    private func updateSendState() {
        let hasText = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        sendButton.isEnabled = hasText
        sendButton.tintColor = hasText ? FeelitColors.primary : FeelitColors.textTertiary
    }

    private var isNearBottom: Bool {
        guard !comments.isEmpty else { return true }
        let offsetY = tableView.contentOffset.y + tableView.bounds.height
        return offsetY >= tableView.contentSize.height - 80
    }

    private func scrollToBottom(animated: Bool) {
        guard !comments.isEmpty else { return }
        let last = IndexPath(row: comments.count - 1, section: 0)
        tableView.scrollToRow(at: last, at: .bottom, animated: animated)
    }

    @objc private func dismissTapped() { dismiss(animated: true) }

    // MARK: Keyboard
    private func registerKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let hiding = note.name == UIResponder.keyboardWillHideNotification
        inputBottomConstraint.constant = hiding ? 0 : -(frame.height - view.safeAreaInsets.bottom)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}

// MARK: - UITableViewDataSource / Delegate
extension CommentViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { comments.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseId, for: indexPath) as! CommentCell
        let comment = comments[indexPath.row]
        let grouped = indexPath.row > 0 && comments[indexPath.row - 1].userId == comment.userId
        cell.configure(with: comment, groupedWithPrevious: grouped)
        return cell
    }
}

// MARK: - UITextFieldDelegate
extension CommentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return false
    }
}

// MARK: - CommentSocketDelegate
extension CommentViewController: CommentSocketDelegate {
    func didReceiveNewComment(_ comment: Comment, commentCount: Int) {
        guard comment.postId == postId else { return }
        self.commentCount = commentCount
        updateTitle()
        appendCommentIfNeeded(comment)
    }
}
