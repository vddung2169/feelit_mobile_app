import UIKit

// MARK: - GradientView
/// UIView có sẵn CAGradientLayer, tự resize theo bounds.
final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradient: CAGradientLayer { layer as! CAGradientLayer }

    init(colors: [CGColor],
         start: CGPoint = CGPoint(x: 0, y: 0),
         end: CGPoint = CGPoint(x: 1, y: 1)) {
        super.init(frame: .zero)
        gradient.colors = colors
        gradient.startPoint = start
        gradient.endPoint = end
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setColors(_ colors: [CGColor]) { gradient.colors = colors }
}

// MARK: - AvatarView
/// Avatar tròn gradient với chữ cái đầu của username.
final class AvatarView: UIView {
    private let label = UILabel()
    private let gradient = CAGradientLayer()

    init(size: CGFloat, fontSize: CGFloat) {
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        translatesAutoresizingMaskIntoConstraints = false
        gradient.colors = FeelitColors.avatarGradient
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)

        label.font = FeelitFonts.rounded(fontSize, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size),
            heightAnchor.constraint(equalToConstant: size),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        layer.cornerRadius = size / 2
        clipsToBounds = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    func configure(username: String) {
        label.text = username.first.map { String($0).uppercased() } ?? "?"
    }
}

// MARK: - ChipLabel
/// Chip bo tròn (asset tag, badge uy tín, ...).
final class ChipLabel: UILabel {
    private let inset: UIEdgeInsets
    init(insets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)) {
        self.inset = insets
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        textAlignment = .center
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: inset)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + inset.left + inset.right,
                      height: s.height + inset.top + inset.bottom)
    }

    @discardableResult
    func style(text: String, textColor: UIColor, background: UIColor,
               font: UIFont = FeelitFonts.micro, corner: CGFloat = Radius.badge) -> ChipLabel {
        self.text = text
        self.textColor = textColor
        self.backgroundColor = background
        self.font = font
        self.layer.cornerRadius = corner
        return self
    }
}

// MARK: - VoteBar
/// Thanh YES/NO split, bo pill, animate được.
final class VoteBar: UIView {
    private let yesFill = UIView()
    private let noFill = UIView()
    private var yesWidth: NSLayoutConstraint!

    init(height: CGFloat) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        layer.cornerRadius = height / 2
        backgroundColor = FeelitColors.bearish

        for v in [noFill, yesFill] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }
        noFill.backgroundColor = FeelitColors.bearish
        yesFill.backgroundColor = FeelitColors.bullish

        yesWidth = yesFill.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            noFill.topAnchor.constraint(equalTo: topAnchor),
            noFill.bottomAnchor.constraint(equalTo: bottomAnchor),
            noFill.trailingAnchor.constraint(equalTo: trailingAnchor),
            noFill.leadingAnchor.constraint(equalTo: leadingAnchor),
            yesFill.topAnchor.constraint(equalTo: topAnchor),
            yesFill.bottomAnchor.constraint(equalTo: bottomAnchor),
            yesFill.leadingAnchor.constraint(equalTo: leadingAnchor),
            yesWidth,
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Set tỉ lệ YES (0...1). animated → spring 0.4s.
    func setYesRatio(_ ratio: CGFloat, animated: Bool) {
        yesWidth.isActive = false
        yesWidth = yesFill.widthAnchor.constraint(equalTo: widthAnchor, multiplier: max(0.0001, min(1, ratio)))
        yesWidth.isActive = true
        guard animated else { layoutIfNeeded(); return }
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: Motion.damping,
                       initialSpringVelocity: Motion.velocity) { self.layoutIfNeeded() }
    }
}

// MARK: - UIView helpers
extension UIView {
    /// Style card chuẩn FEELIT: nền surface + border + corner.
    func applyCardStyle(background: UIColor = FeelitColors.surface, corner: CGFloat = Radius.card) {
        backgroundColor = background
        layer.cornerRadius = corner
        layer.borderWidth = 1
        layer.borderColor = FeelitColors.border.cgColor
    }

    /// Animation nhấn card: scale xuống rồi bật lại (spring).
    func animateTapScale(down: CGFloat = 0.96) {
        UIView.animate(withDuration: 0.12, animations: {
            self.transform = CGAffineTransform(scaleX: down, y: down)
        }, completion: { _ in
            UIView.animate(withDuration: Motion.duration, delay: 0,
                           usingSpringWithDamping: 0.8, initialSpringVelocity: Motion.velocity) {
                self.transform = .identity
            }
        })
    }
}
