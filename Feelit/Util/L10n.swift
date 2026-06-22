// Util/L10n.swift
import Foundation

/// Trung tâm quản lý mọi key localized string — tránh hardcode rải rác & typo key.
/// Source language = vi (xem Localizable.xcstrings). Bổ sung key khi migrate thêm file.
enum L10n {

    // MARK: - Common
    enum Common {
        static var ok: String { String(localized: "common.ok") }
        static var cancel: String { String(localized: "common.cancel") }
        static var retry: String { String(localized: "common.retry") }
        static var loading: String { String(localized: "common.loading") }
        static var error: String { String(localized: "common.error") }
        static var close: String { String(localized: "common.close") }
        static var save: String { String(localized: "common.save") }
        static var send: String { String(localized: "common.send") }
        static var delete: String { String(localized: "common.delete") }
        static var confirm: String { String(localized: "common.confirm") }
    }

    // MARK: - Auth
    enum Auth {
        static var errorTitle: String { String(localized: "auth.error.title") }
        static var continueButton: String { String(localized: "auth.button.continue") }
        static var backButton: String { String(localized: "auth.button.back") }
        static var termsText: String { String(localized: "auth.terms.text") }
        static var phonePlaceholder: String { String(localized: "auth.phone.placeholder") }
        static var emailPlaceholder: String { String(localized: "auth.email.placeholder") }
        static var passwordPlaceholder: String { String(localized: "auth.password.placeholder") }
        static var otpTitle: String { String(localized: "auth.otp.title") }
        static var otpResend: String { String(localized: "auth.otp.resend") }
        static var otpInvalid: String { String(localized: "auth.otp.invalid") }
        static var welcomeTitle: String { String(localized: "auth.welcome.title") }
        static var loginWithEmail: String { String(localized: "auth.welcome.login_email") }
        static var loginWithPhone: String { String(localized: "auth.welcome.login_phone") }
        static var forgotPassword: String { String(localized: "auth.forgot_password") }
    }

    // MARK: - Poll
    enum Poll {
        static var voteYes: String { String(localized: "poll.vote.yes") }
        static var voteNo: String { String(localized: "poll.vote.no") }
        static var voteYesAccessibility: String { String(localized: "poll.vote.yes.accessibility") }
        static var voteNoAccessibility: String { String(localized: "poll.vote.no.accessibility") }
        static var winnerYes: String { String(localized: "poll.winner.yes") }
        static var winnerNo: String { String(localized: "poll.winner.no") }
        static var winnerTie: String { String(localized: "poll.winner.tie") }
        static var winnerNoResult: String { String(localized: "poll.winner.no_result") }
        static var duplicateVoteError: String { String(localized: "poll.error.duplicate_vote") }
        static var pollExpiredError: String { String(localized: "poll.error.expired") }
        static var pollNotFoundError: String { String(localized: "poll.error.not_found") }
        static var waitingFinalResult: String { String(localized: "poll.waiting_result") }
        static var connectionLive: String { String(localized: "poll.connection.live") }
        static var connectionReconnecting: String { String(localized: "poll.connection.reconnecting") }
        static var connectionEnded: String { String(localized: "poll.connection.ended") }
        static var joinActivePoll: String { String(localized: "poll.join_active") }
        static var createDemoPoll: String { String(localized: "poll.create_demo") }
        static var noActivePoll: String { String(localized: "poll.no_active") }

        static func votesCount(_ count: Int) -> String {
            String(localized: "poll.votes_count \(count)")
        }
        static func voteTotals(yes: Int, no: Int, total: Int) -> String {
            String(localized: "poll.vote_totals \(yes) \(no) \(total)")
        }
    }

    // MARK: - Feed
    enum Feed {
        static var like: String { String(localized: "feed.button.like") }
        static var comment: String { String(localized: "feed.button.comment") }
        static var share: String { String(localized: "feed.button.share") }
        static var likeAccessibility: String { String(localized: "feed.button.like.accessibility") }
        static var commentAccessibility: String { String(localized: "feed.button.comment.accessibility") }
        static var shareAccessibility: String { String(localized: "feed.button.share.accessibility") }
        static var commentPlaceholder: String { String(localized: "feed.comment.placeholder") }
        static var commentEmptyTitle: String { String(localized: "feed.comment.empty.title") }
        static var commentEmptySubtitle: String { String(localized: "feed.comment.empty.subtitle") }
        static var sendCommentAccessibility: String { String(localized: "feed.comment.send.accessibility") }
        static var closeCommentsAccessibility: String { String(localized: "feed.comment.close.accessibility") }

        static func commentsTitle(_ count: Int) -> String {
            String(localized: "feed.comments_title \(count)")
        }
    }

    // MARK: - Chat
    enum Chat {
        static var myIdPlaceholder: String { String(localized: "chat.my_id.placeholder") }
        static var partnerIdPlaceholder: String { String(localized: "chat.partner_id.placeholder") }
        static var startChat: String { String(localized: "chat.start") }
        static var invalidId: String { String(localized: "chat.error.invalid_id") }
        static var sameId: String { String(localized: "chat.error.same_id") }
        static var messagePlaceholder: String { String(localized: "chat.message.placeholder") }

        static func chatWithTitle(_ partnerId: String) -> String {
            String(localized: "chat.with_title \(partnerId)")
        }
    }

    // MARK: - Tab Bar
    enum Tab {
        static var feed: String { String(localized: "tab.feed") }
        static var explore: String { String(localized: "tab.explore") }
        static var portfolio: String { String(localized: "tab.portfolio") }
        static var profile: String { String(localized: "tab.profile") }
    }

    // MARK: - Profile
    enum Profile {
        static var editProfile: String { String(localized: "profile.edit") }
        static var followers: String { String(localized: "profile.followers") }
        static var following: String { String(localized: "profile.following") }
        static var accuracy: String { String(localized: "profile.accuracy") }
        static var logout: String { String(localized: "profile.logout") }
    }
}
