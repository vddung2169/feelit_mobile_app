import Foundation

// MARK: - AuthMockBackend
/// Backend GIẢ LẬP cho luồng Auth — cho phép test đăng nhập / đăng ký / OTP / quên mật khẩu
/// mà KHÔNG cần server thật ở `localhost:3001`.
///
/// Bật/tắt qua `isEnabled` (mặc định BẬT ở bản DEBUG). Khi bật, `AuthAPIClient` lấy kết quả
/// từ đây thay vì gọi mạng. Đặt `false` nếu muốn gọi server thật.
///
/// ┌─────────────────────────────────────────────────────────────────────┐
/// │  TÀI KHOẢN MẪU — đăng nhập thành công ngay (Welcome → Đăng nhập)      │
/// ├─────────────────────────────────────────────────────────────────────┤
/// │  1) Email:  test@feelit.vn      ·  Mật khẩu:  Test@1234              │
/// │  2) Email:  demo@feelit.vn      ·  Mật khẩu:  Demo@1234              │
/// │  3) SĐT:    0901234567 (+84)    ·  Mật khẩu:  Phone@1234             │
/// ├─────────────────────────────────────────────────────────────────────┤
/// │  OTP (đăng ký mới / quên mật khẩu):  123456  (dùng chung)            │
/// └─────────────────────────────────────────────────────────────────────┘
enum AuthMockBackend {

    #if DEBUG
    static var isEnabled = true
    #else
    static var isEnabled = false
    #endif

    /// Mã OTP hợp lệ dùng chung cho mọi tài khoản mẫu.
    static let universalOTP = "123456"

    /// Độ trễ giả lập mạng (giây) để UI loading hiển thị tự nhiên.
    private static let latency: TimeInterval = 0.4

    // MARK: - Tài khoản mẫu
    struct Account {
        let email: String?
        let phone: String?    // E.164, ví dụ "+84901234567"
        var password: String
        let user: UserDTO
    }

    static var accounts: [Account] = [
        Account(email: "test@feelit.vn", phone: nil, password: "Test@1234",
                user: makeUser(id: "u_test", email: "test@feelit.vn", phone: nil,
                               username: "tester", displayName: "Test User")),
        Account(email: "demo@feelit.vn", phone: nil, password: "Demo@1234",
                user: makeUser(id: "u_demo", email: "demo@feelit.vn", phone: nil,
                               username: "demo", displayName: "Demo User")),
        Account(email: nil, phone: "+84901234567", password: "Phone@1234",
                user: makeUser(id: "u_phone", email: nil, phone: "+84901234567",
                               username: "phoneuser", displayName: "Phone User")),
    ]

    /// userId (đăng ký mới chờ verify) → user tạm.
    private static var pendingRegistrations: [String: UserDTO] = [:]
    /// userId đã đăng nhập → user (cho getCurrentUser).
    private static var activeSessions: [String: UserDTO] = [:]

    /// Bản nháp đăng ký theo flow nhiều bước (gửi OTP → xác minh → hoàn tất).
    private struct Draft { var email: String?; var phone: String?; var verified: Bool }
    private static var drafts: [String: Draft] = [:]

    // MARK: - Endpoints giả lập

    static func register(email: String?, phone: String?, password: String,
                         completion: @escaping (Result<RegisterResponse, Error>) -> Void) {
        run(completion) {
            // Trùng email/SĐT của tài khoản mẫu → báo lỗi như server thật.
            if let email, accounts.contains(where: { $0.email?.caseInsensitiveCompare(email) == .orderedSame }) {
                return .failure(AuthError.emailExists)
            }
            if let phone, accounts.contains(where: { digits($0.phone) == digits(phone) && !digits(phone).isEmpty }) {
                return .failure(AuthError.phoneExists)
            }
            let userId = "u_" + UUID().uuidString.prefix(8)
            pendingRegistrations[userId] = makeUser(
                id: userId, email: email, phone: phone,
                username: usernameFrom(email: email, phone: phone),
                displayName: "Người dùng mới")
            return .success(RegisterResponse(userId: userId, verificationRequired: true))
        }
    }

