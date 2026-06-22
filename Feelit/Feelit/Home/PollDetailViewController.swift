import UIKit

// MARK: - PollDetailViewController
/// Màn chi tiết poll, scroll dọc (Figma 233-5702): giá hiện tại, biểu đồ, nút Tăng/Giảm,
/// các mục quy tắc thu gọn được, tab Bình luận/Hoạt động + ô nhập bình luận.
final class PollDetailViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private let item: PollCardItem
    init(item: PollCardItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let chart = DetailLineChartView()

    private let rulesText = "Resolves Yes if the simple average of the sixty seconds of CF Benchmarks' Bitcoin Real-Time Index (BRTI) before 5 AM EDT is above 62599.99 at 5 AM EDT on Jun 19, 2026. Outcome verified from CF Benchmarks.\n\nNot all cryptocurrency price data is the same. While checking a source like Google or Coinbase may help guide your decision, the price used to determine this market is based on CF Benchmarks' corresponding Real Time Index (RTI). At the last minute before expiration, 60 RTI prices are collected. The official and final value is the average of these prices.\n\nNote: this event is directional."
    private let insiderText = "The following are prohibited from trading this contract: Persons who are employed by any of the Source Agencies are not permitted to trade on the Contract.\n\nPersons who hold any material, non-public information on the Underlying are not permitted to trade on the Contract."

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = FeelitColors.background
        setupScroll()
        buildContent()
        chart.yesSeries = Self.wave(count: 24, base: 0.55, amp: 0.18, up: 0.15)
        chart.noSeries  = Self.wave(count: 24, base: 0.45, amp: 0.16, up: -0.12)
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
        // Back
        let back = AuthUI.backButton(target: self, action: #selector(backTapped))
        let backRow = UIStackView(arrangedSubviews: [back, UIView()])
        backRow.axis = .horizontal

        // Category · cadence
        content.addArrangedSubview(backRow)
        content.addArrangedSubview(label("\(item.category) · \(item.cadence)", 11, .light, 0xEDEDED))

        // Title + icons
        let title = label(item.title, 20, .medium, 0xEDEDED); title.numberOfLines = 0
        let share = iconButton("square.and.arrow.up")
        let save = iconButton("bookmark")
        let titleRow = UIStackView(arrangedSubviews: [title, save, share])
        titleRow.axis = .horizontal; titleRow.spacing = 12; titleRow.alignment = .top
        save.setContentHuggingPriority(.required, for: .horizontal)
        share.setContentHuggingPriority(.required, for: .horizontal)
        content.addArrangedSubview(titleRow)
        content.setCustomSpacing(8, after: content.arrangedSubviews[1])

        // Price block
        content.addArrangedSubview(priceBlock())

        // Chart + legend
        let legend = UIStackView(arrangedSubviews: [dot(0x4CAF50, "CÓ"), dot(0xF44336, "KHÔNG"), UIView()])
        legend.axis = .horizontal; legend.spacing = 14
        content.addArrangedSubview(legend)
        chart.translatesAutoresizingMaskIntoConstraints = false
        chart.heightAnchor.constraint(equalToConstant: 170).isActive = true
        content.addArrangedSubview(chart)

        // Tăng / Giảm
        let up = voteButton("Tăng", 0x4CAF50)
        let down = voteButton("Giảm", 0xF44336)
        let voteRow = UIStackView(arrangedSubviews: [up, down])
        voteRow.axis = .horizontal; voteRow.spacing = 12; voteRow.distribution = .fillEqually
        up.heightAnchor.constraint(equalToConstant: 50).isActive = true
        content.addArrangedSubview(voteRow)

        // Collapsibles
        content.addArrangedSubview(CollapsibleSection(title: "Quy tắc thị trường", body: rulesText, expanded: true))
        content.addArrangedSubview(CollapsibleSection(title: "Giao dịch nội gián bị cấm", body: insiderText, expanded: true))

        // Comments header tabs
        content.addArrangedSubview(commentTabs())

        // Comment input
        content.addArrangedSubview(commentInput())

        // Sample comment
        content.addArrangedSubview(sampleComment())
    }

    // MARK: Sections
    private func priceBlock() -> UIView {
        let cap = label("Giá hiện tại", 11, .light, 0xEDEDED)
        let price = label(item.currentPrice, 25, .medium, 0xEDEDED)
        let change = label("\(item.isUp ? "▲" : "▼") \(item.changePercent)", 12, .medium,
                           item.isUp ? 0x4CAF50 : 0xF44336)
        let row = UIStackView(arrangedSubviews: [price, change, UIView()])
        row.axis = .horizontal; row.spacing = 8; row.alignment = .firstBaseline
        let v = UIStackView(arrangedSubviews: [cap, row])
        v.axis = .vertical; v.spacing = 2; v.alignment = .leading
        return v
    }

    private func commentTabs() -> UIView {
        let a = label("Bình luận", 14, .semibold, 0xEDEDED)
        let b = label("Hoạt động", 14, .medium, 0xB3B3B3)
        let s = UIStackView(arrangedSubviews: [a, b, UIView()])
        s.axis = .horizontal; s.spacing = 20
        return s
    }

    private func commentInput() -> UIView {
        let box = UIView()
        box.backgroundColor = FeelitColors.surface
        box.layer.cornerRadius = 16
        box.layer.borderWidth = 1
        box.layer.borderColor = FeelitColors.border.cgColor

        let placeholder = label("Bạn đang nghĩ gì?", 12, .regular, 0x606060)
        let counter = label("800 ký tự", 11, .medium, 0x606060)
        var bcfg = UIButton.Configuration.filled()
        bcfg.baseBackgroundColor = FeelitColors.primary
        bcfg.baseForegroundColor = UIColor(hex: 0xFBFBFB)
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

    private func sampleComment() -> UIView {
        let avatar = AvatarView(size: 36, fontSize: 14)
        avatar.configure(username: "fin.enjoyer")
        let name = label("fin.enjoyer", 16, .regular, 0xEDEDED)
        let meta = label("Tăng · 15% · 19 th 06", 12, .regular, 0x4CAF50)
        let body = label("Khả năng cao BTC giữ vùng giá này tới sáng mai mất 🚀", 14, .regular, 0xB3B3B3)
        body.numberOfLines = 0
        let textCol = UIStackView(arrangedSubviews: [name, meta, body])
        textCol.axis = .vertical; textCol.spacing = 3
        textCol.setCustomSpacing(6, after: meta)
        let row = UIStackView(arrangedSubviews: [avatar, textCol])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .top
        avatar.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    // MARK: Helpers
    private func dot(_ color: UInt32, _ text: String) -> UIView {
        let d = UIView()
        d.backgroundColor = UIColor(hex: color)
        d.layer.cornerRadius = 4
        d.translatesAutoresizingMaskIntoConstraints = false
        d.widthAnchor.constraint(equalToConstant: 8).isActive = true
        d.heightAnchor.constraint(equalToConstant: 8).isActive = true
        let l = label(text, 11, .medium, 0xEDEDED)
        let s = UIStackView(arrangedSubviews: [d, l])
        s.axis = .horizontal; s.spacing = 5; s.alignment = .center
        return s
    }

    private func label(_ text: String, _ size: CGFloat, _ weight: UIFont.Weight, _ hex: UInt32) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = UIColor(hex: hex)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func iconButton(_ icon: String) -> UIButton {
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular))
        c.baseForegroundColor = FeelitColors.textPrimary
        c.contentInsets = .zero
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    private func voteButton(_ title: String, _ color: UInt32) -> UIButton {
        var c = UIButton.Configuration.filled()
        c.baseBackgroundColor = UIColor(hex: color)
        c.baseForegroundColor = UIColor(hex: 0x111111)
        c.cornerStyle = .large
        c.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        return UIButton(configuration: c)
    }

    @objc private func backTapped() { navigationController?.popViewController(animated: true) }

    /// Sinh dữ liệu sóng giả lập 0...1.
    private static func wave(count: Int, base: CGFloat, amp: CGFloat, up: CGFloat) -> [CGFloat] {
        (0..<count).map { i in
            let t = CGFloat(i) / CGFloat(count - 1)
            let s = sin(t * .pi * 3) * amp + sin(t * .pi * 7) * amp * 0.4
            return min(max(base + s + up * t, 0.05), 0.95)
        }
    }
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
        titleLabel.textColor = FeelitColors.textPrimary
        chevron.tintColor = FeelitColors.textSecondary
        chevron.contentMode = .scaleAspectFit

        let header = UIStackView(arrangedSubviews: [titleLabel, UIView(), chevron])
        header.axis = .horizontal
        header.alignment = .center
        header.isUserInteractionEnabled = true
        header.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggle)))

        body.text = bodyText
        body.numberOfLines = 0
        body.font = .systemFont(ofSize: 13, weight: .regular)
        body.textColor = FeelitColors.textSecondary
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

        let top = UIView(); top.backgroundColor = FeelitColors.border
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
