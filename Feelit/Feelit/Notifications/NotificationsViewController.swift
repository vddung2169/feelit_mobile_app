import UIKit

// MARK: - NotificationsViewController
/// Màn hình danh sách thông báo (hàng đợi in-app). Tap item → đọc + mở poll.
final class NotificationsViewController: UIViewController {

    private var items: [AppNotification] = []
    private let tableView = UITableView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let emptyLabel = UILabel()

    private var userId: String { NotificationCoordinator.shared.currentUserId }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        title = "Thông báo"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Đọc hết", style: .plain, target: self, action: #selector(markAllTapped))
        setupTable()
        setupSpinner()
        setupEmpty()
        load()
    }

    private func setupTable() {
        tableView.backgroundColor = FeelitColors.background
        tableView.separatorColor = FeelitColors.border
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupSpinner() {
        spinner.color = FeelitColors.textSecondary
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupEmpty() {
        emptyLabel.text = "🔔\nChưa có thông báo nào"
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = FeelitFonts.body
        emptyLabel.textColor = FeelitColors.textSecondary
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    private func load() {
        spinner.startAnimating()
        APIClient.shared.getNotifications(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.spinner.stopAnimating()
                switch result {
                case .success(let res):
                    self.items = res.notifications
                    NotificationCoordinator.shared.setUnread(res.unreadCount)
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = !res.notifications.isEmpty
                case .failure(let error):
                    print("⚠️ getNotifications failed: \(error)")
                    self.emptyLabel.isHidden = !self.items.isEmpty
                }
            }
        }
    }

    @objc private func markAllTapped() {
        APIClient.shared.markAllNotificationsRead(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, case .success(let res) = result else { return }
                NotificationCoordinator.shared.setUnread(res.unreadCount)
                self.items = self.items.map {
                    AppNotification(id: $0.id, userId: $0.userId, type: $0.type, title: $0.title,
                                    body: $0.body, data: $0.data, pollId: $0.pollId,
                                    isRead: true, createdAt: $0.createdAt)
                }
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - DataSource / Delegate
extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.reuseId, for: indexPath) as! NotificationCell
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]

        if !item.isRead {
            APIClient.shared.markNotificationRead(notificationId: item.id) { _ in }
            NotificationCoordinator.shared.setUnread(max(0, NotificationCoordinator.shared.unreadCount - 1))
        }
        if let pollId = item.resolvedPollId {
            NotificationCoordinator.shared.openPoll(pollId: pollId)
        }
    }
}
