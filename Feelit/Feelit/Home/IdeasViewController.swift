import UIKit

// MARK: - Mô hình dữ liệu (mock)
/// Poll nhúng trong bài đăng ý tưởng.
struct IdeaEmbeddedPoll {
    let pollId: String          // map sang PollFeedData.items để mở chi tiết
    let tag: String             // "Crypto · Hàng giờ"
    let title: String
    let beatPrice: String       // "Giá cần vượt"
    let nowPrice: String        // "Giá hiện tại"
    let changePercent: String   // "11%"
    let isUp: Bool
}

/// Bài trích dẫn (quote) một bài khác.
struct IdeaQuote {
    let username: String
    let time: String
    let content: String
}

/// Một bài đăng trong feed Ý tưởng (Figma 481-24229).
struct IdeaPost {
    let username: String
    let time: String
    let content: String
    var voteBadge: String? = nil       // "Tăng · 15% · 19 th 06"
    var repostLabel: String? = nil     // "fin.enjoyer đã đăng lại"
    var poll: IdeaEmbeddedPoll? = nil
    var quote: IdeaQuote? = nil
    var threadBelow: Bool = false      // có đường nối thread xuống dưới
    var likes: Int = 0
    var comments: Int = 0
    var reposts: Int = 0
}

enum IdeasData {
    static let tabs = ["Dành cho bạn", "Đang theo dõi", "Xu hướng"]

    static let posts: [IdeaPost] = [
        IdeaPost(username: "fin.enjoyer", time: "19 thg 06",
                 content: "Khả năng là sẽ tăng đấy các bảnh à tại mình có xài bùa may mắn",
                 voteBadge: "Tăng · 15% · 19 th 06",
                 poll: IdeaEmbeddedPoll(pollId: "btc", tag: "Crypto · Hàng giờ",
                                        title: "Giá Bitcoin ngày mai lúc 10:00AM",
                                        beatPrice: "$62,757.48", nowPrice: "$69,660.27",
                                        changePercent: "11%", isUp: true),
                 threadBelow: true, likes: 15, comments: 2, reposts: 1),

        IdeaPost(username: "michael.hudon", time: "5h",
                 content: "Đúng gòi @fin.enjoyer, BTC đang consolidate ở vùng $68k~$70k. Breakout là chắc chắn 📈",
                 voteBadge: "Tăng · 8% · 20 th 06",
                 likes: 15, comments: 2, reposts: 1),

        IdeaPost(username: "dauxe.chonguoi.tantat", time: "2h",
                 content: "FOMC meeting tuần tới sẽ quyết định xu hướng của toàn bộ #DeFi và #Bitcoin. Mọi người nên theo dõi sát.",
                 repostLabel: "fin.enjoyer đã đăng lại",
                 likes: 15, comments: 2, reposts: 1),

        IdeaPost(username: "nguyen.trades", time: "23 thg 06",
                 content: "Vừa vote Tăng trên poll #ETH/USD. Dự đoán ETH sẽ test lại $3,800 trước cuối tuần này. Ai cùng view không?",
                 voteBadge: "Tăng · 5% · 23 th 06",
                 poll: IdeaEmbeddedPoll(pollId: "eth", tag: "Crypto · Hàng giờ",
                                        title: "Giá ETH cuối tuần này sẽ vượt $3,800?",
                                        beatPrice: "$3,800.00", nowPrice: "$3,542.10",
                                        changePercent: "11%", isUp: true),
                 threadBelow: true, likes: 15, comments: 2, reposts: 1),

        IdeaPost(username: "long.pham", time: "1h",
                 content: "@nguyen.trades — view đồng ý, nhưng volume vẫn yếu. Cẩn thận fakeout cuối tuần nhé.",
                 quote: IdeaQuote(username: "nguyen.trades", time: "23 thg 06",
                                  content: "Vừa vote Tăng trên poll #ETH/USD. Dự đoán ETH sẽ test lại $3,800 trước cuối tuần này."),
                 likes: 15, comments: 2, reposts: 1),
    ]
}

