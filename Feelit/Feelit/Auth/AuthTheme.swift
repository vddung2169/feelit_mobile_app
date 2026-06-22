import UIKit

// MARK: - AuthTheme
/// Token màu dùng chung cho flow Auth (Welcome / Email Input...).
/// Lấy CHÍNH XÁC theo Figma Feelit_app light mode (nodes 268-63xx … 268-69xx):
/// nền #FBFBFB, surface #F7F7F7, chữ #202020, accent xanh #4CAF50.
/// Flow Auth được ép `.light` (xem AuthNavigationController).
/// (Giá trị dark cũ giữ trong chú thích để tham khảo/khôi phục.)
enum AuthTheme {
    static let background        = UIColor(hex: 0xFBFBFB)   // nền màn       (dark: 0x111111)
    static let inputField        = UIColor(hex: 0xF7F7F7)   // ô nhập / surface (dark: 0x181818)
    static let buttonDisabled    = UIColor(hex: 0xE6E6E6)   // nút khi disabled (dark: 0x292929)

    static let fieldBorder       = UIColor(hex: 0xCCCCCC)   // viền ô (mặc định) (dark: 0x474747)
    static let fieldBorderActive = UIColor(hex: 0x366837)   // viền ô (hợp lệ)   (dark: 0x366837)
    static let otpBorder         = UIColor(hex: 0x8C8C8C)   // viền ô OTP (mặc định)

    static let textPrimary       = UIColor(hex: 0x202020)   // (dark: 0xEDEDED)
    static let textSecondary     = UIColor(hex: 0x818181)   // (dark: 0xB3B3B3)
    static let textTertiary      = UIColor(hex: 0xB9B9B9)   // (dark: 0x606060)
    static let placeholder       = UIColor(hex: 0xB9B9B9)   // (dark: 0x606060)

    static let green             = UIColor(hex: 0x4CAF50)   // accent / nút chính
    static let onGreen           = UIColor(hex: 0xFBFBFB)   // chữ trên nền xanh (dark: 0x111111)
    static let bad               = UIColor(hex: 0xF44336)   // lỗi (viền OTP / thông báo)
}

// MARK: - FeelitLogoView
/// Wordmark "feelit" dựng bằng code: chữ trắng + chấm tròn xanh đè lên chữ 'i'
/// (để hiển thị đúng trên nền tối, khác với asset wordmark màu đen).
final class FeelitLogoView: UIView {

    private let fontSize: CGFloat
    private let label = UILabel()
    private let dot = UIView()

    init(fontSize: CGFloat = 44,
         textColor: UIColor = AuthTheme.textPrimary,
         dotColor: UIColor = AuthTheme.green) {
        self.fontSize = fontSize
        super.init(frame: .zero)

        label.text = "feelit"
        label.font = FeelitFonts.rounded(fontSize, weight: .heavy)
        label.textColor = textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        dot.backgroundColor = dotColor
        dot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dot)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let font = label.font else { return }
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        // Đo bề rộng để đặt chấm đúng vào vị trí thân chữ 'i' (ký tự thứ 5).
        let wFeel  = ("feel"  as NSString).size(withAttributes: attrs).width
        let wFeeli = ("feeli" as NSString).size(withAttributes: attrs).width
        let size = fontSize * 0.17
        let cx = wFeel + (wFeeli - wFeel) / 2
        let cy = label.bounds.height * 0.21
        dot.frame = CGRect(x: cx - size / 2, y: cy - size / 2, width: size, height: size)
        dot.layer.cornerRadius = size / 2
    }
}

// MARK: - AuthNavigationController
/// Nav controller cho flow Auth: ẩn nav bar (dùng nút "Trở lại" custom),
/// ép light mode (nền trắng) cho toàn flow, forward status bar style sang VC đang hiển thị.
final class AuthNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarHidden(true, animated: false)
        view.backgroundColor = AuthTheme.background
        overrideUserInterfaceStyle = .light
    }
    override var childForStatusBarStyle: UIViewController? { topViewController }
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
}
