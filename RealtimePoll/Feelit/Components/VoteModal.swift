import UIKit

// MARK: - VoteModal
/// Bottom sheet (~60% màn hình) để vote 1 poll. Drag-to-dismiss, haptic,
/// confetti khi vote theo phe đa số, progress animation, nút chia sẻ.
final class VoteModal: UIViewController {

    private let poll: FEPoll
    private var voted = false

    private let overlay = UIView()
    private let sheet = UIView()
    private var sheetBottom: NSLayoutConstraint!

    private let handle = UIView()
    private let titleLabel = UILabel()
    private let contextLabel = UILabel()
    private let yesButton = UIButton(type: .system)
    private let noButton = UIButton(type: .system)
    private let resultBar = VoteBar(height: 28)
    private let resultLabel = UILabel()
    private let shareButton = UIButton(type: .system)

    init(poll: FEPoll) {
        self.poll = poll
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOverlay()
        setupSheet()
        setupContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: Setup
    private func setupOverlay() {
        overlay.backgroundColor = FeelitColors.overlay
        overlay.alpha = 0
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSheet)))
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupSheet() {
        sheet.backgroundColor = FeelitColors.surface
        sheet.layer.cornerRadius = Radius.largeCard
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)

        sheetBottom = sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 600)
        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            sheetBottom,
        ])
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sheet.addGestureRecognizer(pan)
    }

    private func setupContent() {
        handle.backgroundColor = FeelitColors.surfaceElevated
        handle.layer.cornerRadius = 2
        handle.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(handle)

        titleLabel.font = FeelitFonts.heading
        titleLabel.textColor = FeelitColors.textPrimary
        titleLabel.numberOfLines = 3
        titleLabel.text = poll.title

        contextLabel.font = FeelitFonts.caption
        contextLabel.textColor = FeelitColors.textSecondary
        contextLabel.numberOfLines = 0
        contextLabel.text = "\(poll.asset)  •  ⏳ \(poll.endsIn)  •  \(poll.votesText)"

        styleBig(yesButton, title: "👍 TĂNG", subtitle: "\(poll.yesPercent)% hiện tại", color: FeelitColors.bullish)
        styleBig(noButton, title: "👎 GIẢM", subtitle: "\(poll.noPercent)% hiện tại", color: FeelitColors.bearish)
        yesButton.addTarget(self, action: #selector(yesTapped), for: .touchUpInside)
        noButton.addTarget(self, action: #selector(noTapped), for: .touchUpInside)

        resultBar.isHidden = true
        resultLabel.font = FeelitFonts.title
        resultLabel.textColor = FeelitColors.textPrimary
        resultLabel.textAlignment = .center
        resultLabel.isHidden = true

        shareButton.setTitle("📤 Chia sẻ nhận định", for: .normal)
        shareButton.setTitleColor(FeelitColors.primary, for: .normal)
        shareButton.titleLabel?.font = FeelitFonts.title
        shareButton.isHidden = true

        let buttons = UIStackView(arrangedSubviews: [yesButton, noButton])
        buttons.axis = .vertical
        buttons.spacing = Spacing.md
        buttons.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [titleLabel, contextLabel, buttons, resultBar, resultLabel, shareButton])
        stack.axis = .vertical
        stack.spacing = Spacing.lg
        stack.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(stack)

        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: sheet.topAnchor, constant: Spacing.md),
            handle.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 36),
            handle.heightAnchor.constraint(equalToConstant: 4),

            stack.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: Spacing.xl),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: Spacing.xl),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -Spacing.xl),

            yesButton.heightAnchor.constraint(equalToConstant: 64),
            noButton.heightAnchor.constraint(equalToConstant: 64),
        ])
    }

    private func styleBig(_ b: UIButton, title: String, subtitle: String, color: UIColor) {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.cornerStyle = .fixed
        config.background.cornerRadius = Radius.smallCard
        var titleAttr = AttributedString(title)
        titleAttr.font = .systemFont(ofSize: 18, weight: .bold)
        config.attributedTitle = titleAttr
        var subAttr = AttributedString(subtitle)
        subAttr.font = FeelitFonts.caption
        config.attributedSubtitle = subAttr
        config.titleAlignment = .center
        b.configuration = config
    }

    // MARK: Animate
    private func animateIn() {
        sheetBottom.constant = 0
        UIView.animate(withDuration: Motion.duration, delay: 0,
                       usingSpringWithDamping: Motion.damping, initialSpringVelocity: Motion.velocity) {
            self.overlay.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    @objc private func dismissSheet() {
        sheetBottom.constant = 700
        UIView.animate(withDuration: Motion.duration, animations: {
            self.overlay.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: { _ in self.dismiss(animated: false) })
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let t = g.translation(in: sheet).y
        switch g.state {
        case .changed:
            sheetBottom.constant = max(0, t)
        case .ended:
            if t > 120 { dismissSheet() }
            else { animateIn() }
        default: break
        }
    }

    // MARK: Vote
    @objc private func yesTapped() { vote(yes: true) }
    @objc private func noTapped() { vote(yes: false) }

    private func vote(yes: Bool) {
        guard !voted else { return }
        voted = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        yesButton.isHidden = true
        noButton.isHidden = true
        resultBar.isHidden = false
        resultLabel.isHidden = false
        shareButton.isHidden = false
        resultLabel.text = "TĂNG \(poll.yesPercent)%  •  GIẢM \(poll.noPercent)%"

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: Motion.damping,
                       initialSpringVelocity: Motion.velocity) {
            self.resultBar.setYesRatio(CGFloat(self.poll.yesPercent) / 100, animated: false)
            self.sheet.layoutIfNeeded()
        }

        let majority = (yes && poll.yesPercent >= 50) || (!yes && poll.noPercent >= 50)
        if majority { fireConfetti() }
    }

    // MARK: Confetti
    private func fireConfetti() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: sheet.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: sheet.bounds.width, height: 1)

        let colors = [FeelitColors.primary, FeelitColors.bullish, FeelitColors.gold, FeelitColors.bearish]
        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 4
            cell.velocity = 180
            cell.velocityRange = 60
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 6
            cell.spin = 3
            cell.spinRange = 4
            cell.scale = 0.5
            cell.scaleRange = 0.3
            cell.color = color.cgColor
            cell.contents = Self.confettiImage().cgImage
            return cell
        }
        sheet.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { emitter.birthRate = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { emitter.removeFromSuperlayer() }
    }

    private static func confettiImage() -> UIImage {
        let size = CGSize(width: 8, height: 8)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
