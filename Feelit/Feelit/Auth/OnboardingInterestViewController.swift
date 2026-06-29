import UIKit

// MARK: - ChipsFlowView
/// Hàng chip có thể chọn nhiều, tự xuống dòng (wrap). Tự tính chiều cao.
final class ChipsFlowView: UIView {

    var onSelectionChanged: (() -> Void)?
    private(set) var selectedTitles: Set<String> = []

    private let titles: [String]
    private var buttons: [UIButton] = []
    private let hSpacing: CGFloat = 8
    private let vSpacing: CGFloat = 12
    private let chipHeight: CGFloat = 36
    private lazy var heightConstraint = heightAnchor.constraint(equalToConstant: 0)

    init(titles: [String]) {
        self.titles = titles
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        titles.forEach { addChip($0) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func addChip(_ title: String) {
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .regular)]))
        config.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        let b = UIButton(configuration: config)
        b.layer.cornerRadius = chipHeight / 2
        b.clipsToBounds = true
        b.addAction(UIAction { [weak self] _ in self?.toggle(title, button: b) }, for: .touchUpInside)
        addSubview(b)
        buttons.append(b)
        style(b, selected: false)
    }

    private func toggle(_ title: String, button: UIButton) {
        if selectedTitles.contains(title) { selectedTitles.remove(title) }
        else { selectedTitles.insert(title) }
        style(button, selected: selectedTitles.contains(title))
        onSelectionChanged?()
    }

    private func style(_ b: UIButton, selected: Bool) {
        b.backgroundColor = selected ? AuthTheme.textPrimary : AuthTheme.inputField
        b.configuration?.baseForegroundColor = selected ? AuthTheme.onGreen : AuthTheme.textSecondary
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let maxW = bounds.width
        guard maxW > 0 else { return }
        var x: CGFloat = 0, y: CGFloat = 0
        for b in buttons {
            let w = b.intrinsicContentSize.width
            if x > 0, x + w > maxW { x = 0; y += chipHeight + vSpacing }
            b.frame = CGRect(x: x, y: y, width: w, height: chipHeight)
            x += w + hSpacing
        }
        let total = y + chipHeight
        if heightConstraint.constant != total { heightConstraint.constant = total }
    }
}

// MARK: - OnboardingInterestViewController
/// Bước onboarding 2 — chọn chủ đề quan tâm (Figma node 161-22179).
/// Chọn ≥ 1 chủ đề → bật "Tiếp tục"; "Bỏ qua" để vào thẳng Home.
final class OnboardingInterestViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    private let viewModel = OnboardingInterestViewModel()
    private var topics: [String] { viewModel.topics }

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Bạn quan tâm đến\nchủ đề nào?"
        l.font = FeelitFonts.rounded(30, weight: .bold)
        l.textColor = AuthTheme.textPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Chọn trên 1 chủ đề để cá nhân hóa feed"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = AuthTheme.textSecondary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var chips = ChipsFlowView(titles: topics)
    private lazy var continueButton = AuthUI.continueButton(target: self, action: #selector(continueTapped))

    private lazy var skipButton = AuthUI.skipButton(title: "Bỏ qua", target: self, action: #selector(skipTapped))

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = AuthTheme.background
        chips.onSelectionChanged = { [weak self] in self?.updateContinueState() }
        setupLayout()
        updateContinueState()
    }

    private func setupLayout() {
        let top = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, chips])
        top.axis = .vertical
        top.alignment = .fill
        top.spacing = 24
        top.setCustomSpacing(8, after: titleLabel)
        top.translatesAutoresizingMaskIntoConstraints = false

        let bottom = UIStackView(arrangedSubviews: [continueButton, skipButton])
        bottom.axis = .vertical
        bottom.alignment = .fill
        bottom.spacing = 8
        bottom.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(top)
        view.addSubview(bottom)
        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            top.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            top.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottom.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    private func updateContinueState() {
        AuthUI.setEnabled(continueButton, !chips.selectedTitles.isEmpty)
    }

    // MARK: Actions
    @objc private func continueTapped() {
        guard !chips.selectedTitles.isEmpty else { return }
        viewModel.save(chips.selectedTitles)
        goNext()
    }

    @objc private func skipTapped() { goNext() }

    private func goNext() {
        navigationController?.pushViewController(OnboardingInviteFriendsViewController(), animated: true)
    }
}
