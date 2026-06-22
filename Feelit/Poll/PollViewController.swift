import UIKit
import Combine

final class PollViewController: UIViewController {

    // MARK: - State
    private let poll: Poll                 // giữ để share poll vào chat
    private let viewModel: PollViewModel
    private var cancellables = Set<AnyCancellable>()
    private var didShowWinner = false

    init(poll: Poll) {
        self.poll = poll
        self.viewModel = PollViewModel(poll: poll)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Elements

    // Header
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .label
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let countdownLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 28, weight: .semibold)
        l.textColor = .systemOrange
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let connectionBadge: UILabel = {
        let l = UILabel()
        l.text = "● Connecting"
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .systemGray
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Vote totals
    private let yesPercentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .systemGreen
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let noPercentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = .systemRed
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let progressBar: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .default)
        p.trackTintColor = .systemRed.withAlphaComponent(0.3)
        p.progressTintColor = .systemGreen
        p.layer.cornerRadius = 6
        p.clipsToBounds = true
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()

    private let voteTotalsLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Chart (pure UIKit — no third-party library)
    private let chartView: PollChartView = {
        let c = PollChartView()
        c.translatesAutoresizingMaskIntoConstraints = false
        c.layer.cornerRadius = 12
        c.backgroundColor = UIColor.secondarySystemBackground
        return c
    }()

