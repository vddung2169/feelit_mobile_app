import UIKit

// MARK: - PollDetailViewController
/// Màn chi tiết poll, scroll dọc (Figma 233-5702): giá hiện tại, biểu đồ, nút Tăng/Giảm,
/// các mục quy tắc thu gọn được, tab Bình luận/Hoạt động + ô nhập bình luận.
final class PollDetailViewController: UIViewController {

    // MARK: - Bảng màu Light mode (Figma 481-23974 "Home | Poll Detail")
    private enum L {
        static let pageBg     = Theme.page
        static let cardBg     = Theme.card
        static let textPrimary = Theme.textPrimary
        static let icon       = Theme.textPrimary
        static let muted      = Theme.textSecondary
        static let placeholder = Theme.textTertiary
        static let divider    = Theme.borderStrong
        static let separator  = Theme.textTertiary
        // Chip chọn dạng đảo màu (nền tối + chữ sáng ở light; ngược lại ở dark).
        static let chipSelected = Theme.textPrimary
        static let chipSelectedText = Theme.page
        static let segmentBg  = Theme.track
        static let segmentActiveBg = Theme.surfaceRaised
        static let green      = Theme.green
        static let red        = Theme.red
        static let voteUp     = Theme.voteUp
        static let voteDown   = Theme.voteDown
    }