    static func verifyOTP(userId: String, code: String, channel: String,
                          completion: @escaping (Result<AuthSessionResponse, Error>) -> Void) {
        run(completion) {
            guard code == universalOTP else { return .failure(AuthError.invalidOTP) }
            let user = pendingRegistrations[userId]
                ?? accounts.first(where: { $0.user.id == userId })?.user
                ?? makeUser(id: userId, email: nil, phone: nil, username: "user", displayName: "User")
            pendingRegistrations[userId] = nil
            activeSessions[user.id] = user
            return .success(makeSession(user: user))
        }
    }

    static func resendOTP(userId: String, channel: String,
                          completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        run(completion) { .success(EmptyResponse()) }
    }

    // MARK: - Đăng ký nhiều bước (Email → OTP → Mật khẩu → SĐT → Hoàn tất)

    /// Bước 1: gửi OTP tới email/SĐT, tạo bản nháp đăng ký, trả về userId.
    static func sendRegistrationOTP(email: String?, phone: String?,
                                    completion: @escaping (Result<RegisterResponse, Error>) -> Void) {
        run(completion) {
            if let email, accounts.contains(where: { $0.email?.caseInsensitiveCompare(email) == .orderedSame }) {
                return .failure(AuthError.emailExists)
            }
            if let phone, accounts.contains(where: { digits($0.phone) == digits(phone) && !digits(phone).isEmpty }) {
                return .failure(AuthError.phoneExists)
            }
            let userId = "u_" + UUID().uuidString.prefix(8)
            drafts[userId] = Draft(email: email, phone: phone, verified: false)
            return .success(RegisterResponse(userId: userId, verificationRequired: true))
        }
    }

    /// Bước 2: xác minh OTP cho bản nháp (KHÔNG đăng nhập, chỉ đánh dấu đã xác minh).
    static func verifyRegistrationOTP(userId: String, code: String,
                                      completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        run(completion) {
            guard code == universalOTP else { return .failure(AuthError.invalidOTP) }
            guard drafts[userId] != nil else { return .failure(AuthError.unknown("Phiên đăng ký không hợp lệ")) }
            drafts[userId]?.verified = true
            return .success(EmptyResponse())
        }
    }

    /// Bước cuối: gắn contact bổ sung + mật khẩu, tạo tài khoản thật và trả session.
    static func completeRegistration(userId: String, email: String?, phone: String?, password: String,
                                     completion: @escaping (Result<AuthSessionResponse, Error>) -> Void) {
        run(completion) {
            guard var draft = drafts[userId], draft.verified else {
                return .failure(AuthError.unknown("Phiên đăng ký chưa được xác minh"))
            }
            draft.email = email ?? draft.email
            draft.phone = phone ?? draft.phone
            let user = makeUser(id: userId, email: draft.email, phone: draft.phone,
                                username: usernameFrom(email: draft.email, phone: draft.phone),
                                displayName: "Người dùng mới")
            accounts.append(Account(email: draft.email, phone: draft.phone, password: password, user: user))
            activeSessions[userId] = user
            drafts[userId] = nil
            return .success(makeSession(user: user))
        }
    }

    static func login(emailOrPhone: String, password: String,
                      completion: @escaping (Result<AuthSessionResponse, Error>) -> Void) {
        run(completion) {
            guard let acc = accounts.first(where: { matches($0, emailOrPhone) }) else {
                return .failure(AuthError.invalidCredentials)
            }
            guard acc.password == password else { return .failure(AuthError.invalidCredentials) }
            activeSessions[acc.user.id] = acc.user
            return .success(makeSession(user: acc.user))
        }
    }

    // MARK: - Đăng nhập bằng SĐT qua OTP (không mật khẩu)

