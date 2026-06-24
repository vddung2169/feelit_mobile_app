import UIKit

// MARK: - SharePollViewController
/// Sheet chọn người nhận để share 1 poll vào chat (giống "Gửi tới..." của FB).
/// Gửi message poll-share qua API messages hiện có → recipient nhận realtime + lưu lịch sử.
final class SharePollViewController: UIViewController {

    private let viewModel: SharePollViewModel
    private var recipients: [String] { viewModel.recipients }

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()

    private let previewLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(poll: Poll) {
        self.viewModel = SharePollViewModel(poll: poll)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Chia sẻ poll"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))

        setupLayout()

        previewLabel.text = viewModel.previewText

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "contact")
    }

    private func setupLayout() {
        view.addSubview(previewLabel)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            previewLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            previewLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    private func share(to recipient: String) {
        view.isUserInteractionEnabled = false
        viewModel.share(to: recipient) { [weak self] result in
            guard let self = self else { return }
            self.view.isUserInteractionEnabled = true
            switch result {
            case .success:
                self.dismiss(animated: true)
            case .failure(let error):
                self.showError(error.localizedDescription)
            }
        }
    }

    private func showError(_ msg: String) {
        let a = UIAlertController(title: "Lỗi", message: "Không gửi được: \(msg)", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - DataSource & Delegate
extension SharePollViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Gửi tới"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recipients.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contact", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = recipients[indexPath.row]
        config.image = UIImage(systemName: "person.crop.circle.fill")
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        share(to: recipients[indexPath.row])
    }
}