    private let viewModel: PollDetailViewModel
    private var item: PollCardItem { viewModel.item }
    /// Live detail (Figma 481-24129) dùng nút Tăng/Giảm tông nhạt (tint mờ);
    /// Home detail (481-23974) dùng nút đặc. Mặc định nút đặc.
    private let softVoteButtons: Bool
    init(item: PollCardItem, softVoteButtons: Bool = false) {
        self.viewModel = PollDetailViewModel(item: item)
        self.softVoteButtons = softVoteButtons
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let chart = DetailLineChartView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = L.pageBg
        setupScroll()
        buildContent()
        chart.yesSeries = viewModel.yesSeries
        chart.noSeries  = viewModel.noSeries
    }

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInset.bottom = 100
        view.addSubview(scroll)
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40),
        ])
    }

    private func buildContent() {
        // Top: chip danh mục + tìm kiếm
        content.addArrangedSubview(topChips())

        // Header navigation: ‹ Trở lại  |  chuông thông báo
        content.addArrangedSubview(headerNav())

        // Category · cadence
        let tag = label("\(item.category) · \(item.cadence)", 12, .light, 0x202020)
        content.addArrangedSubview(tag)

        // Title + icons
        let title = label(item.title, 20, .medium, 0x202020); title.numberOfLines = 0
        let share = iconButton("square.and.arrow.up")
        let save = iconButton("bookmark")
        let titleRow = UIStackView(arrangedSubviews: [title, save, share])
        titleRow.axis = .horizontal; titleRow.spacing = 12; titleRow.alignment = .top
        save.setContentHuggingPriority(.required, for: .horizontal)
        share.setContentHuggingPriority(.required, for: .horizontal)
        content.addArrangedSubview(titleRow)
        content.setCustomSpacing(8, after: tag)

        // Hai chỉ số: Giá cần vượt · Giá hiện tại
        content.addArrangedSubview(metricsRow())

        // Chart
        chart.translatesAutoresizingMaskIntoConstraints = false
        chart.heightAnchor.constraint(equalToConstant: 170).isActive = true
        content.addArrangedSubview(chart)

        // Tăng / Neutral / Giảm
        content.addArrangedSubview(voteRow())

        // Collapsibles
        content.addArrangedSubview(CollapsibleSection(title: "Quy tắc thị trường", body: viewModel.rulesText, expanded: true))
        content.addArrangedSubview(CollapsibleSection(title: "Giao dịch nội gián bị cấm", body: viewModel.insiderText, expanded: true))

        // Comments header tabs
        content.addArrangedSubview(commentTabs())

        // Comment input
        content.addArrangedSubview(commentInput())

        // Sample comments
        content.addArrangedSubview(commentView(
            username: "fin.enjoyer", vote: "Tăng · 15% · 19 th 06",
            body: "Khả năng là sẽ tăng đấy các bảnh à tại mình có xài bùa may mắn",
            time: "5h", replies: 2))
        content.addArrangedSubview(commentView(
            username: "moon.boy", vote: "Tăng · 22% · 19 th 06",
            body: "BTC giữ vùng giá này là chuẩn bài, mình all-in 🚀",
            time: "5h", replies: 2))
    }

    // MARK: Sections
    private func topChips() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 8; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        for (i, c) in PollFeedData.categories.enumerated() {
            row.addArrangedSubview(chip(c, selected: i == selectedCategoryIndex))
        }
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.topAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            row.heightAnchor.constraint(equalTo: scroll.heightAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 32),
        ])
        let search = iconButton("magnifyingglass")
        search.setContentHuggingPriority(.required, for: .horizontal)
        search.setContentCompressionResistancePriority(.required, for: .horizontal)
        let h = UIStackView(arrangedSubviews: [scroll, search])
        h.axis = .horizontal; h.spacing = 10; h.alignment = .center
        return h
    }

    private var selectedCategoryIndex: Int {
        PollFeedData.categories.firstIndex(of: item.category) ?? 0
    }

    private func headerNav() -> UIView {
        let back = AuthUI.backButton(target: self, action: #selector(backTapped))
        let bell1 = notifBell()
        let bell2 = notifBell()
        let row = UIStackView(arrangedSubviews: [back, UIView(), bell1, bell2])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        bell1.setContentHuggingPriority(.required, for: .horizontal)
        bell2.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func metricsRow() -> UIView {
        let beat = metric(caption: "Giá cần vượt", value: item.currentPrice, valueHex: 0x202020)
        let now = metric(caption: "Giá hiện tại", value: item.marketPrice,
                         valueHex: item.isUp ? 0x4CAF50 : 0xF44336)
        // Vạch ngăn dọc giữa hai chỉ số (Figma: stroke #B9B9B9).
        let divider = UIView()
        divider.backgroundColor = L.separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
        let row = UIStackView(arrangedSubviews: [beat, divider, now])
        row.axis = .horizontal; row.spacing = 16; row.alignment = .fill
        beat.widthAnchor.constraint(equalTo: now.widthAnchor).isActive = true
        return row
    }

    private func voteRow() -> UIView {
        let up = voteButton("Tăng", 0x74FF7A)
        let neutral = voteButton("Neutral", 0xFFFFFF)
        // Nút Neutral trắng trên nền sáng cần viền để nhìn thấy.
        neutral.layer.borderWidth = 1
        neutral.layer.borderColor = L.divider.cgColor
        let down = voteButton("Giảm", 0xEF5350)
        let row = UIStackView(arrangedSubviews: [up, neutral, down])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .fill
        up.heightAnchor.constraint(equalToConstant: 48).isActive = true
        neutral.widthAnchor.constraint(equalToConstant: 96).isActive = true
        up.widthAnchor.constraint(equalTo: down.widthAnchor).isActive = true
        return row
    }

    private func commentTabs() -> UIView {
        let a = pill("Bình luận", icon: "bubble.left", selected: true)
        let b = pill("Hoạt động", icon: "bolt", selected: false)
        let seg = UIStackView(arrangedSubviews: [a, b])
        seg.axis = .horizontal; seg.spacing = 0
        seg.backgroundColor = L.segmentBg
        seg.layer.cornerRadius = 9
        seg.isLayoutMarginsRelativeArrangement = true
        seg.layoutMargins = .init(top: 3, left: 3, bottom: 3, right: 3)
        let s = UIStackView(arrangedSubviews: [seg, UIView()])
        s.axis = .horizontal
        return s
    }

    private func commentInput() -> UIView {
        let box = UIView()
        box.backgroundColor = L.segmentActiveBg
        box.layer.cornerRadius = 16
        box.layer.borderWidth = 1
        box.layer.borderColor = L.divider.cgColor

        let placeholder = label("Bạn đang nghĩ gì?", 12, .regular, 0xB9B9B9)
        let counter = label("800 ký tự", 11, .medium, 0xB9B9B9)
        var bcfg = UIButton.Configuration.filled()
        bcfg.baseBackgroundColor = L.textPrimary
        bcfg.baseForegroundColor = Theme.page
        bcfg.cornerStyle = .capsule
        bcfg.attributedTitle = AttributedString("Bình luận", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 11, weight: .medium)]))
        bcfg.contentInsets = .init(top: 6, leading: 14, bottom: 6, trailing: 14)
        let sendBtn = UIButton(configuration: bcfg)
        sendBtn.setContentHuggingPriority(.required, for: .horizontal)

        let bottomRow = UIStackView(arrangedSubviews: [counter, UIView(), sendBtn])
        bottomRow.axis = .horizontal; bottomRow.alignment = .center
        let v = UIStackView(arrangedSubviews: [placeholder, bottomRow])
        v.axis = .vertical; v.spacing = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: box.topAnchor, constant: 14),
            v.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            v.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
            v.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12),
        ])
        return box
    }

    private func commentView(username: String, vote: String, body: String,
                             time: String, replies: Int) -> UIView {
        let avatar = AvatarView(size: 48, fontSize: 18)
        avatar.configure(username: username)
        avatar.setContentHuggingPriority(.required, for: .horizontal)

        let name = label(username, 16, .medium, 0x202020)
        let badge = PaddingLabel(insets: .init(top: 1, left: 8, bottom: 1, right: 8))
        badge.text = vote
        badge.font = .systemFont(ofSize: 11, weight: .medium)
        badge.textColor = UIColor(hex: 0x4CAF50)
        badge.backgroundColor = UIColor(hex: 0x74FF7A)
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        let badgeRow = UIStackView(arrangedSubviews: [badge, UIView()])
        badgeRow.axis = .horizontal

        let bodyLabel = label(body, 14, .regular, 0x202020)
        bodyLabel.numberOfLines = 0

        let timeLabel = label(time, 12, .regular, 0xB9B9B9)
        let reply = label("Trả lời (\(replies))", 12, .regular, 0x818181)
        let footer = UIStackView(arrangedSubviews: [timeLabel, reply, UIView()])
        footer.axis = .horizontal; footer.spacing = 12; footer.alignment = .center

        let textCol = UIStackView(arrangedSubviews: [name, badgeRow, bodyLabel, footer])
        textCol.axis = .vertical; textCol.spacing = 4
        textCol.setCustomSpacing(8, after: badgeRow)
        textCol.setCustomSpacing(8, after: bodyLabel)

        let row = UIStackView(arrangedSubviews: [avatar, textCol])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .top
        return row
    }

    // MARK: Helpers
    private func chip(_ text: String, selected: Bool) -> UIView {
        let l = PaddingLabel(insets: .init(top: 7, left: 12, bottom: 7, right: 12))
        l.text = text
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = selected ? L.chipSelectedText : L.textPrimary
        l.backgroundColor = selected ? L.chipSelected : .clear
        l.layer.cornerRadius = 16
        l.clipsToBounds = true
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }

    private func notifBell() -> UIView {
        let iv = UIImageView(image: UIImage(systemName: "bell",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)))
        iv.tintColor = Theme.textSecondary
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        let dot = UIView()
        dot.backgroundColor = Theme.redDot
        dot.layer.cornerRadius = 3
        dot.translatesAutoresizingMaskIntoConstraints = false
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(iv)
        wrap.addSubview(dot)
        NSLayoutConstraint.activate([
            wrap.widthAnchor.constraint(equalToConstant: 24),
            wrap.heightAnchor.constraint(equalToConstant: 24),
            iv.centerXAnchor.constraint(equalTo: wrap.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 22),
            iv.heightAnchor.constraint(equalToConstant: 22),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),
            dot.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 1),
            dot.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -1),
        ])
        return wrap
    }

    private func metric(caption: String, value: String, valueHex: UInt32) -> UIView {
        let swatch = UIView()
        swatch.backgroundColor = UIColor(hex: 0x3E63DD)
        swatch.layer.cornerRadius = 2
        swatch.translatesAutoresizingMaskIntoConstraints = false
        swatch.widthAnchor.constraint(equalToConstant: 6).isActive = true
        swatch.heightAnchor.constraint(equalToConstant: 6).isActive = true
        let cap = label(caption, 12, .regular, 0x202020)
        let capRow = UIStackView(arrangedSubviews: [swatch, cap, UIView()])
        capRow.axis = .horizontal; capRow.spacing = 6; capRow.alignment = .center
        let val = label(value, 22, .semibold, valueHex)
        let v = UIStackView(arrangedSubviews: [capRow, val])
        v.axis = .vertical; v.spacing = 6; v.alignment = .leading
        return v
    }

    private func pill(_ text: String, icon: String, selected: Bool) -> UIView {
        let iv = UIImageView(image: UIImage(systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)))
        iv.tintColor = selected ? Theme.textPrimary : Theme.textSecondary
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        let l = label(text, 13, .medium, selected ? 0x202020 : 0x818181)
        let row = UIStackView(arrangedSubviews: [iv, l])
        row.axis = .horizontal; row.spacing = 6; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 6, left: 14, bottom: 6, right: 14)
        if selected {
            row.backgroundColor = L.segmentActiveBg
            row.layer.cornerRadius = 7
            row.layer.borderWidth = 1
            row.layer.borderColor = L.divider.cgColor
        }
        return row
    }

    private func label(_ text: String, _ size: CGFloat, _ weight: UIFont.Weight, _ hex: UInt32) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = Self.adaptiveColor(hex)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    /// Ánh xạ các hex trung tính (nền/chữ) sang màu adaptive; màu nhấn giữ nguyên.
    static func adaptiveColor(_ hex: UInt32) -> UIColor {
        switch hex {
        case 0x202020, 0x121212: return Theme.textPrimary
        case 0x818181, 0x969696, 0x525252: return Theme.textSecondary
        case 0xB9B9B9:           return Theme.textTertiary
        case 0xCCCCCC:           return Theme.borderStrong
        default:                 return UIColor(hex: hex)
        }
    }

    private func iconButton(_ icon: String) -> UIButton {
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular))
        c.baseForegroundColor = L.icon
        c.contentInsets = .zero
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    private func voteButton(_ title: String, _ color: UInt32) -> UIButton {
        var c = UIButton.Configuration.filled()
        if softVoteButtons {
            // Live detail (Figma 481-24129): nền tint 32%, chữ theo màu xanh/đỏ.
            c.baseBackgroundColor = UIColor(hex: color, alpha: 0.32)
            let textHex: UInt32 = color == 0x74FF7A ? 0x4CAF50 : (color == 0xEF5350 ? 0xF44336 : 0x202020)
            c.baseForegroundColor = UIColor(hex: textHex)
        } else {
            c.baseBackgroundColor = UIColor(hex: color)
            c.baseForegroundColor = UIColor(hex: 0x202020)
        }
        c.cornerStyle = .large
        c.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        return UIButton(configuration: c)
    }

    @objc private func backTapped() { navigationController?.popViewController(animated: true) }
}

