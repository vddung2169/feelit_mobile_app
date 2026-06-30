import UIKit

// MARK: - PollFeedViewController
/// Tab "Poll" — feed thẻ poll full-screen, lướt dọc (Figma 219-5411).
/// Header: chip chủ đề + ô tìm kiếm. Bấm thẻ → màn chi tiết.
final class PollFeedViewController: UIViewController {

    private let viewModel = PollFeedViewModel()
    private var categories: [String] { viewModel.categories }
    private var selectedCategory: String { viewModel.selectedCategory }
    private var items: [PollCardItem] { viewModel.items }
    private var savedItemIds: Set<String> = []

    private let chipsScroll = UIScrollView()
    private let chipsStack = UIStackView()
    private var chipButtons: [UIButton] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = Theme.page
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(PollCardCell.self, forCellWithReuseIdentifier: PollCardCell.reuseId)
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupHeader()
        setupCollection()
    }

    // MARK: Header
    private func setupHeader() {
        chipsScroll.showsHorizontalScrollIndicator = false
        chipsScroll.translatesAutoresizingMaskIntoConstraints = false
        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsStack.translatesAutoresizingMaskIntoConstraints = false
        chipsScroll.addSubview(chipsStack)

        for (i, c) in categories.enumerated() {
            let idx = i
            let b = CategoryChip.make(title: c, selected: c == selectedCategory, icon: chipIcon(c),
                action: UIAction { [weak self] _ in self?.selectCategory(idx) })
            b.tag = i
            chipButtons.append(b)
            chipsStack.addArrangedSubview(b)
        }

        // Icon bảng xếp hạng (trái) + icon tìm kiếm (phải) trên cùng một hàng với chip.
        let leaderboardBtn = headerIcon("chart.bar.fill")
        leaderboardBtn.addAction(UIAction { [weak self] _ in
            self?.navigationController?.pushViewController(LeaderboardViewController(), animated: true)
        }, for: .touchUpInside)
        let searchBtn = headerIcon("magnifyingglass")

        view.addSubview(leaderboardBtn)
        view.addSubview(searchBtn)
        view.addSubview(chipsScroll)
        NSLayoutConstraint.activate([
            leaderboardBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            leaderboardBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            leaderboardBtn.heightAnchor.constraint(equalToConstant: 36),
            leaderboardBtn.widthAnchor.constraint(equalToConstant: 30),

            searchBtn.centerYAnchor.constraint(equalTo: leaderboardBtn.centerYAnchor),
            searchBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBtn.widthAnchor.constraint(equalToConstant: 30),

            chipsScroll.topAnchor.constraint(equalTo: leaderboardBtn.topAnchor),
            chipsScroll.leadingAnchor.constraint(equalTo: leaderboardBtn.trailingAnchor, constant: 8),
            chipsScroll.trailingAnchor.constraint(equalTo: searchBtn.leadingAnchor, constant: -8),
            chipsScroll.heightAnchor.constraint(equalToConstant: 36),

            chipsStack.topAnchor.constraint(equalTo: chipsScroll.topAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScroll.bottomAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScroll.leadingAnchor),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScroll.trailingAnchor),
            chipsStack.heightAnchor.constraint(equalTo: chipsScroll.heightAnchor),
        ])
        updateChipStyles()
    }

    private func chipIcon(_ category: String) -> String? {
        category == "Xu hướng" ? "arrow.up.right" : nil
    }

    private func headerIcon(_ name: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: name,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)), for: .normal)
        b.tintColor = Theme.textPrimary
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setContentHuggingPriority(.required, for: .horizontal)
        return b
    }

    private func setupCollection() {
        view.addSubview(collectionView)
        view.sendSubviewToBack(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: chipsScroll.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: Category
    private func selectCategory(_ index: Int) {
        viewModel.selectCategory(index)
        updateChipStyles()
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }

    private func updateChipStyles() {
        for (i, b) in chipButtons.enumerated() {
            let cat = categories[i]
            CategoryChip.update(b, title: cat, selected: cat == selectedCategory, icon: chipIcon(cat))
        }
    }

}

// MARK: - DataSource / Delegate
extension PollFeedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PollCardCellDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PollCardCell.reuseId, for: indexPath) as! PollCardCell
        let item = items[indexPath.item]
        cell.configure(with: item, isSaved: savedItemIds.contains(item.id))
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func pollCardDidSelect(_ item: PollCardItem) {
        let vc = PollDetailViewController(item: item)
        navigationController?.pushViewController(vc, animated: true)
    }

    func pollCardDidTapComment(_ item: PollCardItem) {
        let vc = CommentsOverlayViewController(item: item)
        if let sheet = vc.sheetPresentationController {
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom { $0.maximumDetentValue * 0.85 }]
            } else {
                sheet.detents = [.large()]
            }
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }

    func pollCardDidTapShare(_ item: PollCardItem, from cell: PollCardCell) {
        // Link mẫu tạm thời tới poll.
        let link = URL(string: "https://feelit.vn/poll/\(item.id)")!
        let activity = UIActivityViewController(
            activityItems: [item.title, link], applicationActivities: nil)
        // iPad: neo popover vào cell.
        activity.popoverPresentationController?.sourceView = cell
        activity.popoverPresentationController?.sourceRect = cell.bounds
        present(activity, animated: true)
    }

    func pollCardDidToggleSave(_ item: PollCardItem, saved: Bool) {
        if saved { savedItemIds.insert(item.id) } else { savedItemIds.remove(item.id) }
    }
}
