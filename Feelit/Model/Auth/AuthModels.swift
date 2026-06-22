import Foundation

// MARK: - Request bodies
struct RegisterRequest: Codable {
    let email: String?
    let phone: String?
    let password: String
}

struct VerifyOTPRequest: Codable {
    let userId: String
    let code: String
    let channel: String   // "email" | "sms"
}

struct LoginRequest: Codable {
    let emailOrPhone: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct ForgotPasswordRequest: Codable {
    let emailOrPhone: String
}

struct ResetPasswordRequest: Codable {
    let userId: String
    let code: String
    let newPassword: String
}

// MARK: - Responses
struct RegisterResponse: Codable {
    let userId: String
    let verificationRequired: Bool
}

struct AuthSessionResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserDTO
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct ForgotPasswordResponse: Codable {
    let userId: String
    let channel: String
}

// MARK: - User
struct UserDTO: Codable {
    let id: String
    let email: String?
    let phone: String?
    let username: String
    let displayName: String
    let avatarUrl: String?
    let bio: String?
    let isVerified: Bool
    let createdAt: String
    let reputation: ReputationDTO
}

struct ReputationDTO: Codable {
    let xp: Int
    let accuracy: Double
    let streak: Int
    let rank: Int
    let totalUsers: Int
}

struct PublicProfileDTO: Codable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    let bio: String?
    let reputation: ReputationDTO
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case emailExists
    case phoneExists
    case invalidOTP
    case otpExpired
    case invalidCredentials
    case accountNotVerified
    case refreshTokenExpired
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .emailExists:         return "Email này đã được sử dụng."
        case .phoneExists:         return "Số điện thoại này đã được sử dụng."
        case .invalidOTP:          return "Mã OTP không đúng."
        case .otpExpired:          return "Mã OTP đã hết hạn. Vui lòng gửi lại."
        case .invalidCredentials:  return "Email/SĐT hoặc mật khẩu không đúng."
        case .accountNotVerified:  return "Tài khoản chưa được xác minh."
        case .refreshTokenExpired: return "Phiên đăng nhập đã hết hạn."
        case .unknown(let msg):    return msg
        }
    }

    static func from(errorCode: String) -> AuthError {
        switch errorCode {
        case "EMAIL_EXISTS":           return .emailExists
        case "PHONE_EXISTS":           return .phoneExists
        case "INVALID_OTP":            return .invalidOTP
        case "OTP_EXPIRED":            return .otpExpired
        case "INVALID_CREDENTIALS":    return .invalidCredentials
        case "ACCOUNT_NOT_VERIFIED":   return .accountNotVerified
        case "REFRESH_TOKEN_EXPIRED":  return .refreshTokenExpired
        default:                       return .unknown(errorCode)
        }
    }
}
