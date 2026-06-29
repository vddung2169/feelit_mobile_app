import UIKit

// MARK: - IdeaPostView
/// Một bài đăng trong feed Ý tưởng: avatar + tên · thời gian, nội dung, badge bình chọn,
/// poll nhúng hoặc trích dẫn, và hàng hành động (thích / bình luận / đăng lại / chia sẻ).
final class IdeaPostView: UIView {

    private let onOpenPoll: (String) -> Void

    init(post: IdeaPost, onOpenPoll: @escaping (String) -> Void) {
        self.onOpenPoll = onOpenPoll
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.page
        build(post)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(_ post: IdeaPost) {
        // Cột avatar (+ đường nối thread nếu có).
        let avatar = IdeaUI.avatar(post.username, size: 48, corner: 12, fontSize: 18)
        let avatarCol = UIView()
        avatarCol.translatesAutoresizingMaskIntoConstraints = false
        avatarCol.addSubview(avatar)
        avatarCol.widthAnchor.constraint(equalToConstant: 48).isActive = true
        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: avatarCol.topAnchor),
            avatar.centerXAnchor.constraint(equalTo: avatarCol.centerXAnchor),
        ])
        if post.threadBelow {
            let line = UIView()
            line.backgroundColor = Theme.border
            line.translatesAutoresizingMaskIntoConstraints = false
            avatarCol.addSubview(line)
            NSLayoutConstraint.activate([
                line.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 8),
                line.bottomAnchor.constraint(equalTo: avatarCol.bottomAnchor),
                line.centerXAnchor.constraint(equalTo: avatarCol.centerXAnchor),
                line.widthAnchor.constraint(equalToConstant: 2),
            ])
        }

        // Cột nội dung.
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 8
        content.translatesAutoresizingMaskIntoConstraints = false

        // Tên · thời gian
        let name = IdeaUI.label(post.username, 16, .medium, 0x202020)
        name.setContentHuggingPriority(.required, for: .horizontal)
        let time = IdeaUI.label("· \(post.time)", 12, .regular, 0xB9B9B9)
        let nameRow = UIStackView(arrangedSubviews: [name, time, UIView()])
        nameRow.axis = .horizontal; nameRow.spacing = 6; nameRow.alignment = .firstBaseline
        content.addArrangedSubview(nameRow)

        // Nội dung
        let body = IdeaUI.label(post.content, 14, .regular, 0x202020)
        body.numberOfLines = 0
        content.addArrangedSubview(body)
        content.setCustomSpacing(8, after: body)

        // Badge bình chọn + đăng lại
        if post.voteBadge != nil || post.repostLabel != nil {
            let row = UIStackView()
            row.axis = .horizontal; row.spacing = 10; row.alignment = .center
            if let badge = post.voteBadge { row.addArrangedSubview(voteBadge(badge)) }
            if let repost = post.repostLabel { row.addArrangedSubview(repostView(repost)) }
            row.addArrangedSubview(UIView())
            content.addArrangedSubview(row)
        }

        // Poll nhúng / trích dẫn
        if let poll = post.poll {
            let card = IdeaPollCardView(poll: poll) { [weak self] in self?.onOpenPoll(poll.pollId) }
            content.addArrangedSubview(card)
        } else if let quote = post.quote {
            content.addArrangedSubview(IdeaQuoteView(quote: quote))
        }

        // Hàng hành động
        content.addArrangedSubview(actionsRow(post))

        // Hairline ngăn cách bài.
        let hairline = UIView()
        hairline.backgroundColor = Theme.border
        hairline.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [avatarCol, content])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .fill
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        addSubview(hairline)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    // MARK: Sub-views
    private func voteBadge(_ text: String) -> UIView {
        let lbl = IdeaUI.label(text, 12, .light, 0x4CAF50)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .semibold)))
        chevron.tintColor = Theme.textPrimary
        let row = UIStackView(arrangedSubviews: [lbl, chevron])
        row.axis = .horizontal; row.spacing = 4; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 2, left: 8, bottom: 2, right: 8)
        row.backgroundColor = UIColor(hex: 0x74FF7A)
        row.layer.cornerRadius = 4
        row.clipsToBounds = true
        row.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func repostView(_ text: String) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "arrow.2.squarepath",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)))
        icon.tintColor = Theme.textSecondary
        let lbl = IdeaUI.label(text, 11, .medium, 0x818181)
        let row = UIStackView(arrangedSubviews: [icon, lbl])
        row.axis = .horizontal; row.spacing = 4; row.alignment = .center
        row.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func actionsRow(_ post: IdeaPost) -> UIView {
        let like = action("heart", "\(post.likes)")
        let comment = action("bubble.right", "\(post.comments)")
        let repost = action("arrow.2.squarepath", "\(post.reposts)")
        let share = UIImageView(image: UIImage(systemName: "paperplane",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)))
        share.tintColor = Theme.textSecondary
        share.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [like, comment, repost, UIView(), share])
        row.axis = .horizontal; row.spacing = 22; row.alignment = .center
        return row
    }

    private func action(_ icon: String, _ count: String) -> UIView {
        let iv = UIImageView(image: UIImage(systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)))
        iv.tintColor = Theme.textSecondary
        let lbl = IdeaUI.label(count, 12, .regular, 0x818181)
        let row = UIStackView(arrangedSubviews: [iv, lbl])
        row.axis = .horizontal; row.spacing = 5; row.alignment = .center
        return row
    }
}

