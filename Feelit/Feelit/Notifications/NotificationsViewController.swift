import UIKit
import Combine

// MARK: - NotificationsViewController
/// Màn hình danh sách thông báo (View). Tải/đánh dấu đọc nằm trong `NotificationsViewModel`.
final class NotificationsViewController: UIViewController {

    private let viewModel = NotificationsViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var items: [AppNotification] { viewModel.items }

    private let tableView = UITableView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        title = "Thông báo"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Đọc hết", style: .plain, target: self, action: #selector(markAllTapped))
        setupTable()
        setupSpinner()
        setupEmpty()
        bindViewModel()
        viewModel.load()
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                loading ? self?.spinner.startAnimating() : self?.spinner.stopAnimating()
                self?.updateEmptyState()
            }
            .store(in: &cancellables)
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = viewModel.isLoading || !items.isEmpty
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

    @objc private func markAllTapped() {
        viewModel.markAllRead()
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
        if let pollId = viewModel.didTap(items[indexPath.row]) {
            NotificationCoordinator.shared.openPoll(pollId: pollId)
        }
    }
}