    /// Gửi OTP đăng nhập tới SĐT của một tài khoản đã tồn tại.
    static func sendLoginOTP(phone: String,
                             completion: @escaping (Result<ForgotPasswordResponse, Error>) -> Void) {
        run(completion) {
            guard let acc = accounts.first(where: { matches($0, phone) }) else {
                return .failure(AuthError.invalidCredentials)
            }
            return .success(ForgotPasswordResponse(userId: acc.user.id, channel: "sms"))
        }
    }

    /// Xác minh OTP đăng nhập → trả session.
    static func verifyLoginOTP(userId: String, code: String,
                               completion: @escaping (Result<AuthSessionResponse, Error>) -> Void) {
        run(completion) {
            guard code == universalOTP else { return .failure(AuthError.invalidOTP) }
            guard let acc = accounts.first(where: { $0.user.id == userId }) else {
                return .failure(AuthError.invalidCredentials)
            }
            activeSessions[acc.user.id] = acc.user
            return .success(makeSession(user: acc.user))
        }
    }

    static func forgotPassword(emailOrPhone: String,
                               completion: @escaping (Result<ForgotPasswordResponse, Error>) -> Void) {
        run(completion) {
            let acc = accounts.first(where: { matches($0, emailOrPhone) })
            let userId = acc?.user.id ?? "u_" + UUID().uuidString.prefix(8)
            let channel = emailOrPhone.contains("@") ? "email" : "sms"
            return .success(ForgotPasswordResponse(userId: userId, channel: channel))
        }
    }

    static func resetPassword(userId: String, code: String, newPassword: String,
                              completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        run(completion) {
            guard code == universalOTP else { return .failure(AuthError.invalidOTP) }
            if let idx = accounts.firstIndex(where: { $0.user.id == userId }) {
                accounts[idx].password = newPassword
            }
            return .success(EmptyResponse())
        }
    }

    static func getCurrentUser(completion: @escaping (Result<UserDTO, Error>) -> Void) {
        run(completion) {
            if let id = TokenStore.shared.currentUserId,
               let user = activeSessions[id] ?? accounts.first(where: { $0.user.id == id })?.user {
                return .success(user)
            }
            return .success(accounts[0].user)
        }
    }

    // MARK: - Helpers
    private static func run<T>(_ completion: @escaping (Result<T, Error>) -> Void,
                               _ body: @escaping () -> Result<T, Error>) {
        DispatchQueue.global().asyncAfter(deadline: .now() + latency) {
            completion(body())
        }
    }

    private static func matches(_ acc: Account, _ input: String) -> Bool {
        let t = input.trimmingCharacters(in: .whitespaces)
        if let e = acc.email, e.caseInsensitiveCompare(t) == .orderedSame { return true }
        let inDigits = digits(t)
        if let p = acc.phone, !inDigits.isEmpty, digits(p) == inDigits { return true }
        return false
    }

    private static func digits(_ s: String?) -> String { (s ?? "").filter(\.isNumber) }

    private static func usernameFrom(email: String?, phone: String?) -> String {
        if let email, let at = email.firstIndex(of: "@") { return String(email[..<at]) }
        if let phone { return "user" + phone.suffix(4) }
        return "user"
    }

    private static func makeUser(id: String, email: String?, phone: String?,
                                 username: String, displayName: String) -> UserDTO {
        UserDTO(id: id, email: email, phone: phone, username: username,
                displayName: displayName, avatarUrl: nil, bio: "Tài khoản test",
                isVerified: true, createdAt: "2026-01-01T00:00:00Z",
                reputation: ReputationDTO(xp: 1250, accuracy: 0.72, streak: 5,
                                          rank: 128, totalUsers: 10_000))
    }

    private static func makeSession(user: UserDTO) -> AuthSessionResponse {
        AuthSessionResponse(accessToken: "mock_access_\(user.id)",
                            refreshToken: "mock_refresh_\(user.id)",
                            user: user)
    }
}
