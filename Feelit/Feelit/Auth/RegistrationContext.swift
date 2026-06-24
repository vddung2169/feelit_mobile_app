import Foundation

// MARK: - RegistrationContext
/// Mang dữ liệu xuyên suốt flow đăng ký nhiều bước:
/// Email/SĐT → OTP → Mật khẩu → contact bổ sung → Hoàn tất.
/// Truyền theo tham chiếu qua các màn để gom dần thông tin.
final class RegistrationContext {
    var userId: String = ""
    var email: String?
    var phone: String?            // E.164, vd "+84987654321"
    var phoneDisplay: String?     // bản hiển thị, vd "+84 987654321"
    var password: String = ""
    /// Kênh định danh chính (bước đầu): "email" | "sms".
    let primaryChannel: String

    init(primaryChannel: String) { self.primaryChannel = primaryChannel }

    /// Bước cuối cần thu SĐT (khi đăng ký bằng email) hay Email (khi đăng ký bằng SĐT).
    var finalNeedsPhone: Bool { primaryChannel == "email" }
}
