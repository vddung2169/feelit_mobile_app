import UIKit

// MARK: - LiveViewController
/// Tab "Live" (Figma 481-24109 "Live | Default"): danh sách thẻ poll gọn — mỗi thẻ
/// gồm tag + số người tham gia, mã tài sản + tiêu đề, hai chỉ số giá, nút Tăng/Giảm.
/// Bấm thẻ → mở màn chi tiết (Figma 481-24129) với nút bình chọn tông nhạt.
final class LiveViewController: UIViewController {

    private let categories = PollFeedData.categories
    private var selectedCategory = PollFeedData.categories.first ?? "Xu hướng"
    private var items: [PollCardItem] {
        // "Xu hướng" = tất cả; còn lại lọc theo danh mục.
        selectedCategory == categories.first
            ? PollFeedData.items
            : PollFeedData.items.filter { $0.category == selectedCategory }
    }

    private let chipsScroll = UIScrollView()
    private let chipsStack = UIStackView()
    private var chipButtons: [UIButton] = []

    private let scroll = UIScrollView()
    private let list = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupHeader()
        setupList()
        reload()
    }

    // MARK: Header (chip danh mục + tìm kiếm) — giống màn Poll: chip Liquid Glass + icon tìm kiếm
    private func setupHeader() {
        chipsScroll.showsHorizontalScrollIndicator = false
        chipsScroll.translatesAutoresizingMaskIntoConstraints = false
        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsStack.translatesAutoresizingMaskIntoConstraints = false
        chipsScroll.addSubview(chipsStack)

        for (i, c) in categories.enumerated() {
            let idx = i
            // Chip Liquid Glass (iOS 26+) như màn Poll; "Xu hướng" có icon mũi tên xu hướng.
            let b = CategoryChip.make(title: c, selected: c == selectedCategory, icon: chipIcon(c),
                action: UIAction { [weak self] _ in self?.selectCategory(idx) })
            b.tag = i
            chipButtons.append(b)
            chipsStack.addArrangedSubview(b)
        }

        let search = UIButton(type: .system)
        search.setImage(UIImage(systemName: "magnifyingglass",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)), for: .normal)
        search.tintColor = Theme.textPrimary
        search.translatesAutoresizingMaskIntoConstraints = false
        search.setContentHuggingPriority(.required, for: .horizontal)

        view.addSubview(chipsScroll)
        view.addSubview(search)
        NSLayoutConstraint.activate([
            chipsScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            chipsScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chipsScroll.heightAnchor.constraint(equalToConstant: 36),

            search.centerYAnchor.constraint(equalTo: chipsScroll.centerYAnchor),
            search.leadingAnchor.constraint(equalTo: chipsScroll.trailingAnchor, constant: 8),
            search.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            search.widthAnchor.constraint(equalToConstant: 28),

            chipsStack.topAnchor.constraint(equalTo: chipsScroll.topAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScroll.bottomAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScroll.leadingAnchor, constant: 16),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScroll.trailingAnchor, constant: -16),
            chipsStack.heightAnchor.constraint(equalTo: chipsScroll.heightAnchor),
        ])
        updateChipStyles()
    }

    private func chipIcon(_ category: String) -> String? {
        category == "Xu hướng" ? "arrow.up.right" : nil
    }

    private func setupList() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInset.bottom = 100
        view.addSubview(scroll)

        list.axis = .vertical
        list.spacing = 16
        list.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(list)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: chipsScroll.bottomAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            list.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            list.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            list.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            list.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        ])
    }

    private func reload() {
        list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in items {
            let card = LivePollCardView(item: item) { [weak self] in self?.open(item) }
            list.addArrangedSubview(card)
        }
    }

    private func open(_ item: PollCardItem) {
        navigationController?.pushViewController(
            PollDetailViewController(item: item, softVoteButtons: true), animated: true)
    }

    // MARK: Category
    private func selectCategory(_ index: Int) {
        selectedCategory = categories[index]
        updateChipStyles()
        reload()
        scroll.setContentOffset(.zero, animated: false)
    }

    private func updateChipStyles() {
        for (i, b) in chipButtons.enumerated() {
            let cat = categories[i]
            CategoryChip.update(b, title: cat, selected: cat == selectedCategory, icon: chipIcon(cat))
        }
    }
}

// MARK: - LivePollCardView
/// Thẻ poll gọn cho tab Live (Figma "Mention" 481-24109): nền #F7F7F7, viền #CCCCCC.
final class LivePollCardView: ThemeCardView {

    private let onTap: () -> Void

