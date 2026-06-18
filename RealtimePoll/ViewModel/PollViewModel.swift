import Foundation
import Combine

// MARK: - PollViewModel
/// Logic cho `PollViewController`: countdown, socket realtime, vote, chart, winner.
/// KHÔNG import UIKit. Mọi format string được tính sẵn ở đây để View chỉ bind.
final class PollViewModel {

    enum ConnectionStatus { case connecting, live, reconnecting, ended }
    struct WinnerInfo {
        let emoji: String
        let message: String       // text cho banner
        let yesCount: Int
        let noCount: Int
        let winner: String        // "YES" | "NO" | "TIE" | khác — để View dựng popup
    }

    // MARK: - Output
    @Published private(set) var pollTitle: String
    @Published private(set) var countdownText: String = "--:--"
    @Published private(set) var isUrgent: Bool = false              // true khi <= 30s hoặc đã hết giờ
    @Published private(set) var yesPercentageText: String = ""      // "YES  68%"
    @Published private(set) var noPercentageText: String = ""       // "32%  NO"
    @Published private(set) var progressValue: Float = 0            // 0.0 → 1.0
    @Published private(set) var voteTotalsText: String = ""
    @Published private(set) var canVote: Bool = false
    @Published private(set) var hasVoted: Bool
    @Published private(set) var isVotingLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var connectionStatus: ConnectionStatus = .connecting
    @Published private(set) var chartEntries: [(yes: Double, no: Double)] = []
    @Published private(set) var winnerInfo: WinnerInfo? = nil
    @Published private(set) var voteButtonSubtitle: String? = nil   // "Voted" / "Voted ✓" / "Waiting..."

    // MARK: - Private
    private var poll: Poll
    private let socketManager = SocketManager()
    private var cancellables = Set<AnyCancellable>()
    private var countdownCancellable: AnyCancellable?

    // MARK: - Init
    init(poll: Poll) {
        self.poll = poll
        self.pollTitle = poll.title
        self.hasVoted = PollRepository.shared.hasVoted(pollId: poll.id)
    }

    // MARK: - Input
    func onViewDidLoad() {
        applyPollData()
        if poll.isActive { startCountdown() }
        connectSocket()
        loadChart()
    }

    func onViewDisappear() {
        stopCountdown()
        socketManager.leavePoll(pollId: poll.id)
        socketManager.delegate = nil
        socketManager.disconnect()
    }

    func submitVote(choice: String) {
        isVotingLoading = true
        errorMessage = nil
        PollRepository.shared.submitVote(pollId: poll.id, choice: choice) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isVotingLoading = false
                switch result {
                case .success:
                    self.hasVoted = true
                    self.canVote = false
                    self.voteButtonSubtitle = "Voted ✓"
                    self.scheduleCompletionNotification()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func clearError() { errorMessage = nil }

    // MARK: - Apply poll data
    private func applyPollData() {
        pollTitle = poll.title
        updateTotals(yes: poll.yesCount, no: poll.noCount,
                     yesPct: poll.yesPercentage, noPct: poll.noPercentage)
        canVote = poll.isActive && !hasVoted
        if hasVoted && poll.isActive { voteButtonSubtitle = "Voted" }
        if !poll.isActive, let winner = poll.winner {
            showWinner(winner, yesCount: poll.yesCount, noCount: poll.noCount)
        }
    }

    private func updateTotals(yes: Int, no: Int, yesPct: Double, noPct: Double) {
        yesPercentageText = String(format: "YES  %.0f%%", yesPct)
        noPercentageText  = String(format: "%.0f%%  NO", noPct)
        progressValue     = Float(yesPct / 100)
        voteTotalsText    = "Yes: \(yes)  |  No: \(no)  |  Total: \(yes + no)"
    }

    // MARK: - Countdown (Combine Timer)
    private func startCountdown() {
        tickCountdown()
        countdownCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tickCountdown() }
    }

    private func stopCountdown() {
        countdownCancellable?.cancel()
        countdownCancellable = nil
    }

    private func tickCountdown() {
        guard let endsAt = poll.endsAtDate else {
            countdownText = "--:--"
            return
        }
        let remaining = max(0, endsAt.timeIntervalSinceNow)
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        countdownText = String(format: "%02d:%02d", mins, secs)

        if remaining <= 0 {
            stopCountdown()
            countdownText = "00:00"
            isUrgent = true
            canVote = false
            voteButtonSubtitle = "Waiting for final result..."
        } else if remaining <= 30 {
            isUrgent = true
        }
    }

    // MARK: - Socket
    private func connectSocket() {
        guard poll.isActive else {
            connectionStatus = .ended
            return
        }
        socketManager.delegate = self
        socketManager.connect()
        socketManager.joinPoll(pollId: poll.id)
    }

    // MARK: - Chart history
    private func loadChart() {
        PollRepository.shared.loadChart(pollId: poll.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case .success(let points) = result {
                    self.chartEntries = points.map { ($0.yesPercentage, $0.noPercentage) }
                }
            }
        }
    }

    // MARK: - Winner
    private func showWinner(_ winner: String, yesCount: Int, noCount: Int) {
        stopCountdown()
        countdownText = "ENDED"
        canVote = false

        let emoji: String
        let message: String
        switch winner {
        case "YES": emoji = "🎉"; message = "YES THẮNG!\n\(yesCount) vs \(noCount) votes"
        case "NO":  emoji = "🎉"; message = "NO THẮNG!\n\(noCount) vs \(yesCount) votes"
        case "TIE": emoji = "🤝"; message = "HÒA!\n\(yesCount) vs \(noCount) votes"
        default:    emoji = "🗳️"; message = "KHÔNG CÓ KẾT QUẢ"
        }
        winnerInfo = WinnerInfo(emoji: emoji, message: message,
                                yesCount: yesCount, noCount: noCount, winner: winner)
    }

    // MARK: - Completion notification
    private func scheduleCompletionNotification() {
        guard poll.isActive else { return }
        let fireDate = poll.endsAtDate ?? Date().addingTimeInterval(60)
        guard fireDate.timeIntervalSinceNow > 0 else { return }
        NotificationManager.shared.schedulePollFinished(pollId: poll.id, title: poll.title, at: fireDate)
    }

    deinit {
        cancellables.removeAll()
        countdownCancellable?.cancel()
        socketManager.delegate = nil
        socketManager.disconnect()
    }
}

// MARK: - SocketManagerDelegate
extension PollViewModel: SocketManagerDelegate {

    func socketDidConnect() {
        DispatchQueue.main.async { self.connectionStatus = .live }
    }

    func socketDidDisconnect() {
        DispatchQueue.main.async { self.connectionStatus = .reconnecting }
    }

    func socketDidReceiveVoteUpdate(_ update: VoteResponse) {
        DispatchQueue.main.async {
            self.updateTotals(yes: update.yesCount, no: update.noCount,
                              yesPct: update.yesPercentage, noPct: update.noPercentage)
            self.chartEntries.append((update.yesPercentage, update.noPercentage))
            if self.chartEntries.count > 100 { self.chartEntries.removeFirst() }
        }
    }

    func socketDidReceivePollFinished(_ result: PollFinished) {
        DispatchQueue.main.async {
            NotificationManager.shared.cancel(pollId: result.pollId)
            self.showWinner(result.winner, yesCount: result.yesCount, noCount: result.noCount)
        }
    }
}