// MARK: - CollapsibleSection
/// Mục thu gọn được: tiêu đề + chevron, bấm để ẩn/hiện phần body.
final class CollapsibleSection: UIView {
    private let body: UILabel
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
    private var expanded: Bool

    init(title: String, body bodyText: String, expanded: Bool) {
        self.expanded = expanded
        self.body = UILabel()
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = Theme.textPrimary
        chevron.tintColor = Theme.textPrimary
        chevron.contentMode = .scaleAspectFit

        let header = UIStackView(arrangedSubviews: [titleLabel, UIView(), chevron])
        header.axis = .horizontal
        header.alignment = .center
        header.isUserInteractionEnabled = true
        header.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggle)))

        body.text = bodyText
        body.numberOfLines = 0
        body.font = .systemFont(ofSize: 13, weight: .regular)
        body.textColor = Theme.textPrimary
        body.isHidden = !expanded

        let stack = UIStackView(arrangedSubviews: [header, body])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 14),
        ])
        updateChevron()

        let top = UIView(); top.backgroundColor = Theme.borderStrong
        top.translatesAutoresizingMaskIntoConstraints = false
        addSubview(top)
        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: topAnchor),
            top.leadingAnchor.constraint(equalTo: leadingAnchor),
            top.trailingAnchor.constraint(equalTo: trailingAnchor),
            top.heightAnchor.constraint(equalToConstant: 1),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func toggle() {
        expanded.toggle()
        UIView.animate(withDuration: 0.2) {
            self.body.isHidden = !self.expanded
            self.updateChevron()
            self.superview?.superview?.layoutIfNeeded()
        }
    }
    private func updateChevron() {
        chevron.transform = expanded ? CGAffineTransform(rotationAngle: .pi) : .identity
    }
}
