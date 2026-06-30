import UIKit

// MARK: - LeaderboardViewController
/// Bảng Xếp Hạng (Figma 732-22532): mở khi bấm icon bên trái header màn Poll.
/// Gồm bộ lọc, bục vinh danh top 3, danh sách xếp hạng và pill "Bạn #19".
/// Hỗ trợ cả light & dark mode qua bảng màu Theme.
final class LeaderboardViewController: UIViewController {

    private struct Podium { let name: String, pts: String; let rank: Int; let barHeight: CGFloat }
    // Thứ tự hiển thị trái → phải: hạng 2, hạng 1 (giữa, cao nhất), hạng 3.
    private let podium: [Podium] = [
        .init(name: "fin.enjoyer", pts: "40.1K", rank: 2, barHeight: 104),
        .init(name: "cryptoking",  pts: "48.2K", rank: 1, barHeight: 134),
        .init(name: "long.pham",   pts: "38.4K", rank: 3, barHeight: 84),
    ]

    private struct Player { let rank: Int, username: String, accuracy: String, votes: String, pts: String; let isMe: Bool }
    private let myRank = 19
    private lazy var players: [Player] = makePlayers()

    private func makePlayers() -> [Player] {
        let names = ["@nguyen.trades", "@lan.invest", "@minh.crypto", "@huy.stocks", "@trang.fx",
                     "@duc.gold", "@my.vnindex", "@quan.trader", "@thao.btc", "@long.eth",
                     "@vy.fund", "@nam.bull", "@linh.bear", "@phuc.dca", "@hoa.swing",
                     "@an.hodler", "@bao.margin", "@chi.option", "@dat.future", "@yen.forex",
                     "@son.index", "@tu.value", "@ngoc.growth", "@hai.momentum", "@khoa.signal",
                     "@vu.alpha", "@thu.beta"]
        return (4...30).map { r in
            let i = r - 4
            let isMe = r == myRank
            let pts = String(format: "%.1fK", max(2.0, 32.4 - Double(i) * 1.04))
            let acc = String(format: "%.1f%%", max(48.0, 78.4 - Double(i) * 0.95))
            let votes = "\(max(40, 264 - i * 8)) votes"
            return Player(rank: r, username: isMe ? "@ban_finence" : names[min(i, names.count - 1)],
                          accuracy: acc, votes: votes, pts: pts, isMe: isMe)
        }
    }

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private weak var meRow: UIView?
    private var youPill: UIView?
    private weak var youArrow: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupHeader()
        setupScroll()
        buildContent()
        setupYouPill()
    }

    // MARK: Header
    private func setupHeader() {
        let back = UIButton(type: .system)
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        c.imagePadding = 4
        c.attributedTitle = AttributedString("Trở lại", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .regular)]))
        c.baseForegroundColor = Theme.textPrimary
        c.contentInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        back.configuration = c
        back.translatesAutoresizingMaskIntoConstraints = false
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        let title = UILabel()
        title.text = "Bảng Xếp Hạng"
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        title.textColor = Theme.textPrimary
        title.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(back); view.addSubview(title)
        NSLayoutConstraint.activate([
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: back.centerYAnchor),
        ])
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.delegate = self
        scroll.contentInset.bottom = 150
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        ])
    }

    private func buildContent() {
        stack.addArrangedSubview(filterRow())
        stack.addArrangedSubview(podiumView())
        stack.addArrangedSubview(listCard())
    }

    // MARK: Filter
    private func filterRow() -> UIView {
        let time = dropdown("Hôm nay", options: ["Hôm nay", "Tuần này", "Tháng này", "Tất cả"])
        let cat = dropdown("Chứng khoán VN", options: PollFeedData.categories)
        let row = UIStackView(arrangedSubviews: [time, UIView(), cat])
        row.axis = .horizontal; row.alignment = .center
        return row
    }

    private func dropdown(_ title: String, options: [String]) -> UIButton {
        var c = UIButton.Configuration.plain()
        c.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 12, weight: .regular)]))
        c.image = UIImage(systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold))
        c.imagePlacement = .trailing
        c.imagePadding = 6
        c.baseForegroundColor = Theme.textPrimary
        c.background.backgroundColor = Theme.track
        c.background.cornerRadius = 8
        c.contentInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 10)
        let b = UIButton(configuration: c)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.menu = UIMenu(children: options.map { opt in
            UIAction(title: opt, state: opt == title ? .on : .off) { [weak b] _ in
                var cfg = b?.configuration
                cfg?.attributedTitle = AttributedString(opt, attributes:
                    AttributeContainer([.font: UIFont.systemFont(ofSize: 12, weight: .regular)]))
                b?.configuration = cfg
            }
        })
        b.showsMenuAsPrimaryAction = true
        return b
    }

    // MARK: Podium
    private func podiumView() -> UIView {
        let cols = podium.map { podiumColumn($0) }
        let row = UIStackView(arrangedSubviews: cols)
        row.axis = .horizontal; row.alignment = .bottom; row.distribution = .fillEqually; row.spacing = 10
        return row
    }

    private func podiumColumn(_ p: Podium) -> UIView {
        let avatar = IdeaUI.avatar(p.name, size: p.rank == 1 ? 56 : 48, corner: 12, fontSize: p.rank == 1 ? 22 : 18)
        let name = label(p.name, 12, .regular, Theme.textPrimary)
        name.textAlignment = .center
        let pts = label("\(p.pts) pts", 13, .semibold, Theme.green)
        pts.textAlignment = .center

        // Cột vinh danh: bar gradient xanh, bo trên, có số hạng.
        let bar = GradientView(colors: [Theme.voteUp.cgColor, Theme.green.cgColor],
                               start: CGPoint(x: 0.5, y: 0), end: CGPoint(x: 0.5, y: 1))
        bar.layer.cornerRadius = 12
        bar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bar.clipsToBounds = true
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.heightAnchor.constraint(equalToConstant: p.barHeight).isActive = true
        bar.widthAnchor.constraint(equalToConstant: 96).isActive = true
        let rankLabel = label("\(p.rank)", 22, .bold, .white)
        rankLabel.textAlignment = .center
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(rankLabel)
        NSLayoutConstraint.activate([
            rankLabel.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
            rankLabel.topAnchor.constraint(equalTo: bar.topAnchor, constant: 12),
        ])

        let col = UIStackView(arrangedSubviews: [avatar, name, pts, bar])
        col.axis = .vertical; col.spacing = 6; col.alignment = .center
        col.setCustomSpacing(10, after: pts)
        return col
    }

    // MARK: List
    private func listCard() -> UIView {
        var rows: [UIView] = []
        for (i, p) in players.enumerated() {
            let row = playerRow(p)
            if p.isMe { meRow = row }
            rows.append(row)
            if i < players.count - 1 { rows.append(divider()) }
        }
        let col = UIStackView(arrangedSubviews: rows)
        col.axis = .vertical; col.spacing = 0
        col.translatesAutoresizingMaskIntoConstraints = false
        let card = ThemeCardView()
        card.backgroundColor = Theme.card
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.borderUIColor = Theme.border
        card.addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: card.topAnchor),
            col.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            col.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            col.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])
        return card
    }

    private func playerRow(_ p: Player) -> UIView {
        let rank = label("\(p.rank)", 13, .regular, Theme.textSecondary)
        rank.textAlignment = .center
        rank.widthAnchor.constraint(equalToConstant: 28).isActive = true

        let avatar = IdeaUI.avatar(p.username.replacingOccurrences(of: "@", with: ""), size: 36, corner: 9, fontSize: 15)

        let name = label(p.username, 13, .regular, Theme.textPrimary)
        let acc = label(p.accuracy, 10, .light, Theme.textSecondary)
        let dot = UIView()
        dot.backgroundColor = Theme.borderStrong
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 1).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        let votes = label(p.votes, 10, .light, Theme.textSecondary)
        let meta = UIStackView(arrangedSubviews: [acc, dot, votes, UIView()])
        meta.axis = .horizontal; meta.spacing = 8; meta.alignment = .center
        let textCol = UIStackView(arrangedSubviews: [name, meta])
        textCol.axis = .vertical; textCol.spacing = 3

        let pts = label(p.pts, 13, .semibold, Theme.green)
        pts.setContentHuggingPriority(.required, for: .horizontal)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)))
        chevron.tintColor = Theme.textTertiary
        let right = UIStackView(arrangedSubviews: [pts, chevron])
        right.axis = .horizontal; right.spacing = 8; right.alignment = .center
        right.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [rank, avatar, textCol, right])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 11, left: 12, bottom: 11, right: 14)
        if p.isMe {
            // Tô nhẹ dòng của bản thân để dễ nhận ra.
            row.backgroundColor = Theme.green.withAlphaComponent(0.12)
            name.textColor = Theme.green
        }
        return row
    }

    // MARK: "Bạn #19" pill
    private func setupYouPill() {
        let avatar = IdeaUI.avatar("Bạn", size: 28, corner: 7, fontSize: 12)
        let name = label("Bạn", 12, .medium, Theme.textPrimary)
        let rank = label("#19", 11, .light, Theme.textSecondary)
        let arrow = UIImageView(image: UIImage(systemName: "arrow.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        arrow.tintColor = Theme.textPrimary
        youArrow = arrow
        let row = UIStackView(arrangedSubviews: [avatar, name, rank, arrow])
        row.axis = .horizontal; row.spacing = 8; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 8, left: 10, bottom: 8, right: 14)
        row.translatesAutoresizingMaskIntoConstraints = false

        let pill = ThemeCardView()
        pill.backgroundColor = Theme.card
        pill.layer.cornerRadius = 24
        pill.layer.borderWidth = 1
        pill.borderUIColor = Theme.border
        pill.layer.shadowColor = UIColor.black.cgColor
        pill.layer.shadowOpacity = 0.2
        pill.layer.shadowRadius = 12
        pill.layer.shadowOffset = CGSize(width: 0, height: 4)
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(row)
        view.addSubview(pill)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: pill.topAnchor),
            row.leadingAnchor.constraint(equalTo: pill.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: pill.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: pill.bottomAnchor),
            pill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pill.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
        ])
        // Bấm pill → cuộn tới đúng vị trí của mình.
        pill.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(scrollToMe)))
        youPill = pill
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateYouPillVisibility()
    }

    /// Ẩn pill khi dòng của mình (#19) đang hiển thị trên màn; hiện lại khi cuộn ra xa.
    private func updateYouPillVisibility() {
        guard let meRow, let youPill, meRow.bounds.height > 0 else { return }
        let rowFrame = meRow.convert(meRow.bounds, to: scroll)
        var visible = scroll.bounds
        visible.size.height -= 130   // chừa vùng pill + tab bar ở đáy
        let seen = visible.intersects(rowFrame)

        // Mũi tên chỉ hướng cần cuộn: hạng của mình ở TRÊN → mũi tên lên; ở DƯỚI → mũi tên xuống.
        let pointsUp = rowFrame.midY < visible.minY
        youArrow?.image = UIImage(systemName: pointsUp ? "arrow.up" : "arrow.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))

        let targetAlpha: CGFloat = seen ? 0 : 1
        guard abs(youPill.alpha - targetAlpha) > 0.01 else { return }
        youPill.isUserInteractionEnabled = !seen
        UIView.animate(withDuration: 0.2) {
            youPill.alpha = targetAlpha
            youPill.transform = seen ? CGAffineTransform(scaleX: 0.85, y: 0.85) : .identity
        }
    }

    @objc private func scrollToMe() {
        guard let meRow else { return }
        let rowFrame = meRow.convert(meRow.bounds, to: scroll)
        let maxY = scroll.contentSize.height + scroll.contentInset.bottom - scroll.bounds.height
        let targetY = max(-scroll.contentInset.top, min(rowFrame.midY - scroll.bounds.height / 2, maxY))
        scroll.setContentOffset(CGPoint(x: 0, y: targetY), animated: true)
    }

    // MARK: Helpers
    private func divider() -> UIView {
        let d = UIView()
        d.backgroundColor = Theme.border
        d.translatesAutoresizingMaskIntoConstraints = false
        d.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return d
    }

    private func label(_ text: String, _ size: CGFloat, _ weight: UIFont.Weight, _ color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
}

// MARK: - UIScrollViewDelegate
extension LeaderboardViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) { updateYouPillVisibility() }
}