    init(item: PollCardItem, onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.card
        layer.cornerRadius = 12
        layer.borderWidth = 1
        borderUIColor = Theme.borderStrong

        // Hàng tag + số người tham gia
        let tag = makeLabel("\(item.category) · \(item.cadence)", 12, .light, 0x202020)
        let peopleIcon = UIImageView(image: UIImage(systemName: "person.2.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)))
        peopleIcon.tintColor = Theme.textSecondary
        peopleIcon.setContentHuggingPriority(.required, for: .horizontal)
        let countLabel = makeLabel(compactCount(item.voters), 12, .regular, 0x818181)
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        let tagRow = UIStackView(arrangedSubviews: [tag, UIView(), peopleIcon, countLabel])
        tagRow.axis = .horizontal; tagRow.spacing = 4; tagRow.alignment = .center

        // Mã tài sản + tiêu đề
        let assetBadge = makeAssetBadge(item)
        let assetRow = UIStackView(arrangedSubviews: [assetBadge, UIView()])
        assetRow.axis = .horizontal; assetRow.alignment = .center
        let title = makeLabel(item.title, 15, .medium, 0x202020)
        title.numberOfLines = 2

        // Hai chỉ số
        let metrics = makeMetrics(item)

        // Nút Tăng / Giảm (tông nhạt)
        let up = votePill("Tăng", bg: 0x74FF7A, text: 0x4CAF50)
        let down = votePill("Giảm", bg: 0xEF5350, text: 0xF44336)
        let voteRow = UIStackView(arrangedSubviews: [up, down])
        voteRow.axis = .horizontal; voteRow.spacing = 10; voteRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [tagRow, assetRow, title, metrics, voteRow])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(6, after: assetRow)
        stack.setCustomSpacing(14, after: title)
        stack.setCustomSpacing(14, after: metrics)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        onTap()
        alpha = 0.7
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
    }

    // MARK: Builders
    private func makeAssetBadge(_ item: PollCardItem) -> UIView {
        let square = UILabel()
        square.text = item.assetEmoji
        square.font = .systemFont(ofSize: 11)
        square.textAlignment = .center
        square.backgroundColor = UIColor(hex: item.assetColor)
        square.layer.cornerRadius = 4
        square.clipsToBounds = true
        square.translatesAutoresizingMaskIntoConstraints = false
        square.widthAnchor.constraint(equalToConstant: 18).isActive = true
        square.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let sym = makeLabel(item.assetSymbol, 12, .medium, 0x202020)
        let row = UIStackView(arrangedSubviews: [square, sym])
        row.axis = .horizontal; row.spacing = 6; row.alignment = .center
        return row
    }

    private func makeMetrics(_ item: PollCardItem) -> UIView {
        let beat = metricColumn("Giá cần vượt", item.currentPrice, valueHex: 0x818181, badge: nil)
        let now = metricColumn("Giá hiện tại", item.marketPrice,
                               valueHex: item.isUp ? 0x4CAF50 : 0xF44336,
                               badge: (item.changePercent, item.isUp))
        let divider = UIView()
        divider.backgroundColor = Theme.borderStrong
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
        let row = UIStackView(arrangedSubviews: [beat, divider, now])
        row.axis = .horizontal; row.spacing = 14; row.alignment = .fill
        beat.widthAnchor.constraint(equalTo: now.widthAnchor).isActive = true
        return row
    }

    private func metricColumn(_ caption: String, _ value: String, valueHex: UInt32,
                              badge: (String, Bool)?) -> UIView {
        let cap = makeLabel(caption, 10, .light, 0x818181)
        let val = makeLabel(value, 15, .semibold, valueHex)
        val.setContentHuggingPriority(.required, for: .horizontal)
        let valueRow = UIStackView(arrangedSubviews: [val])
        valueRow.axis = .horizontal; valueRow.spacing = 6; valueRow.alignment = .center
        if let (pct, up) = badge {
            valueRow.addArrangedSubview(changeBadge(pct, up: up))
            valueRow.addArrangedSubview(UIView())
        }
        let col = UIStackView(arrangedSubviews: [cap, valueRow])
        col.axis = .vertical; col.spacing = 4; col.alignment = .leading
        return col
    }

    private func changeBadge(_ pct: String, up: Bool) -> UIView {
        let arrow = UIImageView(image: UIImage(systemName: up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 7, weight: .bold)))
        arrow.tintColor = UIColor(hex: up ? 0x4CAF50 : 0xF44336)
        let lbl = makeLabel(pct, 9, .semibold, up ? 0x4CAF50 : 0xF44336)
        let row = UIStackView(arrangedSubviews: [arrow, lbl])
        row.axis = .horizontal; row.spacing = 2; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 2, left: 5, bottom: 2, right: 5)
        row.backgroundColor = UIColor(hex: up ? 0x74FF7A : 0xEF5350, alpha: 0.35)
        row.layer.cornerRadius = 4
        row.clipsToBounds = true
        row.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func votePill(_ title: String, bg: UInt32, text: UInt32) -> UIView {
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = UIColor(hex: text)
        l.textAlignment = .center
        l.backgroundColor = UIColor(hex: bg, alpha: 0.15)
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return l
    }

    private func makeLabel(_ text: String, _ size: CGFloat, _ weight: UIFont.Weight, _ hex: UInt32) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = PollDetailViewController.adaptiveColor(hex)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    /// 19204 → "19.2k", 842 → "842".
    private func compactCount(_ n: Int) -> String {
        if n >= 1000 {
            let k = Double(n) / 1000
            return String(format: "%.1fk", k)
        }
        return "\(n)"
    }
}