// MARK: - IdeaPollCardView
/// Poll nhúng trong bài đăng (Figma "Mention"): nền #EDEDED, viền #CCCCCC, nút "Xem poll".
final class IdeaPollCardView: ThemeCardView {

    private let onTap: () -> Void

    init(poll: IdeaEmbeddedPoll, onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.track
        layer.cornerRadius = 12
        layer.borderWidth = 1
        borderUIColor = Theme.borderStrong

        let tag = IdeaUI.label(poll.tag, 11, .light, 0x202020)
        let title = IdeaUI.label(poll.title, 14, .regular, 0x202020)
        title.numberOfLines = 2

        let metrics = makeMetrics(poll)

        var xemCfg = UIButton.Configuration.filled()
        xemCfg.baseBackgroundColor = Theme.textPrimary
        xemCfg.baseForegroundColor = Theme.page
        xemCfg.cornerStyle = .small
        xemCfg.contentInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
        xemCfg.attributedTitle = AttributedString("Xem poll", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 12, weight: .regular)]))
        let xemBtn = UIButton(configuration: xemCfg)
        xemBtn.addAction(UIAction { [weak self] _ in self?.onTap() }, for: .touchUpInside)
        xemBtn.setContentHuggingPriority(.required, for: .horizontal)

        let tang = votePill("Tăng", bg: 0x74FF7A, text: 0x4CAF50)
        let giam = votePill("Giảm", bg: 0xEF5350, text: 0xF44336)
        let buttons = UIStackView(arrangedSubviews: [xemBtn, UIView(), tang, giam])
        buttons.axis = .horizontal; buttons.spacing = 8; buttons.alignment = .center

        let stack = UIStackView(arrangedSubviews: [tag, title, metrics, buttons])
        stack.axis = .vertical; stack.spacing = 8
        stack.setCustomSpacing(12, after: title)
        stack.setCustomSpacing(12, after: metrics)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13),
        ])
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { onTap() }

    private func makeMetrics(_ poll: IdeaEmbeddedPoll) -> UIView {
        let beat = column("Giá cần vượt", poll.beatPrice, valueHex: 0x818181, badge: nil)
        let now = column("Giá hiện tại", poll.nowPrice,
                         valueHex: poll.isUp ? 0x4CAF50 : 0xF44336,
                         badge: (poll.changePercent, poll.isUp))
        let divider = UIView()
        divider.backgroundColor = Theme.borderStrong
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
        let row = UIStackView(arrangedSubviews: [beat, divider, now])
        row.axis = .horizontal; row.spacing = 14; row.alignment = .fill
        beat.widthAnchor.constraint(equalTo: now.widthAnchor).isActive = true
        return row
    }

    private func column(_ caption: String, _ value: String, valueHex: UInt32,
                        badge: (String, Bool)?) -> UIView {
        let cap = IdeaUI.label(caption, 10, .light, 0x818181)
        let val = IdeaUI.label(value, 14, .semibold, valueHex)
        val.setContentHuggingPriority(.required, for: .horizontal)
        let valueRow = UIStackView(arrangedSubviews: [val])
        valueRow.axis = .horizontal; valueRow.spacing = 6; valueRow.alignment = .center
        if let (pct, up) = badge {
            valueRow.addArrangedSubview(IdeaUI.changeBadge(pct, up: up))
            valueRow.addArrangedSubview(UIView())
        }
        let col = UIStackView(arrangedSubviews: [cap, valueRow])
        col.axis = .vertical; col.spacing = 4; col.alignment = .leading
        return col
    }

    private func votePill(_ title: String, bg: UInt32, text: UInt32) -> UIView {
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = UIColor(hex: text)
        l.textAlignment = .center
        l.backgroundColor = UIColor(hex: bg, alpha: 0.15)
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.widthAnchor.constraint(equalToConstant: 60).isActive = true
        l.heightAnchor.constraint(equalToConstant: 29).isActive = true
        return l
    }
}

