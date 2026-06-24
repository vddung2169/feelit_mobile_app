import UIKit

// MARK: - ExploreViewController
/// Tab 2 — Explore: search bar + category chips + trending assets (grid 2 cột) + top investors.
final class ExploreViewController: UIViewController {

    private enum Section: Int, CaseIterable { case categories, assets, investors }

    private let viewModel = ExploreViewModel()
    private var categories: [String] { viewModel.categories }
    private var selectedCategory: Int { viewModel.selectedCategory }
    private var assets: [FEAsset] { viewModel.assets }
    private var investors: [FEInvestor] { viewModel.investors }

    // Search bar
    private let searchContainer = UIView()
    private let searchField = UITextField()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = FeelitColors.background
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInset.bottom = FeelitLayout.scrollBottomInset
        cv.showsVerticalScrollIndicator = false
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        setupSearch()
        setupCollectionView()
    }

    // MARK: Search
    private func setupSearch() {
        searchContainer.backgroundColor = FeelitColors.surfaceElevated
        searchContainer.layer.cornerRadius = Radius.button
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchContainer)

        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = FeelitColors.textSecondary
        icon.translatesAutoresizingMaskIntoConstraints = false

        searchField.attributedPlaceholder = NSAttributedString(
            string: "Tìm cổ phiếu, nhà đầu tư...",
            attributes: [.foregroundColor: FeelitColors.textTertiary])
        searchField.textColor = FeelitColors.textPrimary
        searchField.font = FeelitFonts.body
        searchField.translatesAutoresizingMaskIntoConstraints = false

        searchContainer.addSubview(icon)
        searchContainer.addSubview(searchField)
        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.lg),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.lg),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.lg),
            searchContainer.heightAnchor.constraint(equalToConstant: 48),

            icon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: Spacing.md),
            icon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            searchField.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: Spacing.sm),
            searchField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -Spacing.md),
            searchField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
        ])
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: Spacing.md),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CategoryChipCell.self, forCellWithReuseIdentifier: CategoryChipCell.reuseId)
        collectionView.register(AssetCard.self, forCellWithReuseIdentifier: AssetCard.reuseId)
        collectionView.register(InvestorCard.self, forCellWithReuseIdentifier: InvestorCard.reuseId)
        collectionView.register(SectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SectionHeaderView.reuseId)
    }

    // MARK: Layout
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] index, _ in
            switch Section(rawValue: index)! {
            case .categories: return self?.categoriesSection()
            case .assets:     return self?.assetsSection()
            case .investors:  return self?.investorsSection()
            }
        }
    }

    private func categoriesSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .estimated(90), heightDimension: .absolute(36)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
            widthDimension: .estimated(90), heightDimension: .absolute(36)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Spacing.sm
        section.contentInsets = .init(top: 0, leading: Spacing.lg, bottom: Spacing.xl, trailing: Spacing.lg)
        return section
    }

    private func assetsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(150)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
            widthDimension: .fractionalWidth(1), heightDimension: .absolute(150)), subitems: [item, item])
        group.interItemSpacing = .fixed(Spacing.md)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Spacing.md
        section.contentInsets = .init(top: 0, leading: Spacing.lg, bottom: Spacing.xl, trailing: Spacing.lg)
        section.boundarySupplementaryItems = [header()]
        return section
    }

    private func investorsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .absolute(120), heightDimension: .absolute(160)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
            widthDimension: .absolute(120), heightDimension: .absolute(160)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
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
extension ExploreViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { Section.allCases.count }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .categories: return categories.count
        case .assets:     return assets.count
        case .investors:  return investors.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .categories:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryChipCell.reuseId, for: indexPath) as! CategoryChipCell
            cell.configure(title: categories[indexPath.item], selected: indexPath.item == selectedCategory)
            return cell
        case .assets:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCard.reuseId, for: indexPath) as! AssetCard
            cell.configure(with: assets[indexPath.item])
            return cell
        case .investors:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InvestorCard.reuseId, for: indexPath) as! InvestorCard
            cell.configure(with: investors[indexPath.item])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: SectionHeaderView.reuseId, for: indexPath) as! SectionHeaderView
        switch Section(rawValue: indexPath.section)! {
        case .assets:    header.configure(title: "📊 Trending Assets", showAction: true)
        case .investors: header.configure(title: "👑 Top Investors", showAction: true)
        default:         header.configure(title: "", showAction: false)
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard Section(rawValue: indexPath.section) == .categories else { return }
        let previous = viewModel.selectedCategory
        viewModel.selectCategory(indexPath.item)
        collectionView.reloadItems(at: [indexPath, IndexPath(item: previous, section: 0)])
    }
}
