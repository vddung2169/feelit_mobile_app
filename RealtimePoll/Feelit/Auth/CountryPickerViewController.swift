import UIKit

// MARK: - CountryPickerViewController
/// Danh sách quốc gia (cờ + tên + mã vùng) có tìm kiếm. Chọn → gọi `onSelect`.
final class CountryPickerViewController: UIViewController {

    var onSelect: ((Country) -> Void)?

    private let all = Countries.all.sorted { $0.name < $1.name }
    private var filtered: [Country] = []

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = AuthTheme.background
        title = "Chọn quốc gia"
        filtered = all

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem?.tintColor = AuthTheme.textPrimary

        searchBar.placeholder = "Tìm quốc gia"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = 56
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func close() { dismiss(animated: true) }
}

// MARK: - Search
extension CountryPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        filtered = q.isEmpty ? all : all.filter {
            $0.name.lowercased().contains(q) || $0.dialCode.contains(q) || $0.iso.lowercased().contains(q)
        }
        tableView.reloadData()
    }
}

// MARK: - Table
extension CountryPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = filtered[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = "\(c.flag)  \(c.name)"
        config.textProperties.color = AuthTheme.textPrimary
        config.textProperties.font = .systemFont(ofSize: 16, weight: .regular)
        config.secondaryText = c.dialCode
        config.secondaryTextProperties.color = AuthTheme.textSecondary
        config.prefersSideBySideTextAndSecondaryText = true
        cell.contentConfiguration = config
        cell.backgroundColor = .clear
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = filtered[indexPath.row]
        dismiss(animated: true) { [weak self] in self?.onSelect?(country) }
    }
}
