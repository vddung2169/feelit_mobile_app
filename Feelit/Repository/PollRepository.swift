import Foundation

/// Trung gian giữa ViewController và APIClient/SocketManager.
/// Lưu trạng thái poll hiện tại và notify ViewController qua callback.
final class PollRepository {

    static let shared = PollRepository()
    private init() {}

    private let votedPollsKey = "voted_poll_ids"

    // MARK: - Load active poll
    func loadActivePoll(completion: @escaping (Result<Poll, Error>) -> Void) {
        APIClient.shared.getActivePoll(completion: completion)
    }

    // MARK: - Load poll by id
    func loadPoll(pollId: String, completion: @escaping (Result<Poll, Error>) -> Void) {
        APIClient.shared.getPoll(pollId: pollId, completion: completion)
    }

    // MARK: - Create demo poll
    func createDemoPoll(completion: @escaping (Result<Poll, Error>) -> Void) {
        let titles = [
            "Should we ship the new feature this week?",
            "Is dark mode better than light mode?",
            "Should we move to a 4-day work week?",
            "Would you recommend this app to a friend?",
        ]
        let title = titles.randomElement() ?? "Team Poll"
        APIClient.shared.createPoll(title: title, completion: completion)
    }

    // MARK: - Submit vote
    func submitVote(
        pollId: String,
        choice: String,
        completion: @escaping (Result<VoteResponse, Error>) -> Void
    ) {
        APIClient.shared.submitVote(pollId: pollId, choice: choice) { [weak self] result in
            if case .success = result {
                self?.markVoted(pollId: pollId)
            }
            completion(result)
        }
    }

    // MARK: - Chart data
    func loadChart(
        pollId: String,
        completion: @escaping (Result<[ChartPoint], Error>) -> Void
    ) {
        APIClient.shared.getChart(pollId: pollId, completion: completion)
    }

    // MARK: - Voted tracking (UserDefaults)
    func hasVoted(pollId: String) -> Bool {
        let voted = UserDefaults.standard.stringArray(forKey: votedPollsKey) ?? []
        return voted.contains(pollId)
    }

    private func markVoted(pollId: String) {
        var voted = UserDefaults.standard.stringArray(forKey: votedPollsKey) ?? []
        if !voted.contains(pollId) {
            voted.append(pollId)
            UserDefaults.standard.set(voted, forKey: votedPollsKey)
        }
    }
}
