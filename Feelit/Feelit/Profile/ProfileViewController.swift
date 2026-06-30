import UIKit

// MARK: - ProfileViewController
/// Tab Profile (Figma 600-25299 "Profile | Default", light mode): header "Hồ sơ" + nút cài đặt,
/// thẻ hồ sơ (avatar/tên/XP), thẻ thống kê, chất lượng dự đoán, hoạt động, danh mục nổi bật,
/// và lịch sử dự đoán.
final class ProfileViewController: UIViewController {

    // Bảng màu adaptive (light/dark) dùng chung.
    private enum P {
        static let page    = Theme.page
        static let card    = Theme.card
        static let border  = Theme.border
        static let text    = Theme.textPrimary
        static let sub     = Theme.textSecondary
        static let muted   = Theme.textTertiary
        static let track   = Theme.track
        static let green   = Theme.green
        static let red     = Theme.red
        static let gold    = Theme.gold
    }

    private struct Activity {
        let title: String, category: String, choice: String, xp: String, time: String
        let status: Status
        enum Status { case correct, wrong, pending }
    }
    private let activities: [Activity] = [
        .init(title: "BTC vượt $70K ngày mai?", category: "Crypto", choice: "Chọn: Tăng", xp: "+120 XP", time: "2 giờ trước", status: .correct),
        .init(title: "Việt Nam thắng Thái Lan tối nay?", category: "Thể thao", choice: "Chọn: Thắng", xp: "+95 XP", time: "1 ngày trước", status: .correct),
        .init(title: "ETH chạm $4,000 tuần này?", category: "Crypto", choice: "Chọn: Có", xp: "0 XP", time: "2 ngày trước", status: .wrong),
        .init(title: "Apple ra mắt AI tại WWDC?", category: "Công nghệ", choice: "Chọn: Có", xp: "+80 XP", time: "3 ngày trước", status: .correct),
        .init(title: "SOOBIN đạt 50M view tháng này?", category: "Giải trí", choice: "Chọn: Có", xp: "Đang chờ", time: "4 ngày trước", status: .pending),
    ]

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    /// Header nổi dùng Liquid Glass (iOS 26+) / vật liệu mờ (iOS cũ).
    private let headerBar: UIVisualEffectView = {
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            effect = UIGlassEffect()
        } else {
            effect = UIBlurEffect(style: .systemThinMaterial)
        }
        let v = UIVisualEffectView(effect: effect)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var didSetHeaderInset = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = P.page
        setupScroll()
        setupHeader()   // sau setupScroll để lớp kính nằm trên nội dung
        buildContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let top = headerBar.frame.height + 4
        guard top > 4, abs(scroll.contentInset.top - top) > 0.5 else { return }
        scroll.contentInset.top = top
        scroll.verticalScrollIndicatorInsets.top = top
        scroll.contentOffset.y = -top   // giữ ở đỉnh khi header settle xong
    }

    // MARK: Header
    private func setupHeader() {
        let title = label("Hồ sơ", 22, .medium, P.text)

        let gear = UIButton(type: .system)
        gear.setImage(UIImage(systemName: "gearshape.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
        gear.tintColor = P.text
        gear.translatesAutoresizingMaskIntoConstraints = false
        gear.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let dot = UIView()
        dot.backgroundColor = Theme.redDot
        dot.layer.cornerRadius = 3
        dot.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerBar)
        headerBar.contentView.addSubview(title)
        headerBar.contentView.addSubview(gear)
        gear.addSubview(dot)
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),

            title.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),

            gear.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            gear.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -16),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),
            dot.topAnchor.constraint(equalTo: gear.topAnchor, constant: 2),
            dot.trailingAnchor.constraint(equalTo: gear.trailingAnchor, constant: -1),
        ])
    }

    @objc private func openSettings() {
        navigationController?.pushViewController(ProfileSettingsViewController(), animated: true)
    }

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset.bottom = 130
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            // Cuộn toàn màn để nội dung trôi dưới lớp kính header.
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        ])
    }

    private func buildContent() {
        stack.addArrangedSubview(profileCard())
        stack.addArrangedSubview(statsRow())
        stack.addArrangedSubview(accuracyCard())
        stack.addArrangedSubview(activityStatsCard())
        stack.addArrangedSubview(categoriesCard())
        stack.addArrangedSubview(historyCard())
    }

    // MARK: Profile card
    private func profileCard() -> UIView {
        let avatar = IdeaUI.avatar("fin.enjoyer", size: 58, corner: 14, fontSize: 22)
        let name = label("fin.enjoyer", 16, .semibold, P.text)
        let handle = label("@ilovefinance", 11, .regular, P.sub)
        let nameCol = UIStackView(arrangedSubviews: [name, handle])
        nameCol.axis = .vertical; nameCol.spacing = 3
        let idRow = UIStackView(arrangedSubviews: [avatar, nameCol])
        idRow.axis = .horizontal; idRow.spacing = 12; idRow.alignment = .center

        let topRow = UIStackView(arrangedSubviews: [idRow, UIView(), rankBadge("#127")])
        topRow.axis = .horizontal; topRow.alignment = .top

        let bio = label("Chỉ là một broker thích đủ kiểu tài chính hehe\nBooking: booking.finenjoyer@gmail.com", 13, .regular, P.sub)
        bio.numberOfLines = 0

        let xp = label("18,420 XP", 12, .bold, P.text)
        let lvl = label("20.000 XP → Lv.43", 11, .light, P.muted)
        let xpRow = UIStackView(arrangedSubviews: [xp, UIView(), lvl])
        xpRow.axis = .horizontal; xpRow.alignment = .firstBaseline
        let xpCol = UIStackView(arrangedSubviews: [xpRow, bar(ratio: 0.88, fill: P.text, height: 5)])
        xpCol.axis = .vertical; xpCol.spacing = 8

        let col = UIStackView(arrangedSubviews: [topRow, bio, xpCol])
        col.axis = .vertical; col.spacing = 14
        return card(col, radius: 16)
    }

    private func rankBadge(_ text: String) -> UIView {
        let trophy = UIImageView(image: UIImage(systemName: "trophy.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)))
        trophy.tintColor = P.gold
        let lbl = label(text, 12, .bold, P.gold)
        let row = UIStackView(arrangedSubviews: [trophy, lbl])
        row.axis = .horizontal; row.spacing = 4; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 5, left: 9, bottom: 5, right: 9)
        row.backgroundColor = P.gold.withAlphaComponent(0.15)
        row.layer.cornerRadius = 8
        row.clipsToBounds = true
        row.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    // MARK: Stats row (Tổng XP / Streak)
    private func statsRow() -> UIView {
        let totalXP = statCard(caption: "Tổng XP", icon: nil) {
            self.label("18,420", 25, .medium, P.text)
        }
        let streakVal = UIStackView(arrangedSubviews: [label("14", 28, .heavy, P.text), label("ngày", 12, .regular, P.muted)])
        streakVal.axis = .horizontal; streakVal.spacing = 4; streakVal.alignment = .lastBaseline
        let streak = statCard(caption: "Streak", icon: "flame.fill") { streakVal }
        let row = UIStackView(arrangedSubviews: [totalXP, streak])
        row.axis = .horizontal; row.spacing = 12; row.distribution = .fillEqually
        return row
    }

    private func statCard(caption: String, icon: String?, value: () -> UIView) -> UIView {
        let capRow = UIStackView()
        capRow.axis = .horizontal; capRow.spacing = 5; capRow.alignment = .center
        if let icon {
            let iv = UIImageView(image: UIImage(systemName: icon,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)))
            iv.tintColor = P.sub
            capRow.addArrangedSubview(iv)
        }
        capRow.addArrangedSubview(label(caption, 11, .light, P.muted))
        capRow.addArrangedSubview(UIView())
        let col = UIStackView(arrangedSubviews: [capRow, value()])
        col.axis = .vertical; col.spacing = 8; col.alignment = .leading
        return card(col, radius: 12, padding: 16)
    }

    // MARK: Accuracy card
    private func accuracyCard() -> UIView {
        let header = sectionHeader("scope", "Chất lượng dự đoán")
        let accRow = UIStackView(arrangedSubviews: [label("Độ chính xác", 12, .regular, P.sub), UIView(), label("73.4%", 14, .bold, P.green)])
        accRow.axis = .horizontal; accRow.alignment = .center
        let accCol = UIStackView(arrangedSubviews: [accRow, bar(ratio: 0.734, fill: P.green, height: 5)])
        accCol.axis = .vertical; accCol.spacing = 8

        let votesCorrect = miniStat("Votes đúng", value: "208", suffix: "/ 284")
        let votesTotal = miniStat("Tổng lượt vote", value: "284", suffix: nil)
        let bottom = UIStackView(arrangedSubviews: [votesCorrect, vDivider(36), votesTotal])
        bottom.axis = .horizontal; bottom.spacing = 16; bottom.alignment = .center
        votesCorrect.widthAnchor.constraint(equalTo: votesTotal.widthAnchor).isActive = true

        let col = UIStackView(arrangedSubviews: [header, accCol, hDivider(), bottom])
        col.axis = .vertical; col.spacing = 14
        return card(col, radius: 12)
    }

    // MARK: Activity stats card
    private func activityStatsCard() -> UIView {
        let header = sectionHeader("bolt.fill", "Hoạt động")
        let points = miniStat("Điểm tích lũy", value: "3,240", suffix: nil)
        let streak = miniStat("Streak lâu nhất", value: "31", suffix: "ngày")
        let row = UIStackView(arrangedSubviews: [points, vDivider(36), streak])
        row.axis = .horizontal; row.spacing = 16; row.alignment = .center
        points.widthAnchor.constraint(equalTo: streak.widthAnchor).isActive = true
        let col = UIStackView(arrangedSubviews: [header, row])
        col.axis = .vertical; col.spacing = 14
        return card(col, radius: 12)
    }

    private func miniStat(_ caption: String, value: String, suffix: String?) -> UIView {
        let cap = label(caption, 11, .regular, P.muted)
        let val = label(value, 20, .bold, P.text)
        let valueRow = UIStackView(arrangedSubviews: [val])
        valueRow.axis = .horizontal; valueRow.spacing = 4; valueRow.alignment = .lastBaseline
        if let suffix { valueRow.addArrangedSubview(label(suffix, 12, .regular, P.muted)) }
        valueRow.addArrangedSubview(UIView())
        let col = UIStackView(arrangedSubviews: [cap, valueRow])
        col.axis = .vertical; col.spacing = 6; col.alignment = .leading
        return col
    }

    // MARK: Categories card
    private func categoriesCard() -> UIView {
        let titleRow = UIStackView(arrangedSubviews: [label("Danh mục nổi bật", 13, .semibold, P.text), UIView(),
            chevron()])
        titleRow.axis = .horizontal; titleRow.alignment = .center
        let cats: [(String, String, Int, Bool)] = [
            ("1", "Crypto", 81, true), ("2", "Chứng khoán VN", 74, false),
            ("3", "Ngoại hối", 69, false), ("4", "Tài chính", 58, false),
        ]
        let rows = cats.map { categoryRow(rank: $0.0, name: $0.1, percent: $0.2, gold: $0.3) }
        let col = UIStackView(arrangedSubviews: [titleRow] + rows)
        col.axis = .vertical; col.spacing = 14
        return card(col, radius: 12)
    }

    private func categoryRow(rank: String, name: String, percent: Int, gold: Bool) -> UIView {
        let r = label(rank, 11, .bold, gold ? Theme.goldRank : P.muted)
        r.widthAnchor.constraint(equalToConstant: 14).isActive = true
        let n = label(name, 13, .regular, P.text)
        let b = bar(ratio: CGFloat(percent) / 100, fill: P.text, height: 4)
        b.widthAnchor.constraint(equalToConstant: 64).isActive = true
        let pct = label("\(percent)%", 11, .bold, P.text)
        let right = UIStackView(arrangedSubviews: [b, pct])
        right.axis = .horizontal; right.spacing = 8; right.alignment = .center
        right.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [r, n, UIView(), right])
        row.axis = .horizontal; row.spacing = 8; row.alignment = .center
        return row
    }

    // MARK: History card
    private func historyCard() -> UIView {
        let tabHistory = pill("Lịch sử", selected: true)
        let tabPosts = pill("Bài đăng", selected: false)
        let tabs = UIStackView(arrangedSubviews: [tabHistory, tabPosts])
        tabs.axis = .horizontal; tabs.spacing = 4
        let seeAll = UIStackView(arrangedSubviews: [label("Xem tất cả", 12, .regular, P.muted), chevron()])
        seeAll.axis = .horizontal; seeAll.spacing = 2; seeAll.alignment = .center
        let header = UIStackView(arrangedSubviews: [tabs, UIView(), seeAll])
        header.axis = .horizontal; header.alignment = .center

        var children: [UIView] = [header]
        for (i, a) in activities.enumerated() {
            children.append(activityRow(a))
            if i < activities.count - 1 { children.append(hDivider()) }
        }
        let col = UIStackView(arrangedSubviews: children)
        col.axis = .vertical; col.spacing = 12
        return card(col, radius: 12)
    }

    private func activityRow(_ a: Activity) -> UIView {
        let (bg, fg, icon): (UIColor, UIColor, String)
        switch a.status {
        case .correct: (bg, fg, icon) = (Theme.voteUp, P.green, "checkmark")
        case .wrong:   (bg, fg, icon) = (Theme.voteDown, P.red, "xmark")
        case .pending: (bg, fg, icon) = (P.track, P.sub, "clock")
        }
        let badge = UIView()
        badge.backgroundColor = bg.withAlphaComponent(a.status == .pending ? 1 : 0.35)
        badge.layer.cornerRadius = 14
        badge.translatesAutoresizingMaskIntoConstraints = false
        let icv = UIImageView(image: UIImage(systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)))
        icv.tintColor = fg
        icv.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(icv)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 28),
            badge.heightAnchor.constraint(equalToConstant: 28),
            icv.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            icv.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
        ])

        let title = label(a.title, 13, .medium, P.text)
        title.numberOfLines = 1
        let chip = label(a.category, 10, .regular, P.sub)
        chip.translatesAutoresizingMaskIntoConstraints = false
        let chipWrap = UIView()
        chipWrap.backgroundColor = P.track
        chipWrap.layer.cornerRadius = 4
        chipWrap.translatesAutoresizingMaskIntoConstraints = false
        chipWrap.addSubview(chip)
        NSLayoutConstraint.activate([
            chip.topAnchor.constraint(equalTo: chipWrap.topAnchor, constant: 2),
            chip.bottomAnchor.constraint(equalTo: chipWrap.bottomAnchor, constant: -2),
            chip.leadingAnchor.constraint(equalTo: chipWrap.leadingAnchor, constant: 6),
            chip.trailingAnchor.constraint(equalTo: chipWrap.trailingAnchor, constant: -6),
        ])
        chipWrap.setContentHuggingPriority(.required, for: .horizontal)
        let meta = UIStackView(arrangedSubviews: [chipWrap, label(a.choice, 11, .regular, P.muted), UIView()])
        meta.axis = .horizontal; meta.spacing = 8; meta.alignment = .center
        let textCol = UIStackView(arrangedSubviews: [title, meta])
        textCol.axis = .vertical; textCol.spacing = 6

        let xpColor: UIColor = a.status == .correct ? P.green : (a.status == .pending ? P.sub : P.text)
        let xp = label(a.status == .pending ? "Đang chờ" : a.xp, 12, .bold, xpColor)
        let time = label(a.time, 10, .regular, P.muted)
        let rightCol = UIStackView(arrangedSubviews: [xp, time])
        rightCol.axis = .vertical; rightCol.spacing = 3; rightCol.alignment = .trailing
        rightCol.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [badge, textCol, rightCol])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        return row
    }

    // MARK: Reusable bits
    private func card(_ content: UIView, radius: CGFloat, padding: CGFloat = 16) -> UIView {
        let c = ThemeCardView()
        c.backgroundColor = P.card
        c.layer.cornerRadius = radius
        c.layer.borderWidth = 1
        c.borderUIColor = P.border
        content.translatesAutoresizingMaskIntoConstraints = false
        c.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: c.topAnchor, constant: padding),
            content.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: padding),
            content.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -padding),
            content.bottomAnchor.constraint(equalTo: c.bottomAnchor, constant: -padding),
        ])
        return c
    }

    private func sectionHeader(_ icon: String, _ text: String) -> UIView {
        let iv = UIImageView(image: UIImage(systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)))
        iv.tintColor = P.sub
        let row = UIStackView(arrangedSubviews: [iv, label(text, 13, .semibold, P.text), UIView()])
        row.axis = .horizontal; row.spacing = 7; row.alignment = .center
        return row
    }

    private func bar(ratio: CGFloat, fill: UIColor, height: CGFloat) -> UIView {
        let track = UIView()
        track.backgroundColor = P.track
        track.layer.cornerRadius = height / 2
        track.translatesAutoresizingMaskIntoConstraints = false
        track.heightAnchor.constraint(equalToConstant: height).isActive = true
        let fillV = UIView()
        fillV.backgroundColor = fill
        fillV.layer.cornerRadius = height / 2
        fillV.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fillV)
        NSLayoutConstraint.activate([
            fillV.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fillV.topAnchor.constraint(equalTo: track.topAnchor),
            fillV.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fillV.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: max(0.02, min(1, ratio))),
        ])
        return track
    }

    private func pill(_ text: String, selected: Bool) -> UIView {
        let l = label(text, 12, selected ? .semibold : .regular, selected ? P.text : P.muted)
        let wrap = UIView()
        wrap.backgroundColor = selected ? P.track : .clear
        wrap.layer.cornerRadius = 8
        l.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(l)
        NSLayoutConstraint.activate([
            l.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 5),
            l.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -5),
            l.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 12),
            l.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -12),
        ])
        return wrap
    }

    private func chevron() -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)))
        iv.tintColor = P.muted
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }

    private func hDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = P.border
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func vDivider(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.backgroundColor = P.border
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: 1).isActive = true
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
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