// MARK: - IdeaQuoteView
/// Bài trích dẫn lồng trong bài đăng: avatar nhỏ + tên · thời gian + nội dung.
final class IdeaQuoteView: ThemeCardView {
    init(quote: IdeaQuote) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.track
        layer.cornerRadius = 12
        layer.borderWidth = 1
        borderUIColor = Theme.borderStrong

        let avatar = IdeaUI.avatar(quote.username, size: 24, corner: 6, fontSize: 11)
        let name = IdeaUI.label(quote.username, 14, .medium, 0x202020)
        name.setContentHuggingPriority(.required, for: .horizontal)
        let time = IdeaUI.label("· \(quote.time)", 12, .regular, 0xB9B9B9)
        let head = UIStackView(arrangedSubviews: [avatar, name, time, UIView()])
        head.axis = .horizontal; head.spacing = 8; head.alignment = .center

        let body = IdeaUI.label(quote.content, 14, .regular, 0x818181)
        body.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [head, body])
        stack.axis = .vertical; stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - IdeaUI (helper dùng chung)
enum IdeaUI {
    static func label(_ text: String, _ size: CGFloat, _ weight: UIFont.Weight, _ hex: UInt32) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = PollDetailViewController.adaptiveColor(hex)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    /// Avatar vuông bo góc với chữ cái đầu trên nền gradient tím-xanh.
    static func avatar(_ username: String, size: CGFloat, corner: CGFloat, fontSize: CGFloat) -> UIView {
        let v = GradientView(colors: FeelitColors.avatarGradient)
        v.layer.cornerRadius = corner
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: size).isActive = true
        v.heightAnchor.constraint(equalToConstant: size).isActive = true
        let initial = UILabel()
        initial.text = username.first.map { String($0).uppercased() } ?? "?"
        initial.font = .systemFont(ofSize: fontSize, weight: .semibold)
        initial.textColor = .white
        initial.textAlignment = .center
        initial.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(initial)
        NSLayoutConstraint.activate([
            initial.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            initial.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }

    /// Badge phần trăm thay đổi (▲/▼ + %).
    static func changeBadge(_ pct: String, up: Bool) -> UIView {
        let arrow = UIImageView(image: UIImage(systemName: up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 7, weight: .bold)))
        arrow.tintColor = UIColor(hex: up ? 0x4CAF50 : 0xF44336)
        let lbl = label(pct, 9, .semibold, up ? 0x4CAF50 : 0xF44336)
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
}