    // Vote buttons
    private let yesButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "👍  YES"
        config.baseBackgroundColor = .systemGreen
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = .systemFont(ofSize: 20, weight: .bold); return a
        }
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let noButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "👎  NO"
        config.baseBackgroundColor = .systemRed
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = .systemFont(ofSize: 20, weight: .bold); return a
        }
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let winnerBanner: UIView = {
        let v = UIView()
        v.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.systemYellow.cgColor
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let winnerLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .heavy)
        l.textColor = .label
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.hidesWhenStopped = true
        a.translatesAutoresizingMaskIntoConstraints = false
        return a
    }()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .systemRed
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        bindViewModel()
        viewModel.onViewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.onViewDisappear()
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.$pollTitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.titleLabel.text = $0 }
            .store(in: &cancellables)

        viewModel.$countdownText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.countdownLabel.text = text
                self?.updateCountdownColor()
            }
            .store(in: &cancellables)

        viewModel.$isUrgent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateCountdownColor() }
            .store(in: &cancellables)

        viewModel.$yesPercentageText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.yesPercentLabel.text = $0 }
            .store(in: &cancellables)

        viewModel.$noPercentageText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.noPercentLabel.text = $0 }
            .store(in: &cancellables)

        viewModel.$progressValue
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                UIView.animate(withDuration: 0.4) { self?.progressBar.setProgress(value, animated: true) }
            }
            .store(in: &cancellables)

        viewModel.$voteTotalsText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.voteTotalsLabel.text = $0 }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$canVote, viewModel.$isVotingLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canVote, loading in
                let enabled = canVote && !loading
                self?.yesButton.isEnabled = enabled
                self?.noButton.isEnabled = enabled
            }
            .store(in: &cancellables)

        viewModel.$isVotingLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading { self?.activityIndicator.startAnimating() }
                else { self?.activityIndicator.stopAnimating() }
            }
            .store(in: &cancellables)

        viewModel.$voteButtonSubtitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] subtitle in
                self?.yesButton.configuration?.subtitle = subtitle
                self?.noButton.configuration?.subtitle = subtitle
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                if let message = message {
                    self?.errorLabel.text = message
                    self?.errorLabel.isHidden = false
                } else {
                    self?.errorLabel.isHidden = true
                }
            }
            .store(in: &cancellables)

        viewModel.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in self?.applyConnectionStatus(status) }
            .store(in: &cancellables)

        viewModel.$chartEntries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in self?.chartView.setData(entries) }
            .store(in: &cancellables)

        viewModel.$winnerInfo
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] info in self?.presentWinner(info) }
            .store(in: &cancellables)
    }

    private func updateCountdownColor() {
        if viewModel.countdownText == "ENDED" {
            countdownLabel.textColor = .secondaryLabel
        } else if viewModel.isUrgent {
            countdownLabel.textColor = .systemRed
        } else {
            countdownLabel.textColor = .systemOrange
        }
    }

    private func applyConnectionStatus(_ status: PollViewModel.ConnectionStatus) {
        switch status {
        case .connecting:
            connectionBadge.text = "● Connecting"; connectionBadge.textColor = .systemGray
        case .live:
            connectionBadge.text = "● Live"; connectionBadge.textColor = .systemGreen
        case .reconnecting:
            connectionBadge.text = "● Reconnecting..."; connectionBadge.textColor = .systemOrange
        case .ended:
            connectionBadge.text = "● Ended"; connectionBadge.textColor = .secondaryLabel
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Live Poll"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(sharePollTapped))

        // % row
        let percentRow = UIStackView(arrangedSubviews: [yesPercentLabel, noPercentLabel])
        percentRow.distribution = .equalSpacing
        percentRow.translatesAutoresizingMaskIntoConstraints = false

        // Winner banner
        winnerBanner.addSubview(winnerLabel)
        NSLayoutConstraint.activate([
            winnerLabel.topAnchor.constraint(equalTo: winnerBanner.topAnchor, constant: 16),
            winnerLabel.bottomAnchor.constraint(equalTo: winnerBanner.bottomAnchor, constant: -16),
            winnerLabel.leadingAnchor.constraint(equalTo: winnerBanner.leadingAnchor, constant: 16),
            winnerLabel.trailingAnchor.constraint(equalTo: winnerBanner.trailingAnchor, constant: -16),
        ])

        // Buttons row
        let btnStack = UIStackView(arrangedSubviews: [yesButton, noButton])
        btnStack.spacing = 12
        btnStack.distribution = .fillEqually
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        // Main scroll content
        let contentStack = UIStackView(arrangedSubviews: [
            titleLabel,
            countdownLabel,
            connectionBadge,
            vDivider(),
            percentRow,
            progressBar,
            voteTotalsLabel,
            chartView,
            winnerBanner,
            btnStack,
            activityIndicator,
            errorLabel,
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            progressBar.heightAnchor.constraint(equalToConstant: 12),
            chartView.heightAnchor.constraint(equalToConstant: 180),
            yesButton.heightAnchor.constraint(equalToConstant: 56),
            noButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    private func setupActions() {
        yesButton.addTarget(self, action: #selector(voteTapped(_:)), for: .touchUpInside)
        noButton.addTarget(self, action: #selector(voteTapped(_:)), for: .touchUpInside)
    }

    // MARK: - Share poll vào chat
    @objc private func sharePollTapped() {
        let shareVC = SharePollViewController(poll: poll)
        let nav = UINavigationController(rootViewController: shareVC)
        present(nav, animated: true)
    }

    // MARK: - Vote
    @objc private func voteTapped(_ sender: UIButton) {
        let choice = (sender == yesButton) ? "YES" : "NO"
        viewModel.submitVote(choice: choice)
    }

    // MARK: - Winner (build text từ winnerInfo, hiện popup)
    private func presentWinner(_ info: PollViewModel.WinnerInfo) {
        guard !didShowWinner else { return }
        didShowWinner = true

        let resultText: String
        switch info.winner {
        case "YES":
            resultText = "YES THẮNG!\n\nYES: \(info.yesCount) votes\nNO: \(info.noCount) votes"
        case "NO":
            resultText = "NO THẮNG!\n\nNO: \(info.noCount) votes\nYES: \(info.yesCount) votes"
        case "TIE":
            resultText = "HÒA!\n\nYES: \(info.yesCount) votes\nNO: \(info.noCount) votes"
        default:
            resultText = "KHÔNG CÓ KẾT QUẢ\n(chưa có vote nào)"
        }

        showResultPopup(emoji: info.emoji, resultText: resultText, winner: info.winner,
                        yesCount: info.yesCount, noCount: info.noCount)
    }

    private func showResultPopup(emoji: String, resultText: String,
                                  winner: String, yesCount: Int, noCount: Int) {
        // Overlay mờ
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.tag = 999
        view.addSubview(overlay)

        // Popup card
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.3
        card.layer.shadowRadius = 20
        card.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(card)

        // Close button (dấu X)
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .secondaryLabel
        closeBtn.contentVerticalAlignment = .fill
        closeBtn.contentHorizontalAlignment = .fill
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(closeBtn)

        // Emoji label
        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 64)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(emojiLabel)

        // Title
        let titleLbl = UILabel()
        titleLbl.text = "KẾT QUẢ POLL"
        titleLbl.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLbl.textColor = .secondaryLabel
        titleLbl.textAlignment = .center
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLbl)

        // Result text
        let resultLbl = UILabel()
        resultLbl.text = resultText
        resultLbl.font = .systemFont(ofSize: 22, weight: .bold)
        resultLbl.textAlignment = .center
        resultLbl.numberOfLines = 0
        resultLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(resultLbl)

        // Progress bar mini
        let miniProgress = UIProgressView(progressViewStyle: .default)
        miniProgress.trackTintColor = .systemRed.withAlphaComponent(0.3)
        miniProgress.progressTintColor = .systemGreen
        miniProgress.layer.cornerRadius = 4
        miniProgress.clipsToBounds = true
        miniProgress.translatesAutoresizingMaskIntoConstraints = false
        let total = yesCount + noCount
        let yesPct = total > 0 ? Float(yesCount) / Float(total) : 0
        miniProgress.setProgress(yesPct, animated: false)
        card.addSubview(miniProgress)

        // YES/NO labels dưới progress
        let yesLbl = UILabel()
        yesLbl.text = String(format: "YES %.0f%%", yesPct * 100)
        yesLbl.font = .systemFont(ofSize: 13, weight: .medium)
        yesLbl.textColor = .systemGreen
        yesLbl.translatesAutoresizingMaskIntoConstraints = false

        let noLbl = UILabel()
        noLbl.text = String(format: "NO %.0f%%", (1 - yesPct) * 100)
        noLbl.font = .systemFont(ofSize: 13, weight: .medium)
        noLbl.textColor = .systemRed
        noLbl.textAlignment = .right
        noLbl.translatesAutoresizingMaskIntoConstraints = false

        let pctRow = UIStackView(arrangedSubviews: [yesLbl, noLbl])
        pctRow.distribution = .equalSpacing
        pctRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(pctRow)

        // Layout
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            card.widthAnchor.constraint(equalTo: overlay.widthAnchor, multiplier: 0.85),

            closeBtn.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            closeBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            closeBtn.widthAnchor.constraint(equalToConstant: 28),
            closeBtn.heightAnchor.constraint(equalToConstant: 28),

            emojiLabel.topAnchor.constraint(equalTo: closeBtn.bottomAnchor, constant: 8),
            emojiLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            titleLbl.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 4),
            titleLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            resultLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 16),
            resultLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            resultLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            miniProgress.topAnchor.constraint(equalTo: resultLbl.bottomAnchor, constant: 20),
            miniProgress.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            miniProgress.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            miniProgress.heightAnchor.constraint(equalToConstant: 8),

            pctRow.topAnchor.constraint(equalTo: miniProgress.bottomAnchor, constant: 6),
            pctRow.leadingAnchor.constraint(equalTo: miniProgress.leadingAnchor),
            pctRow.trailingAnchor.constraint(equalTo: miniProgress.trailingAnchor),
            pctRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
        ])

        // Animate popup xuất hiện
        card.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        overlay.alpha = 0
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5) {
            overlay.alpha = 1
            card.transform = .identity
        }

        // Close action — xóa overlay, hiện winner banner bên dưới
        let closeAction = { [weak self, weak overlay] in
            UIView.animate(withDuration: 0.2, animations: {
                overlay?.alpha = 0
            }) { _ in
                overlay?.removeFromSuperview()
                self?.showWinnerBanner(winner: winner, yesCount: yesCount, noCount: noCount)
            }
        }

        closeBtn.addAction(UIAction { _ in closeAction() }, for: .touchUpInside)

        // Tap overlay để đóng
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(dummyTap))
        overlay.addGestureRecognizer(tap)
        overlay.accessibilityActivate()

        // Lưu closeAction để tap overlay dùng được
        objc_setAssociatedObject(overlay, &AssociatedKeys.closeAction, closeAction, .OBJC_ASSOCIATION_COPY)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped(_:)))
        overlay.addGestureRecognizer(tapGesture)
    }

    @objc private func dummyTap() {}

    @objc private func overlayTapped(_ gesture: UITapGestureRecognizer) {
        guard let overlay = gesture.view else { return }
        if let closeAction = objc_getAssociatedObject(overlay, &AssociatedKeys.closeAction) as? () -> Void {
            closeAction()
        }
    }

    private func showWinnerBanner(winner: String, yesCount: Int, noCount: Int) {
        let emoji: String
        let message: String
        switch winner {
        case "YES": emoji = "🎉"; message = "YES THẮNG!\n\(yesCount) vs \(noCount) votes"
        case "NO":  emoji = "🎉"; message = "NO THẮNG!\n\(noCount) vs \(yesCount) votes"
        case "TIE": emoji = "🤝"; message = "HÒA!\n\(yesCount) vs \(noCount) votes"
        default:    emoji = "🗳️"; message = "KHÔNG CÓ KẾT QUẢ"
        }
        winnerLabel.text = "\(emoji)  \(message)"
        winnerBanner.isHidden = false
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5) {
            self.winnerBanner.alpha = 1
        }
    }
    // MARK: - Helpers
    private func vDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }
}

private enum AssociatedKeys {
    static var closeAction = "closeAction"
}
