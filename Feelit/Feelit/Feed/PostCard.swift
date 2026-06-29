import UIKit

// MARK: - PostCardDelegate
protocol PostCardDelegate: AnyObject {
    func postCard(_ cell: PostCard, didTapComment postId: String, postTitle: String, commentCount: Int)
    func postCard(_ cell: PostCard, didTapLike postId: String)
}

// MARK: - PostCard
/// Cell post trong Feed: header (avatar/username/badge/time) + content + tags
/// + poll embed (vote YES/NO → progress) + footer (like/comment/share/bookmark).
final class PostCard: UICollectionViewCell {
    static let reuseId = "PostCard"

    // Header
    private let avatar = AvatarView(size: 40, fontSize: 17)
    private let usernameLabel = UILabel()
    private let badgeChip = ChipLabel()
    private let timeLabel = UILabel()
    private let moreButton = UIButton(type: .system)

    // Content
    private let contentLabel = UILabel()
    private let seeMoreButton = UIButton(type: .system)
    private let tagsStack = UIStackView()

    // Poll embed
    private let pollEmbed = UIView()
    private let pollTitle = UILabel()
    private let yesButton = UIButton(type: .system)
    private let noButton = UIButton(type: .system)
    private let buttonsRow = UIStackView()
    private let resultBar = VoteBar(height: 36)
    private let resultLabels = UILabel()

    // Footer
    private let likeButton = FooterButton(symbol: "heart")
    private let commentButton = FooterButton(symbol: "bubble.left")
    private let shareButton = FooterButton(symbol: "square.and.arrow.up")
    private let bookmarkButton = UIButton(type: .system)

    private var poll: FEPoll?
    private var voted = false
    private var liked = false
    var onNeedsLayout: (() -> Void)?

    weak var delegate: PostCardDelegate?

    // Lưu lại để truyền cho delegate khi bấm comment/like.
    private var postId = ""
    private var postContent = ""
    private var commentCount = 0
    private var likeCount = 0

