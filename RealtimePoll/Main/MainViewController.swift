import UIKit

final class MainViewController: UIViewController {

    // MARK: - Data
    private var polls: [Poll] = []

    // MARK: - UI
    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text = "🗳️"
        l.font = .systemFont(ofSize: 48)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Realtime Poll"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .label
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let createButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Create New Poll"
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .large
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.register(PollCell.self, forCellReuseIdentifier: PollCell.id)
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Chưa có poll nào.\nBấm 'Create New Poll' để tạo."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.hidesWhenStopped = true
        a.translatesAutoresizingMaskIntoConstraints = false
        return a
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPolls()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Realtime Poll"
        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubview(createButton)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(activityIndicator)

        tableView.delegate   = self
        tableView.dataSource = self

        NSLayoutConstraint.activate([
            createButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createButton.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(refreshTapped)
            )
    }

    private func setupActions() {
        createButton.addTarget(self, action: #selector(createPollTapped), for: .touchUpInside)
    }

    // MARK: - Load polls
    private func loadPolls() {
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true

        APIClient.shared.getPolls { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                switch result {
                case .success(let list):
                    self?.polls = list
                    self?.tableView.reloadData()
                    self?.emptyLabel.isHidden = !list.isEmpty
                case .failure:
                    self?.emptyLabel.text = "Không thể tải danh sách poll.\nKiểm tra server đang chạy chưa."
                    self?.emptyLabel.isHidden = false
                }
            }
        }
    }

    // MARK: - Actions
    private func loadPolls(completion: (() -> Void)? = nil) {
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true

        APIClient.shared.getPolls { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                completion?()
                switch result {
                case .success(let list):
                    self?.polls = list
                    self?.tableView.reloadData()
                    self?.emptyLabel.isHidden = !list.isEmpty
                case .failure:
                    self?.emptyLabel.text = "Không thể tải danh sách poll.\nKiểm tra server đang chạy chưa."
                    self?.emptyLabel.isHidden = false
                }
            }
        }
    }
    
    @objc private func refreshTapped() {
        let btn = navigationItem.rightBarButtonItem
        btn?.isEnabled = false
        loadPolls {
            DispatchQueue.main.async { btn?.isEnabled = true }
        }
    }
    
    @objc private func createPollTapped() {
        let alert = UIAlertController(title: "Tạo Poll Mới", message: "Nhập câu hỏi cho poll", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "VD: Should we ship the new feature?"
            tf.autocapitalizationType = .sentences
        }
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Tạo", style: .default) { [weak self, weak alert] _ in
            let title = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !title.isEmpty else { return }
            self?.createPoll(title: title)
        })
        present(alert, animated: true)
    }

    private func createPoll(title: String) {
        createButton.isEnabled = false
        APIClient.shared.createPoll(title: title) { [weak self] result in
            DispatchQueue.main.async {
                self?.createButton.isEnabled = true
                switch result {
                case .success(let poll):
                    self?.openPoll(poll)
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }

    private func openPoll(_ poll: Poll) {
        let vc = PollViewController(poll: poll)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showError(_ msg: String) {
        let a = UIAlertController(title: "Lỗi", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension MainViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return polls.filter { $0.status == "active" }.count }
        return polls.filter { $0.status != "active" }.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            let count = polls.filter { $0.status == "active" }.count
            return count > 0 ? "🟢 ĐANG ACTIVE" : nil
        }
        let count = polls.filter { $0.status != "active" }.count
        return count > 0 ? "✅ ĐÃ KẾT THÚC" : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PollCell.id, for: indexPath) as! PollCell
        let filtered = indexPath.section == 0
            ? polls.filter { $0.status == "active" }
            : polls.filter { $0.status != "active" }
        cell.configure(with: filtered[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 80 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let filtered = indexPath.section == 0
            ? polls.filter { $0.status == "active" }
            : polls.filter { $0.status != "active" }
        openPoll(filtered[indexPath.row])
    }
}

// MARK: - PollCell
final class PollCell: UITableViewCell {
    static let id = "PollCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statusBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        contentView.addSubview(titleLabel)
        contentView.addSubview(statsLabel)
        contentView.addSubview(statusBadge)
        NSLayoutConstraint.activate([
            statusBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            statusBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusBadge.widthAnchor.constraint(equalToConstant: 70),
            statusBadge.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: -8),

            statsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            statsLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statsLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with poll: Poll) {
        titleLabel.text = poll.title
        let total = poll.totalVotes
        if poll.status == "active" {
            statsLabel.text = "Yes: \(poll.yesCount)  No: \(poll.noCount)  |  \(total) votes"
            statusBadge.text = "● LIVE"
            statusBadge.textColor = .white
            statusBadge.backgroundColor = .systemGreen
        } else {
            let winnerText = poll.winner == "YES" ? "YES thắng" :
                             poll.winner == "NO"  ? "NO thắng"  :
                             poll.winner == "TIE" ? "Hoà" : "No result"
            statsLabel.text = "\(total) votes  |  \(winnerText)"
            statusBadge.text = "ENDED"
            statusBadge.textColor = .secondaryLabel
            statusBadge.backgroundColor = .systemGray5
        }
    }
}
