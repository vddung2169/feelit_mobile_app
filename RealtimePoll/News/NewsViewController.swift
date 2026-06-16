import UIKit

/// Tab "News" — feed flash cards kiểu Locket.
/// Vuốt lên để hiện card mới. Data 6 card fix sẵn, chưa gọi backend.
final class NewsViewController: UIViewController {

    private let cards = NewsSampleData.cards
    /// Lựa chọn đã vote cho từng card (item index -> option index). Giữ lại khi cuộn.
    private var votes: [Int: Int] = [:]

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .black
        cv.contentInsetAdjustmentBehavior = .never
        cv.register(NewsCardCell.self, forCellWithReuseIdentifier: NewsCardCell.id)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    /// Gợi ý "vuốt lên" hiện trên card đầu, ẩn khi người dùng đã cuộn.
    private let swipeHint: UILabel = {
        let l = UILabel()
        l.text = "↑  Vuốt lên xem tiếp"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = UIColor(white: 1, alpha: 0.6)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        view.addSubview(swipeHint)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            swipeHint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            swipeHint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Feed immersive — ẩn nav bar trong tab này.
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}

// MARK: - Data source & layout
extension NewsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cards.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NewsCardCell.id, for: indexPath) as! NewsCardCell
        let item = indexPath.item
        cell.configure(with: cards[item], selectedIndex: votes[item]) { [weak self] optionIndex in
            self?.votes[item] = optionIndex
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 20, swipeHint.alpha > 0 {
            UIView.animate(withDuration: 0.2) { self.swipeHint.alpha = 0 }
        }
    }
}
