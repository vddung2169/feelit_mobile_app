import UIKit

// MARK: - ProfileViewController
/// Tab 4 — Profile: header (avatar/bio/stats/edit) + badges (horizontal) + activity feed.
final class ProfileViewController: UIViewController {

    private let viewModel = ProfileViewModel()
    private var user: FEUser { viewModel.profile }
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        setupScroll()
        stack.addArrangedSubview(makeHeader())
        stack.addArrangedSubview(makeSectionTitle("🏅 Huy hiệu"))
        stack.addArrangedSubview(makeBadges())
        stack.addArrangedSubview(makeSectionTitle("⚡ Hoạt động gần đây"))
        stack.addArrangedSubview(makeActivityCard())
    }

    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset.bottom = FeelitLayout.scrollBottomInset
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = Spacing.lg
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.lg),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.lg),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
    }

    // MARK: Header
    private func makeHeader() -> UIView {
        let card = GradientView(colors: [FeelitColors.surface.cgColor, FeelitColors.background.cgColor])
        card.layer.cornerRadius = Radius.card
        card.clipsToBounds = true

        let avatar = AvatarView(size: 80, fontSize: 32)
        avatar.configure(username: user.username)

        let username = label(user.username, FeelitFonts.heading, FeelitColors.textPrimary)
        username.textAlignment = .center
        let bio = label(user.bio, FeelitFonts.body, FeelitColors.textSecondary)
        bio.textAlignment = .center
        bio.numberOfLines = 2

        let stats = UIStackView(arrangedSubviews: [
            statColumn("Người theo dõi", "\(user.followers)"),
            statColumn("Đang theo dõi", "\(user.following)"),
            statColumn("Độ chính xác", "\(user.accuracy)%"),
        ])
        stats.distribution = .fillEqually

        var config = UIButton.Configuration.plain()
        config.title = "Chỉnh sửa hồ sơ"
        config.baseForegroundColor = FeelitColors.primary
        config.background.cornerRadius = Radius.button
        config.background.strokeColor = FeelitColors.primary
        config.background.strokeWidth = 1
        let editButton = UIButton(configuration: config)
        editButton.titleLabel?.font = FeelitFonts.title
        editButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let avatarWrap = UIStackView(arrangedSubviews: [avatar])
        avatarWrap.alignment = .center
        avatarWrap.axis = .vertical

        let col = UIStackView(arrangedSubviews: [avatarWrap, username, bio, stats, editButton])
        col.axis = .vertical
        col.spacing = Spacing.md
        col.setCustomSpacing(Spacing.lg, after: bio)
        embed(col, in: card, padding: Spacing.xl)
        return card
    }

    // MARK: Badges
    private func makeBadges() -> UIView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.heightAnchor.constraint(equalToConstant: 100).isActive = true

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = Spacing.md
        row.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)
        user.badges.forEach { row.addArrangedSubview(badgeView($0)) }

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.topAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            row.heightAnchor.constraint(equalTo: scroll.heightAnchor),
        ])
        return scroll
    }

    private func badgeView(_ badge: FEBadge) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let icon = label(badge.icon, .systemFont(ofSize: 34), FeelitColors.textPrimary)
        icon.textAlignment = .center
        let name = UILabel()
        name.setMicro(badge.name, color: FeelitColors.textSecondary)
        name.textAlignment = .center

        let col = UIStackView(arrangedSubviews: [icon, name])
        col.axis = .vertical
        col.spacing = Spacing.xs
        col.alignment = .center
        col.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(col)
        NSLayoutConstraint.activate([
            col.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            col.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            col.widthAnchor.constraint(equalTo: container.widthAnchor),
        ])

        if !badge.unlocked {
            container.alpha = 0.3
            let lock = UILabel()
            lock.text = "🔒"
            lock.font = .systemFont(ofSize: 18)
            lock.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(lock)
            NSLayoutConstraint.activate([
                lock.centerXAnchor.constraint(equalTo: icon.centerXAnchor),
                lock.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            ])
        }
        return container
    }

    // MARK: Activity
    private func makeActivityCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()
        let col = UIStackView()
        col.axis = .vertical
        col.spacing = Spacing.md
        for a in viewModel.activities { col.addArrangedSubview(activityRow(a)) }
        embed(col, in: card, padding: Spacing.lg)
        return card
    }

    private func activityRow(_ a: FEActivity) -> UIView {
        let icon = label(a.icon, FeelitFonts.title, FeelitColors.primary)
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        let text = label(a.text, FeelitFonts.body, FeelitColors.textPrimary)
        text.numberOfLines = 2
        let time = label(a.timestamp, FeelitFonts.caption, FeelitColors.textSecondary)
        let row = UIStackView(arrangedSubviews: [icon, text, UIView(), time])
        row.spacing = Spacing.md
        row.alignment = .center
        return row
    }

    // MARK: Helpers
    private func makeSectionTitle(_ text: String) -> UILabel {
        label(text, FeelitFonts.heading, FeelitColors.textPrimary)
    }

    private func label(_ text: String, _ font: UIFont, _ color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text; l.font = font; l.textColor = color
        l.numberOfLines = 0
        return l
    }

    private func statColumn(_ caption: String, _ value: String) -> UIView {
        let v = label(value, FeelitFonts.title, FeelitColors.textPrimary)
        v.textAlignment = .center
        let c = label(caption, FeelitFonts.caption, FeelitColors.textSecondary)
        c.textAlignment = .center
        let col = UIStackView(arrangedSubviews: [v, c])
        col.axis = .vertical
        col.spacing = 2
        col.alignment = .center
        return col
    }

    private func embed(_ content: UIView, in card: UIView, padding: CGFloat) {
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: padding),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: padding),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -padding),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -padding),
        ])
    }
}
