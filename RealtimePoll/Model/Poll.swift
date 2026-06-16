import Foundation

// MARK: - Poll
struct Poll: Codable {
    let id: String
    let title: String
    let status: String          // "active" | "completed"
    let startsAt: String
    let endsAt: String
    let yesCount: Int
    let noCount: Int
    let winner: String?         // "YES" | "NO" | "TIE" | "NO_RESULT" | nil

    enum CodingKeys: String, CodingKey {
        case id, title, status, winner
        case startsAt  = "starts_at"
        case endsAt    = "ends_at"
        case yesCount  = "yes_count"
        case noCount   = "no_count"
    }

    var totalVotes: Int { yesCount + noCount }

    var yesPercentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(yesCount) / Double(totalVotes) * 100
    }

    var noPercentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(noCount) / Double(totalVotes) * 100
    }

    var endsAtDate: Date? {
        ISO8601DateFormatter().date(from: endsAt)
    }

    var isActive: Bool { status == "active" }
    
    var winnerDisplayText: String {
        switch winner {
        case "YES":       return "🎉 YES THẮNG!"
        case "NO":        return "🎉 NO THẮNG!"
        case "TIE":       return "🤝 HÒA!"
        case "NO_RESULT": return "🗳️ KHÔNG CÓ KẾT QUẢ"
        default:          return ""
        }
    }
}

// MARK: - VoteRequest
struct VoteRequest: Codable {
    let voterId: String
    let choice: String          // "YES" | "NO"
}

// MARK: - VoteResponse (realtime update payload)
struct VoteResponse: Codable {
    let pollId: String
    let yesCount: Int
    let noCount: Int
    let totalVotes: Int
    let yesPercentage: Double
    let noPercentage: Double
}

// MARK: - ChartPoint
struct ChartPoint: Codable {
    let yesCount: Int
    let noCount: Int
    let yesPercentage: Double
    let noPercentage: Double
    let recordedAt: String
}

// MARK: - PollFinished (socket event)
struct PollFinished: Codable {
    let pollId: String
    let winner: String
    let yesCount: Int
    let noCount: Int
    let totalVotes: Int
    let yesPercentage: Double
    let noPercentage: Double
}

// MARK: - APIError
struct APIError: Codable {
    let error: String
    let message: String
}
