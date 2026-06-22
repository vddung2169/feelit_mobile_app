import UIKit

// MARK: - FooterButton
/// Nút footer của PostCard: icon SF Symbol + số đếm. Hỗ trợ bounce + đổi màu khi like.
final class FooterButton: UIButton {

    private let symbolName: String

    init(symbol: String) {
        self.symbolName = symbol
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.imagePadding = Spacing.xs
        config.contentInsets = .zero
        config.baseForegroundColor = FeelitColors.textSecondary
        configuration = config
        titleLabel?.font = FeelitFonts.caption
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Cập nhật số đếm (nil = không hiện số).
    func setCount(_ count: Int?, color: UIColor) {
        configuration?.attributedTitle = count.map {
            AttributedString("\($0)", attributes: AttributeContainer([
                .font: FeelitFonts.caption, .foregroundColor: color
            ]))
        }
        configuration?.baseForegroundColor = color
    }

    /// Đổi sang trạng thái liked (heart.fill) hoặc bình thường.
    func setLiked(_ liked: Bool, color: UIColor) {
        configuration?.image = UIImage(systemName: liked ? "heart.fill" : symbolName)
        configuration?.baseForegroundColor = color
        if var title = configuration?.attributedTitle {
            title.foregroundColor = color
            configuration?.attributedTitle = title
        }
    }

    /// Bounce 1.0 → 1.3 → 1.0.
    func bounce() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(withDuration: 0.12, animations: {
            self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: { _ in
            UIView.animate(withDuration: Motion.duration, delay: 0,
                           usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6) {
                self.transform = .identity
            }
        })
    }
}
