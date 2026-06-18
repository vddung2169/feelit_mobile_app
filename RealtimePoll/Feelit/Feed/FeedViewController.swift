import UIKit
import Combine

// MARK: - FeedViewController
/// Tab 1 — Feed: Market Pulse header + Trending polls (horizontal) + Feed posts (vertical).
final class FeedViewController: UIViewController {

    private enum Section: Int, CaseIterable { case pulse, trending, posts }

    private let polls = FEMock.polls   // "Đang Hot" — mock tĩnh (không qua ViewModel)
    private let viewModel = FeedViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var posts: [FEPost] { viewModel.posts }   // nguồn: ViewModel (GET /api/posts)

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = FeelitColors.background
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInset.bottom = FeelitLayout.scrollBottomInset
        cv.showsVerticalScrollIndicator = false
        return cv
    }()

    private let refreshLogo = UILabel()
    private let refreshControl = UIRefreshControl()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        navigationItem.title = "FEELIT"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain, target: self, action: #selector(createPollTapped))
        setupBell()
        setupCollectionView()
        setupRefresh()
        bindViewModel()
        viewModel.loadFeed()

        NotificationCenter.default.addObserver(
            self, selector: #selector(updateBellBadge),
            name: .feelitUnreadDidChange, object: nil)
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.$posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.collectionView.reloadSections(IndexSet(integer: Section.posts.rawValue))
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCoordinator.shared.refreshUnread()
        updateBellBadge()
    }

    // MARK: - Notification bell
    private let bellButton = UIButton(type: .system)
    private let bellBadge = UILabel()

    private func setupBell() {
        bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
        bellButton.tintColor = FeelitColors.textPrimary
        bellButton.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        bellButton.addTarget(self, action: #selector(bellTapped), for: .touchUpInside)

        bellBadge.backgroundColor = FeelitColors.bearish
        bellBadge.textColor = .white
        bellBadge.font = .systemFont(ofSize: 10, weight: .bold)
        bellBadge.textAlignment = .center
        bellBadge.layer.cornerRadius = 8
        bellBadge.clipsToBounds = true
        bellBadge.isHidden = true
        bellBadge.translatesAutoresizingMaskIntoConstraints = false
        bellButton.addSubview(bellBadge)
        NSLayoutConstraint.activate([
            bellBadge.centerXAnchor.constraint(equalTo: bellButton.trailingAnchor, constant: -4),
            bellBadge.centerYAnchor.constraint(equalTo: bellButton.topAnchor, constant: 4),
            bellBadge.heightAnchor.constraint(equalToConstant: 16),
            bellBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
        ])

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: bellButton)
        updateBellBadge()
    }

    @objc private func updateBellBadge() {
        let count = NotificationCoordinator.shared.unreadCount
        bellBadge.isHidden = count == 0
        bellBadge.text = count > 99 ? "99+" : "\(count)"
    }

    @objc private func bellTapped() {
        navigationController?.pushViewController(NotificationsViewController(), animated: true)
    }

    // MARK: - Create poll (giống code cũ, mặc định 1 phút)
    @objc private func createPollTapped() {
        let alert = UIAlertController(title: "Tạo Poll Mới",
                                     message: "Nhập câu hỏi. Poll kéo dài 1 phút.",
                                     preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "VD: VN-INDEX sẽ tăng hôm nay?"
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
        navigationItem.rightBarButtonItem?.isEnabled = false
        APIClient.shared.createPoll(title: title, durationSeconds: 60) { [weak self] result in
            DispatchQueue.main.async {
                self?.navigationItem.rightBarButtonItem?.isEnabled = true
                switch result {
                case .success(let poll):
                    // Tạo xong → join vào xem vote luôn.
                    let vc = PollViewController(poll: poll)
                    vc.hidesBottomBarWhenPushed = true   // ẩn floating tab bar khi xem poll
                    self?.navigationController?.pushViewController(vc, animated: true)
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ msg: String) {
        let a = UIAlertController(title: "Lỗi", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MarketPulseCell.self, forCellWithReuseIdentifier: MarketPulseCell.reuseId)
        collectionView.register(PollCard.self, forCellWithReuseIdentifier: PollCard.reuseId)
        collectionView.register(PostCard.self, forCellWithReuseIdentifier: PostCard.reuseId)
        collectionView.register(SectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SectionHeaderView.reuseId)
    }

    // MARK: Pull to refresh — logo rotate
    private func setupRefresh() {
        refreshLogo.text = "📈"
        refreshLogo.font = .systemFont(ofSize: 24)
        refreshLogo.translatesAutoresizingMaskIntoConstraints = false
        refreshControl.tintColor = .clear
        refreshControl.addSubview(refreshLogo)
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        NSLayoutConstraint.activate([
            refreshLogo.centerXAnchor.constraint(equalTo: refreshControl.centerXAnchor),
            refreshLogo.centerYAnchor.constraint(equalTo: refreshControl.centerYAnchor),
        ])
    }

    @objc private func handleRefresh() {
        let spin = CABasicAnimation(keyPath: "transform.rotation")
        spin.toValue = 2 * Double.pi
        spin.duration = 0.8
        spin.repeatCount = .infinity
        refreshLogo.layer.add(spin, forKey: "spin")

        viewModel.loadFeed { [weak self] in
            self?.refreshLogo.layer.removeAnimation(forKey: "spin")
            self?.refreshControl.endRefreshing()
        }
    }

    // MARK: Compositional Layout
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] index, _ in
            guard let section = Section(rawValue: index) else { return nil }
            switch section {
            case .pulse:    return self?.pulseSection()
            case .trending: return self?.trendingSection()
            case .posts:    return self?.postsSection()
            }
        }
    }

    private func pulseSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1), heightDimension: .estimated(220)))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
            widthDimension: .fractionalWidth(1), heightDimension: .estimated(220)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: Spacing.lg, leading: Spacing.lg, bottom: Spacing.xl, trailing: Spacing.lg)
        return section
    }

    private func trendingSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .absolute(200), heightDimension: .absolute(240)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
            widthDimension: .absolute(200), heightDimension: .absolute(240)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Spacing.md
        section.contentInsets = .init(top: 0, leading: Spacing.lg, bottom: Spacing.xl, trailing: Spacing.lg)
        section.boundarySupplementaryItems = [header()]
        return section
    }

    private func postsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1), heightDimension: .estimated(280)))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
            widthDimension: .fractionalWidth(1), heightDimension: .estimated(280)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Spacing.md
        section.contentInsets = .init(top: 0, leading: Spacing.lg, bottom: Spacing.xl, trailing: Spacing.lg)
        section.boundarySupplementaryItems = [header()]
        return section
    }

    private func header() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44)),
            elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
    }
}

