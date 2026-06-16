import UIKit
import SwiftUI

// MARK: - PortfolioViewController
/// Tab 3 — Portfolio: header accuracy + performance chart + recent predictions + rewards.
final class PortfolioViewController: UIViewController {

    private let user = FEMock.user
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FeelitColors.background
        setupScroll()
        stack.addArrangedSubview(makeHeaderCard())
        stack.addArrangedSubview(makeChartCard())
        stack.addArrangedSubview(makeSectionTitle("📌 Dự đoán gần đây"))
        stack.addArrangedSubview(makePredictionsCard())
        stack.addArrangedSubview(makeRewardsCard())
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
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.lg),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.lg),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.lg),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
    }

    // MARK: Header card
    private func makeHeaderCard() -> UIView {
        let card = GradientView(colors: [FeelitColors.primary.withAlphaComponent(0.6).cgColor,
                                         FeelitColors.surface.cgColor])
        card.layer.cornerRadius = Radius.card
        card.clipsToBounds = true

        let caption = label("Độ chính xác của bạn", FeelitFonts.caption, FeelitColors.textSecondary)
        let big = label("\(user.accuracy)%", FeelitFonts.display, FeelitColors.bullish)
        let rank = label("Xếp hạng #\(user.rank) / \(user.totalUsers)", FeelitFonts.caption, FeelitColors.textSecondary)

        let stats = UIStackView(arrangedSubviews: [
            statColumn("Đã vote", "\(user.totalVotes)"),
            statColumn("Đúng", "\(user.correctVotes)"),
            statColumn("Streak", "🔥\(user.streak)"),
        ])
        stats.distribution = .fillEqually

        let col = UIStackView(arrangedSubviews: [caption, big, rank, stats])
        col.axis = .vertical
        col.spacing = Spacing.sm
        col.setCustomSpacing(Spacing.lg, after: rank)
        embed(col, in: card, padding: Spacing.xl)
        return card
    }

    // MARK: Chart card (Swift Charts qua UIHostingController)
    private func makeChartCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()
        let title = label("📈 Hiệu suất 7 ngày", FeelitFonts.title, FeelitColors.textPrimary)

        let values: [Double] = [0.45, 0.52, 0.48, 0.61, 0.58, 0.7, 0.73]
        let host = UIHostingController(rootView: PerformanceChart(values: values))
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.heightAnchor.constraint(equalToConstant: 160).isActive = true
        addChild(host)

        let col = UIStackView(arrangedSubviews: [title, host.view])
        col.axis = .vertical
        col.spacing = Spacing.md
        embed(col, in: card, padding: Spacing.xl)
        host.didMove(toParent: self)
        return card
    }

    // MARK: Predictions
    private func makePredictionsCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()
        let col = UIStackView()
        col.axis = .vertical
        col.spacing = Spacing.md
        for p in FEMock.predictions { col.addArrangedSubview(predictionRow(p)) }
        embed(col, in: card, padding: Spacing.lg)
        return card
    }

    private func predictionRow(_ p: FEPrediction) -> UIView {
        let chip = ChipLabel()
        chip.style(text: p.asset, textColor: FeelitColors.primary, background: FeelitColors.primarySoft)

        let dir = label(p.isBullish ? "↑ Tăng" : "↓ Giảm", FeelitFonts.body,
                        p.isBullish ? FeelitColors.bullish : FeelitColors.bearish)

        let result = ChipLabel()
        switch p.result {
        case .correct: result.style(text: "✓ Đúng", textColor: FeelitColors.bullish, background: FeelitColors.bullishSoft)
        case .wrong:   result.style(text: "✗ Sai", textColor: FeelitColors.bearish, background: FeelitColors.bearishSoft)
        case .pending: result.style(text: "⏳ Đang chờ", textColor: FeelitColors.textSecondary, background: FeelitColors.surfaceElevated)
        }

        let time = label(p.timestamp, FeelitFonts.caption, FeelitColors.textSecondary)
        let row = UIStackView(arrangedSubviews: [chip, dir, UIView(), result, time])
        row.spacing = Spacing.sm
        row.alignment = .center
        return row
    }

    // MARK: Rewards
    private func makeRewardsCard() -> UIView {
        let card = UIView()
        card.applyCardStyle()
        card.layer.borderColor = FeelitColors.gold.cgColor

        let title = label("🏆 Điểm thưởng", FeelitFonts.heading, FeelitColors.gold)
        let points = label("\(user.points) pts", FeelitFonts.display, FeelitColors.gold)

        var config = UIButton.Configuration.filled()
        config.title = "Đổi thưởng"
        config.baseBackgroundColor = FeelitColors.gold
        config.baseForegroundColor = .black
        config.cornerStyle = .fixed
        config.background.cornerRadius = Radius.button
        let button = UIButton(configuration: config)
        button.titleLabel?.font = FeelitFonts.title
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let col = UIStackView(arrangedSubviews: [title, points, button])
        col.axis = .vertical
        col.spacing = Spacing.md
        embed(col, in: card, padding: Spacing.xl)
        return card
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
        let c = label(caption, FeelitFonts.caption, FeelitColors.textSecondary)
        let col = UIStackView(arrangedSubviews: [v, c])
        col.axis = .vertical
        col.spacing = 2
        col.alignment = .leading
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
