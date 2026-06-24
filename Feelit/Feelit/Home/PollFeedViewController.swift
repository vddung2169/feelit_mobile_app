import UIKit

// MARK: - PollFeedViewController
/// Tab "Poll" — feed thẻ poll full-screen, lướt dọc (Figma 219-5411).
/// Header: chip chủ đề + ô tìm kiếm. Bấm thẻ → màn chi tiết.
final class PollFeedViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private let viewModel = PollFeedViewModel()
    private var categories: [String] { viewModel.categories }
    private var selectedCategory: String { viewModel.selectedCategory }
    private var items: [PollCardItem] { viewModel.items }
    private var savedItemIds: Set<String> = []

    private let chipsScroll = UIScrollView()
    private let chipsStack = UIStackView()
    private var chipButtons: [UIButton] = []

    private let searchField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = FeelitColors.surfaceElevated
        tf.layer.cornerRadius = 12
        tf.font = .systemFont(ofSize: 14, weight: .regular)
        tf.textColor = FeelitColors.textPrimary
        tf.attributedPlaceholder = NSAttributedString(string: "Tìm kiếm...",
            attributes: [.foregroundColor: FeelitColors.textPrimary.withAlphaComponent(0.6)])
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = FeelitColors.textPrimary.withAlphaComponent(0.6)
        let left = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 44))
        icon.frame = CGRect(x: 12, y: 12, width: 20, height: 20)
        left.addSubview(icon)
        tf.leftView = left
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = FeelitColors.background
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
        view.backgroundColor = FeelitColors.background
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
            var config = UIButton.Configuration.plain()
            config.attributedTitle = AttributedString(c, attributes:
                AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .regular)]))
            config.baseForegroundColor = FeelitColors.textPrimary
            config.contentInsets = .init(top: 6, leading: 14, bottom: 6, trailing: 14)
            let b = UIButton(configuration: config)
            b.tag = i
            b.layer.cornerRadius = 8
            b.clipsToBounds = true
            b.addAction(UIAction { [weak self] _ in self?.selectCategory(i) }, for: .touchUpInside)
            chipButtons.append(b)
            chipsStack.addArrangedSubview(b)
        }

        view.addSubview(chipsScroll)
        view.addSubview(searchField)
        NSLayoutConstraint.activate([
            chipsScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            chipsScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipsScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chipsScroll.heightAnchor.constraint(equalToConstant: 36),

            chipsStack.topAnchor.constraint(equalTo: chipsScroll.topAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScroll.bottomAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScroll.leadingAnchor, constant: 16),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScroll.trailingAnchor, constant: -16),
            chipsStack.heightAnchor.constraint(equalTo: chipsScroll.heightAnchor),

            searchField.topAnchor.constraint(equalTo: chipsScroll.bottomAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 44),
        ])
        updateChipStyles()
    }

    private func setupCollection() {
        view.addSubview(collectionView)
        view.sendSubviewToBack(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
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
            b.backgroundColor = categories[i] == selectedCategory ? UIColor(hex: 0x292929) : .clear
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