// MARK: - DataSource & Delegate
extension FeedViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { Section.allCases.count }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .pulse:    return 1
        case .trending: return polls.count
        case .posts:    return posts.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .pulse:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MarketPulseCell.reuseId, for: indexPath) as! MarketPulseCell
            cell.configure(bullishPercent: FEMock.marketPulseBullish, voters: FEMock.marketPulseVoters)
            return cell
        case .trending:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PollCard.reuseId, for: indexPath) as! PollCard
            cell.configure(with: polls[indexPath.item])
            return cell
        case .posts:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostCard.reuseId, for: indexPath) as! PostCard
            cell.configure(with: posts[indexPath.item])
            cell.delegate = self
            cell.onNeedsLayout = { [weak collectionView] in
                collectionView?.collectionViewLayout.invalidateLayout()
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: SectionHeaderView.reuseId, for: indexPath) as! SectionHeaderView
        switch Section(rawValue: indexPath.section)! {
        case .trending: header.configure(title: "🔥 Đang Hot", showAction: true)
        case .posts:    header.configure(title: "📰 Nhận định mới", showAction: false)
        default:        header.configure(title: "", showAction: false)
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard Section(rawValue: indexPath.section) == .trending else { return }
        let modal = VoteModal(poll: polls[indexPath.item])
        modal.modalPresentationStyle = .overFullScreen
        present(modal, animated: false)
    }
}

// MARK: - PostCardDelegate
extension FeedViewController: PostCardDelegate {

    func postCard(_ cell: PostCard, didTapComment postId: String, postTitle: String, commentCount: Int) {
        let vc = CommentViewController(postId: postId, postTitle: postTitle, initialCommentCount: commentCount)
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = false   // tự vẽ handle bar
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(vc, animated: true)
    }

    func postCard(_ cell: PostCard, didTapLike postId: String) {
        // Optimistic UI ở cell; ViewModel gọi API + đồng bộ/revert (revert → reload section).
        viewModel.likePost(postId: postId)
    }
}