    private lazy var contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = Spacing.md
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Setup
    private func setup() {
        if #available(iOS 26.0, *) {
            contentView.applyLiquidGlassCardStyle()
        } else {
            contentView.applyCardStyle()   // giữ nguyên dòng hiện tại
        }
        contentView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.lg),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.lg),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.lg),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.lg),
        ])
        contentStack.addArrangedSubview(makeHeaderRow())
        contentStack.addArrangedSubview(makeContentBlock())
        contentStack.addArrangedSubview(makePollEmbed())
        contentStack.addArrangedSubview(makeFooterRow())
    }

    private func makeHeaderRow() -> UIView {
        usernameLabel.font = FeelitFonts.title
        usernameLabel.textColor = FeelitColors.textPrimary
        timeLabel.font = FeelitFonts.caption
        timeLabel.textColor = FeelitColors.textSecondary
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = FeelitColors.textSecondary

        let nameRow = UIStackView(arrangedSubviews: [usernameLabel, badgeChip])
        nameRow.spacing = Spacing.sm
        nameRow.alignment = .center
        let textCol = UIStackView(arrangedSubviews: [nameRow, timeLabel])
        textCol.axis = .vertical
        textCol.spacing = 2

        let row = UIStackView(arrangedSubviews: [avatar, textCol, UIView(), moreButton])
        row.spacing = Spacing.md
        row.alignment = .center
        return row
    }

    private func makeContentBlock() -> UIView {
        contentLabel.font = FeelitFonts.body
        contentLabel.textColor = FeelitColors.textPrimary
        contentLabel.numberOfLines = 3

        seeMoreButton.setTitle("Xem thêm", for: .normal)
        seeMoreButton.setTitleColor(FeelitColors.primary, for: .normal)
        seeMoreButton.titleLabel?.font = FeelitFonts.caption
        seeMoreButton.contentHorizontalAlignment = .leading
        seeMoreButton.addTarget(self, action: #selector(seeMoreTapped), for: .touchUpInside)

        tagsStack.axis = .horizontal
        tagsStack.spacing = Spacing.sm

        let col = UIStackView(arrangedSubviews: [contentLabel, seeMoreButton, tagsStack])
        col.axis = .vertical
        col.spacing = Spacing.sm
        col.alignment = .leading
        return col
    }

    private func makePollEmbed() -> UIView {
        if #available(iOS 26.0, *) {
            pollEmbed.applyLiquidGlassCardStyle(corner: Radius.smallCard)
        } else {
            pollEmbed.backgroundColor = FeelitColors.surfaceElevated
            pollEmbed.layer.cornerRadius = Radius.smallCard
        }

        pollTitle.font = FeelitFonts.caption
        pollTitle.textColor = FeelitColors.textSecondary
        pollTitle.numberOfLines = 2

        styleVoteButton(yesButton, title: "👍 YES", color: FeelitColors.bullish, soft: FeelitColors.bullishSoft)
        styleVoteButton(noButton, title: "👎 NO", color: FeelitColors.bearish, soft: FeelitColors.bearishSoft)
        yesButton.addTarget(self, action: #selector(yesTapped), for: .touchUpInside)
        noButton.addTarget(self, action: #selector(noTapped), for: .touchUpInside)

        buttonsRow.addArrangedSubview(yesButton)
        buttonsRow.addArrangedSubview(noButton)
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = Spacing.md
        buttonsRow.distribution = .fillEqually

        resultBar.isHidden = true
        resultLabels.font = FeelitFonts.micro
        resultLabels.textColor = FeelitColors.textSecondary
        resultLabels.isHidden = true

        // Vertical stack → ẩn buttonsRow sau khi vote sẽ tự collapse, không để lại khoảng trống.
        let embedStack = UIStackView(arrangedSubviews: [pollTitle, buttonsRow, resultBar, resultLabels])
        embedStack.axis = .vertical
        embedStack.spacing = Spacing.md
        embedStack.translatesAutoresizingMaskIntoConstraints = false
        pollEmbed.addSubview(embedStack)

        NSLayoutConstraint.activate([
            embedStack.topAnchor.constraint(equalTo: pollEmbed.topAnchor, constant: Spacing.md),
            embedStack.leadingAnchor.constraint(equalTo: pollEmbed.leadingAnchor, constant: Spacing.md),
            embedStack.trailingAnchor.constraint(equalTo: pollEmbed.trailingAnchor, constant: -Spacing.md),
            embedStack.bottomAnchor.constraint(equalTo: pollEmbed.bottomAnchor, constant: -Spacing.md),
            yesButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        return pollEmbed
    }

    private func makeFooterRow() -> UIView {
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(commentTapped), for: .touchUpInside)
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = FeelitColors.textSecondary
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [likeButton, commentButton, shareButton, UIView(), bookmarkButton])
        row.spacing = Spacing.xl
        row.alignment = .center
        return row
    }

    private func styleVoteButton(_ b: UIButton, title: String, color: UIColor, soft: UIColor) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = color
        config.baseBackgroundColor = soft
        config.cornerStyle = .fixed
        config.background.cornerRadius = 10
        config.background.strokeColor = color
        config.background.strokeWidth = 1
        b.configuration = config
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
    }

    // MARK: Configure
    func configure(with post: FEPost) {
        postId = post.id
        postContent = post.content
        commentCount = post.comments
        likeCount = post.likes

        avatar.configure(username: post.user)
        usernameLabel.text = post.user
        badgeChip.style(text: post.badge, textColor: .black, background: FeelitColors.gold)
        badgeChip.isHidden = post.badge.isEmpty
        timeLabel.text = post.timestamp
        contentLabel.text = post.content

        tagsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        post.tags.forEach { tag in
            let chip = ChipLabel()
            chip.style(text: tag, textColor: FeelitColors.primary, background: FeelitColors.primarySoft)
            tagsStack.addArrangedSubview(chip)
        }
        tagsStack.addArrangedSubview(UIView())

        if let poll = post.embeddedPoll {
            self.poll = poll
            pollEmbed.isHidden = false
            pollTitle.text = poll.title
        } else {
            pollEmbed.isHidden = true
        }

        // Khôi phục trạng thái tim đã lưu (giữ màu đỏ sau khi mở lại app).
        liked = LikeStore.shared.isLiked(post.id)
        let likeColor = liked ? FeelitColors.bearish : FeelitColors.textSecondary
        likeButton.setLiked(liked, color: likeColor)
        likeButton.setCount(post.likes, color: likeColor)
        commentButton.setCount(post.comments, color: FeelitColors.textSecondary)
        shareButton.setCount(nil, color: FeelitColors.textSecondary)
    }

    // MARK: Actions
    @objc private func seeMoreTapped() {
        contentLabel.numberOfLines = 0
        seeMoreButton.isHidden = true
        onNeedsLayout?()
    }

    @objc private func yesTapped() { castVote(yes: true) }
    @objc private func noTapped() { castVote(yes: false) }

    private func castVote(yes: Bool) {
        guard let poll = poll, !voted else { return }
        voted = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let tapped = yes ? yesButton : noButton
        UIView.animate(withDuration: 0.15, animations: {
            tapped.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }, completion: { _ in
            UIView.animate(withDuration: 0.15) { tapped.transform = .identity }
        })

        buttonsRow.isHidden = true
        resultBar.isHidden = false
        resultLabels.isHidden = false
        resultLabels.text = "TĂNG \(poll.yesPercent)%      GIẢM \(poll.noPercent)%"
        resultBar.setYesRatio(CGFloat(poll.yesPercent) / 100, animated: true)
        onNeedsLayout?()
    }

    @objc private func commentTapped() {
        delegate?.postCard(self, didTapComment: postId, postTitle: postContent, commentCount: commentCount)
    }

    @objc private func likeTapped() {
        // Optimistic UI: đổi trạng thái + cập nhật số ngay.
        liked.toggle()
        likeCount += liked ? 1 : -1
        LikeStore.shared.setLiked(postId, liked)   // nhớ trạng thái qua các lần mở app
        let color = liked ? FeelitColors.bearish : FeelitColors.textSecondary
        likeButton.setLiked(liked, color: color)
        likeButton.setCount(likeCount, color: color)
        likeButton.bounce()   // scale 1.0 → 1.3 → 1.0 + haptic .light

        delegate?.postCard(self, didTapLike: postId)
    }

    @objc private func bookmarkTapped() {
        let filled = bookmarkButton.currentImage == UIImage(systemName: "bookmark")
        bookmarkButton.setImage(UIImage(systemName: filled ? "bookmark.fill" : "bookmark"), for: .normal)
        bookmarkButton.tintColor = filled ? FeelitColors.gold : FeelitColors.textSecondary
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        voted = false
        liked = false
        contentLabel.numberOfLines = 3
        seeMoreButton.isHidden = false
        buttonsRow.isHidden = false
        resultBar.isHidden = true
        resultLabels.isHidden = true
        likeButton.setLiked(false, color: FeelitColors.textSecondary)
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = FeelitColors.textSecondary
    }
}
