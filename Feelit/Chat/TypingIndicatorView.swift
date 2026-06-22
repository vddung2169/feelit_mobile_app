import UIKit

// MARK: - TypingIndicatorView
/// Bong bóng "đang gõ" giống iMessage/Messenger: 3 chấm xám nảy lần lượt.
/// Đặt làm tableFooterView của ChatViewController để nó nằm dưới tin nhắn cuối,
/// canh trái như bubble của đối phương.
final class TypingIndicatorView: UIView {

    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray5
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let dotsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 5
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var dots: [UIView] = []
    private let dotSize: CGFloat = 8
    private let animationKey = "typingBounce"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(bubbleView)
        bubbleView.addSubview(dotsStack)

        for _ in 0..<3 {
            let dot = UIView()
            dot.backgroundColor = .secondaryLabel
            dot.layer.cornerRadius = dotSize / 2
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: dotSize),
                dot.heightAnchor.constraint(equalToConstant: dotSize)
            ])
            dots.append(dot)
            dotsStack.addArrangedSubview(dot)
        }

        NSLayoutConstraint.activate([
            bubbleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            bubbleView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            dotsStack.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            dotsStack.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            dotsStack.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 12),
            dotsStack.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Animation
    func startAnimating() {
        // Tránh add animation chồng lên nhau
        guard dots.first?.layer.animation(forKey: animationKey) == nil else { return }

        let duration: CFTimeInterval = 0.6
        for (index, dot) in dots.enumerated() {
            let bounce = CAKeyframeAnimation(keyPath: "transform")
            bounce.values = [
                CATransform3DIdentity,
                CATransform3DMakeTranslation(0, -5, 0),
                CATransform3DIdentity
            ]
            bounce.keyTimes = [0, 0.5, 1]
            bounce.duration = duration
            bounce.repeatCount = .infinity
            bounce.beginTime = CACurrentMediaTime() + Double(index) * 0.15
            bounce.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            dot.layer.add(bounce, forKey: animationKey)
        }
    }

    func stopAnimating() {
        dots.forEach { $0.layer.removeAnimation(forKey: animationKey) }
    }

    /// Kích thước vừa đủ để dùng làm tableFooterView (frame-based).
    func sizeToFitFooter(width: CGFloat) {
        let height: CGFloat = dotSize + 24 /*padding bubble*/ + 12 /*padding ngoài*/
        frame = CGRect(x: 0, y: 0, width: width, height: height)
        layoutIfNeeded()
    }
}