// MARK: - IdeasViewController
/// Tab "Ý tưởng" (Figma 481-24229 "Ý Tưởng | Home"): tab phân loại + feed bài đăng dạng
/// mạng xã hội (avatar, nội dung, badge bình chọn, poll nhúng / trích dẫn, hành động).
final class IdeasViewController: UIViewController {

    private let tabs = IdeasData.tabs
    private var selectedTab = 0
    private var tabButtons: [UIButton] = []
    private var underline: UIView?
    private var underlineConstraints: [NSLayoutConstraint] = []

    private let tabsRow = UIStackView()
    private let scroll = UIScrollView()
    private let list = UIStackView()

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

    private lazy var fab: UIButton = {
        var c = UIButton.Configuration.filled()
        c.baseBackgroundColor = Theme.textPrimary
        c.baseForegroundColor = Theme.page
        c.image = UIImage(systemName: "plus",
                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold))
        c.cornerStyle = .capsule
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.alpha = 0                       // ẩn lúc đầu, hiện khi cuộn xuống
        b.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.2
        b.layer.shadowRadius = 8
        b.layer.shadowOffset = CGSize(width: 0, height: 4)
        b.addAction(UIAction { [weak self] _ in self?.presentComposer() }, for: .touchUpInside)
        return b
    }()
    private var fabShown = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupList()
        setupTabs()   // sau setupList để lớp kính nằm trên danh sách
        setupFab()
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let top = headerBar.frame.height
        guard top > 0, abs(scroll.contentInset.top - top) > 0.5 else { return }
        scroll.contentInset.top = top
        scroll.verticalScrollIndicatorInsets.top = top
        scroll.contentOffset.y = -top
    }

    private func setupFab() {
        scroll.delegate = self
        view.addSubview(fab)
        NSLayoutConstraint.activate([
            fab.widthAnchor.constraint(equalToConstant: 56),
            fab.heightAnchor.constraint(equalToConstant: 56),
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // Nâng cao hơn thanh tab bar nổi (iOS 26) để không bị che.
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -88),
        ])
    }

    private func setFab(shown: Bool) {
        guard shown != fabShown else { return }
        fabShown = shown
        UIView.animate(withDuration: 0.25) {
            self.fab.alpha = shown ? 1 : 0
            self.fab.transform = shown ? .identity : CGAffineTransform(scaleX: 0.6, y: 0.6)
        }
    }

    // MARK: Tabs
    private func setupTabs() {
        tabsRow.axis = .horizontal
        tabsRow.spacing = 8
        tabsRow.alignment = .center
        tabsRow.translatesAutoresizingMaskIntoConstraints = false

        for (i, t) in tabs.enumerated() {
            var config = UIButton.Configuration.plain()
            config.attributedTitle = AttributedString(t, attributes:
                AttributeContainer([.font: UIFont.systemFont(ofSize: 13, weight: .medium)]))
            config.baseForegroundColor = Theme.textTertiary
            config.contentInsets = .init(top: 8, leading: 4, bottom: 8, trailing: 4)
            let b = UIButton(configuration: config)
            b.tag = i
            b.addAction(UIAction { [weak self] _ in self?.selectTab(i) }, for: .touchUpInside)
            tabButtons.append(b)
            tabsRow.addArrangedSubview(b)
        }

        // Vạch chọn (underline) dưới tab đang chọn.
        let ul = UIView()
        ul.backgroundColor = Theme.textPrimary
        ul.layer.cornerRadius = 1
        ul.translatesAutoresizingMaskIntoConstraints = false
        underline = ul

        // Hairline dưới toàn bộ hàng tab.
        let hairline = UIView()
        hairline.backgroundColor = Theme.border
        hairline.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerBar)
        headerBar.contentView.addSubview(tabsRow)
        headerBar.contentView.addSubview(hairline)
        headerBar.contentView.addSubview(ul)
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 42),

            tabsRow.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            tabsRow.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 16),

            hairline.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
            hairline.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            ul.bottomAnchor.constraint(equalTo: hairline.topAnchor),
            ul.heightAnchor.constraint(equalToConstant: 2),
        ])
        updateTabs()
    }

    private func updateTabs() {
        for (i, b) in tabButtons.enumerated() {
            let selected = i == selectedTab
            b.configuration?.baseForegroundColor = selected ? Theme.textPrimary : Theme.textTertiary
            var c = b.configuration
            c?.attributedTitle = AttributedString(tabs[i], attributes:
                AttributeContainer([.font: UIFont.systemFont(ofSize: 13, weight: selected ? .semibold : .regular)]))
            b.configuration = c
        }
        // Neo underline vào tab đang chọn (gỡ ràng buộc cũ trước khi thêm mới).
        NSLayoutConstraint.deactivate(underlineConstraints)
        if let ul = underline {
            let target = tabButtons[selectedTab]
            underlineConstraints = [
                ul.leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: 4),
                ul.trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: -4),
            ]
            NSLayoutConstraint.activate(underlineConstraints)
        }
    }

    private func selectTab(_ i: Int) {
        selectedTab = i
        updateTabs()
        // Về đầu danh sách (ngay dưới header kính), không phải y=0 tuyệt đối.
        scroll.setContentOffset(CGPoint(x: 0, y: -scroll.contentInset.top), animated: false)
    }

    // MARK: List
    private func setupList() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset.bottom = 130
        view.addSubview(scroll)

        list.axis = .vertical
        list.spacing = 0
        list.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(list)

        NSLayoutConstraint.activate([
            // Cuộn toàn màn để nội dung trôi dưới lớp kính header.
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            list.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            list.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            list.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            list.widthAnchor.constraint(equalTo: scroll.widthAnchor),
        ])
    }

    private func reload() {
        list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // Ô gợi ý đăng bài kiểu Threads "Có gì mới?".
        list.addArrangedSubview(makePrompt())
        for post in IdeasData.posts {
            let v = IdeaPostView(post: post) { [weak self] pollId in self?.openPoll(pollId) }
            list.addArrangedSubview(v)
        }
    }

    // MARK: "Có gì mới?" prompt
    private func makePrompt() -> UIView {
        let avatar = IdeaUI.avatar("fin.enjoyer", size: 40, corner: 10, fontSize: 16)
        let name = IdeaUI.label("fin.enjoyer", 15, .semibold, 0x202020)
        let placeholder = IdeaUI.label("Có gì mới?", 14, .regular, 0xB9B9B9)
        let col = UIStackView(arrangedSubviews: [name, placeholder])
        col.axis = .vertical; col.spacing = 2

        var pc = UIButton.Configuration.filled()
        pc.baseBackgroundColor = Theme.textPrimary
        pc.baseForegroundColor = Theme.page
        pc.cornerStyle = .capsule
        pc.contentInsets = .init(top: 6, leading: 16, bottom: 6, trailing: 16)
        pc.attributedTitle = AttributedString("Đăng", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 13, weight: .semibold)]))
        let postBtn = UIButton(configuration: pc)
        postBtn.setContentHuggingPriority(.required, for: .horizontal)
        postBtn.addAction(UIAction { [weak self] _ in self?.presentComposer() }, for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [avatar, col, postBtn])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false

        let hairline = UIView()
        hairline.backgroundColor = Theme.border
        hairline.translatesAutoresizingMaskIntoConstraints = false

        let wrap = UIView()
        wrap.addSubview(row); wrap.addSubview(hairline)
        wrap.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(promptTapped)))
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 14),
            row.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -14),
            hairline.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),
        ])
        return wrap
    }

    @objc private func promptTapped() { presentComposer() }

    private func presentComposer() {
        let vc = ComposerViewController()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom { _ in 420 }, .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }
        present(vc, animated: true)
    }

    private func openPoll(_ pollId: String) {
        let item = PollFeedData.items.first { $0.id == pollId } ?? PollFeedData.items[0]
        navigationController?.pushViewController(
            PollDetailViewController(item: item, softVoteButtons: true), animated: true)
    }
}

// MARK: - UIScrollViewDelegate (hiện nút + khi cuộn xuống)
extension IdeasViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setFab(shown: scrollView.contentOffset.y > 120)
    }
}
