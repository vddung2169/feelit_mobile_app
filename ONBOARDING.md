# FEELIT — Tài liệu Onboarding cho Dev mới

> Tài liệu tham khảo nội bộ, viết dựa **đúng theo source code thực tế** của project iOS FEELIT (Swift + UIKit). Mục tiêu: dev mới đọc 30–60 phút là nắm toàn bộ app, không cần hỏi lại.
>
> Quy ước: phần giải thích bằng tiếng Việt, tên biến/hàm/file giữ nguyên tiếng Anh. Chỗ nào code chưa rõ sẽ ghi **"Chưa xác định / cần hỏi team"**.

---

## 1. Tổng quan dự án (Project Overview)

**Tên app:** FEELIT (bundle id `vn.feelit.app`). Thư mục git còn tên cũ là `RealtimePoll`; màn `MainViewController` cũng còn hiển thị "Realtime Poll" → app khởi đầu là 1 demo realtime poll rồi được mở rộng thành FEELIT.

**Mục đích sản phẩm:** Mạng xã hội dự đoán/biểu quyết thị trường tài chính (giống prediction market kiểu Kalshi/Polymarket pha trộn feed kiểu Locket). Người dùng vote Tăng/Giảm (YES/NO) cho các poll về VN-Index, vàng, crypto, tỷ giá, lãi suất Fed…; xem kết quả realtime, bình luận, chia sẻ poll vào chat, theo dõi độ chính xác cá nhân.

**Tagline (lấy từ code):**

- `AuthWelcomeViewController`: _"Thể hiện quan điểm & góc nhìn đầu tư"_
- Logo wordmark: **"feelit"** (chữ + chấm xanh trên chữ 'i').

**Đối tượng người dùng:** Nhà đầu tư cá nhân Việt Nam (toàn bộ copy là tiếng Việt; format số/ngày dùng locale `vi_VN`).

---

## 2. Tech Stack

| Layer             | Technology                                             | Version / Ghi chú                                                                     |
| ----------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| Ngôn ngữ          | Swift                                                  | `SWIFT_VERSION = 5.0` (theo project.pbxproj)                                          |
| UI chính          | UIKit (programmatic, Auto Layout)                      | Không dùng Storyboard cho màn hình (chỉ `LaunchScreen`)                               |
| UI phụ            | SwiftUI                                                | Chỉ nhúng cho biểu đồ qua `UIHostingController`                                       |
| Charts            | Apple **Swift Charts**                                 | `PerformanceChart`, `PollChartContent`                                                |
| Charts (tự vẽ)    | CoreGraphics / `UIBezierPath`                          | `SentimentChartView`, `DetailLineChartView`, `IllustrationView`, `CardBackgroundView` |
| Reactive          | Combine                                                | Dùng trong toàn bộ ViewModel (`@Published` + `sink`)                                  |
| Networking REST   | `URLSession` thuần                                     | `APIClient`, `AuthAPIClient` (không Alamofire)                                        |
| Realtime          | **Starscream** (WebSocket)                             | `4.0.8` (Swift Package, theo `Package.resolved`)                                      |
| Realtime protocol | Socket.IO / Engine.IO v4                               | **Tự parse thủ công** trên Starscream (không dùng SDK Socket.IO)                      |
| Widget            | WidgetKit + SwiftUI                                    | Target `PollWidgetExtension`                                                          |
| Push              | `UserNotifications` (APNs + local)                     | `NotificationManager`, `AppDelegate`                                                  |
| Persistence       | `UserDefaults` + Keychain (`Security`)                 | Keychain chỉ cho token (`TokenStore`)                                                 |
| Localization      | String Catalog `Localizable.xcstrings` (vi nguồn + en) | Truy cập qua `L10n.swift` (`String(localized:)`); đã wire một phần (xem §10)          |
| Dependency mgmt   | Swift Package Manager                                  | Chỉ 1 package: Starscream                                                             |
| CI/CD             | Fastlane (Ruby `Gemfile`)                              | Có thư mục `fastlane/` (xem §16)                                                      |

**Dependency bên thứ 3 (duy nhất):**

- Starscream — `https://github.com/daltoniam/Starscream` @ `4.0.8`.

---

## 3. Cấu trúc thư mục (Project Structure)

> Dựa đúng theo các file `.swift` thực tế. Các file `Assets.xcassets`, `Info.plist`, `LaunchScreen` không liệt kê hết.

```
RealtimePoll/                         # Thư mục git (tên cũ)
├── Feelit.xcodeproj                  # Project Xcode (4 targets)
├── Gemfile / Gemfile.lock            # Ruby deps cho Fastlane
├── fastlane/                         # Cấu hình Fastlane (Fastfile…)
│
├── Feelit/                           # ── App chính ──
│   ├── AppDelegate.swift             # APNs register, UNUserNotificationCenter delegate
│   ├── SceneDelegate.swift          # Tạo window + AppRoot (chọn root VC), bật NotificationCoordinator
│   │
│   ├── Chat/                         # Tính năng chat 1-1 (test01/test02)
│   │   ├── ChatLoginViewController.swift     # Nhập ID mình + ID đối phương
│   │   ├── ChatViewController.swift          # Màn chat: REST history + socket realtime + typing
│   │   ├── ChatSocketManager.swift           # WebSocket riêng cho chat (per-instance)
│   │   ├── ChatBubbleCell.swift              # Bubble tin nhắn trái/phải
│   │   ├── SharedPollBubbleCell.swift        # Bubble "card" khi share 1 poll
│   │   ├── SharePollViewController.swift      # Sheet chọn người nhận để share poll
│   │   ├── TypingIndicatorView.swift         # 3 chấm "đang gõ"
│   │   └── Message.swift                      # Model Message + SharedPoll (poll nhúng trong content)
│   │
│   ├── Feelit/                       # Phần lớn UI mới của FEELIT
│   │   ├── Auth/                     # Flow đăng nhập/đăng ký (gọi API thật)
│   │   │   ├── AuthWelcomeViewController.swift       # Màn chào (Tạo TK / Đăng nhập)
│   │   │   ├── AuthEmailInputViewController.swift    # Nhập email
│   │   │   ├── AuthPhoneViewController.swift         # Nhập SĐT + mã quốc gia
│   │   │   ├── AuthPasswordViewController.swift      # Nhập mật khẩu → register/login
│   │   │   ├── AuthOTPViewController.swift           # Nhập OTP 6 số (+ OTPInputView)
│   │   │   ├── AuthForgotPasswordViewController.swift# Quên mật khẩu
│   │   │   ├── AuthResetPasswordViewController.swift # Đặt lại mật khẩu
│   │   │   ├── AuthSuccessViewController.swift       # Màn thành công
│   │   │   ├── AuthFormViewController.swift          # Base class form (bàn phím, nút Tiếp tục)
│   │   │   ├── AuthUI.swift / AuthTheme.swift        # Factory UI + token màu flow Auth
│   │   │   ├── CountryData.swift / CountryPickerViewController.swift  # Danh sách quốc gia
│   │   │   ├── OnboardingUsernameViewController.swift # Onboarding: chọn username
│   │   │   └── OnboardingInterestViewController.swift # Onboarding: chọn chủ đề (ChipsFlowView)
│   │   │
│   │   ├── Components/
│   │   │   ├── NotificationBanner.swift     # Banner in-app trượt từ trên
│   │   │   ├── VoteModal.swift              # Bottom sheet vote nhanh (confetti)
│   │   │   └── SentimentChartView.swift     # Area chart realtime tự vẽ (CoreGraphics)
│   │   │
│   │   ├── Feed/                     # Tab Feed (FeelitTabBarController)
│   │   │   ├── FeedViewController.swift      # Market Pulse + Đang Hot + posts
│   │   │   ├── MarketPulseCell.swift         # Card % bullish toàn thị trường
│   │   │   ├── PollCard.swift                # Cell trending poll (horizontal)
│   │   │   ├── PostCard.swift                # Cell post (like/comment/share/poll embed)
│   │   │   ├── CommentViewController.swift    # Bottom sheet bình luận realtime
│   │   │   ├── CommentCell.swift
│   │   │   ├── FooterButton.swift             # Nút like/comment có bounce
│   │   │   ├── SectionHeaderView.swift
│   │   │   ├── TrendingCardsViewController.swift # "Xem tất cả" Đang Hot (Locket-style)
│   │   │   ├── FlashCardCell.swift            # Thẻ poll full-screen + FlashVoteView
│   │   │   └── IllustrationView.swift         # Minh hoạ vẽ tay theo chủ đề
│   │   │
│   │   ├── Explore/
│   │   │   ├── ExploreViewController.swift    # Tab Explore (search + chips + grid)
│   │   │   └── ExploreCards.swift             # AssetCard, InvestorCard, CategoryChipCell
│   │   │
│   │   ├── Home/                     # "Home mới" (HomeTabBarController + Poll feed kiểu Locket)
│   │   │   ├── HomeTabBarController.swift     # Container tab nổi (FloatingTabBar)
│   │   │   ├── PollFeedViewController.swift   # Tab Poll: feed thẻ full-screen
│   │   │   ├── PollFeedModels.swift           # PollCardItem + mock PollFeedData
│   │   │   ├── PollCardCell.swift             # Thẻ poll (gradient + rail hành động)
│   │   │   ├── PollDetailViewController.swift # Chi tiết poll (chart + rules)
│   │   │   └── DetailLineChartView.swift      # Chart 2 đường CÓ/KHÔNG
│   │   │
│   │   ├── Notifications/
│   │   │   ├── NotificationsViewController.swift  # Danh sách thông báo
│   │   │   └── NotificationCell.swift
│   │   │
│   │   ├── Portfolio/
│   │   │   ├── PortfolioViewController.swift  # Tab Portfolio (accuracy + chart + rewards)
│   │   │   └── PerformanceChartView.swift     # SwiftUI Chart 7 ngày
│   │   │
│   │   ├── Profile/
│   │   │   └── ProfileViewController.swift    # Tab Profile (header + badges + activity)
│   │   │
│   │   ├── Welcome/                  # Flow chào mừng cũ (mock, không gọi API)
│   │   │   ├── LogoLandingViewController.swift   # Splash logo + shared-element transition
│   │   │   ├── WelcomeViewController.swift       # "Create a new account"
│   │   │   └── UsernameInputViewController.swift # Nhập username (mock)
│   │   │
│   │   ├── FeelitColors.swift        # Design tokens: màu (hex)
│   │   ├── FeelitFonts.swift         # Typography + Spacing/Radius/Motion tokens
│   │   ├── FeelitUI.swift            # Component tái sử dụng (GradientView, AvatarView, ChipLabel, VoteBar)
│   │   ├── FeelitModels.swift        # Model UI "FE*" + FEMock (mock data)
│   │   └── FeelitTabBarController.swift  # Tab bar nổi 4 tab (Feed/Explore/Portfolio/Profile)
│   │
│   ├── Main/
│   │   └── MainViewController.swift  # Màn danh sách poll cũ (Realtime Poll) + PollCell
│   │
│   ├── Model/
│   │   ├── Poll.swift                # Poll, VoteRequest, VoteResponse, ChartPoint, PollFinished, APIError
│   │   ├── Comment.swift             # Comment
│   │   ├── AppNotification.swift     # AppNotification, NotificationData, các response
│   │   └── Auth/AuthModels.swift     # Request/Response Auth + UserDTO + AuthError
│   │
│   ├── Network/
│   │   ├── APIClient.swift           # REST chính (poll, chat, posts, notifications, devices)
│   │   ├── AuthAPIClient.swift       # REST Auth/Profile (Bearer token + auto refresh)
│   │   ├── SocketManager.swift       # Socket cho poll (per-instance)
│   │   ├── CommentSocketManager.swift# Socket cho comment/like (per-instance)
│   │   └── NotificationSocketManager.swift # Socket cấp app (singleton)
│   │
│   ├── News/                         # Tab News (flash card mock, chưa nối backend)
│   │   ├── NewsViewController.swift
│   │   ├── NewsCardCell.swift
│   │   └── NewsCard.swift            # Model + NewsSampleData
│   │
│   ├── Poll/
│   │   ├── PollViewController.swift  # Màn live poll (countdown + vote + chart + winner)
│   │   └── PollChartView.swift       # UIKit wrapper bọc SwiftUI Chart
│   │
│   ├── Repository/
│   │   └── PollRepository.swift      # Trung gian API + lưu "đã vote" (UserDefaults)
│   │
│   ├── Util/
│   │   ├── DeviceIdManager.swift     # UUID thiết bị (voterId/userId)
│   │   ├── TokenStore.swift          # Keychain token store
│   │   ├── LikeStore.swift           # Lưu post đã like (UserDefaults)
│   │   ├── NotificationCoordinator.swift # Điều phối thông báo cấp app
│   │   ├── NotificationManager.swift # Quyền push + local notification
│   │   └── L10n.swift                # Key localization tập trung (ít dùng)
│   │
│   └── ViewModel/
│       ├── PollViewModel.swift       # cho PollViewController
│       ├── PollListViewModel.swift   # cho MainViewController
│       ├── FeedViewModel.swift       # cho FeedViewController
│       ├── CommentViewModel.swift    # cho CommentViewController
│       ├── AuthViewModel.swift       # cho flow Auth
│       └── ProfileViewModel.swift    # cho profile (gọi API thật, chưa nối UI)
│
├── FeelitTests/                      # Unit test (chỉ template trống)
├── FeelitUITests/                    # UI test (chỉ template trống)
│
└── PollWidget/                       # ── Widget extension ──
    ├── PollWidget.swift              # Timeline provider + view (small/medium/large)
    └── PollWidgetData.swift          # Model + WidgetSampleData (mock)
```

**Lưu ý cấu trúc:** Có cặp thư mục lồng `Feelit/Feelit/` (đường dẫn vật lý). Đây là kết quả rename `RealtimePoll → Feelit`. Không bịa thêm folder ngoài danh sách trên.

---

## 4. Kiến trúc (Architecture)

### Pattern thực tế: **MVVM toàn bộ** (đã chuyển từ MVVM + MVC pha trộn)

> Trước đây nhiều màn còn là MVC (đọc mock/network thẳng trong VC). Đã refactor: **mọi màn có dữ liệu/logic đều có ViewModel**; VC chỉ dựng UI + bind. Đã verify bằng grep — **không còn `APIClient`/`AuthAPIClient`/`UserDefaults`/`FEMock`/`PollFeedData`/`NewsSampleData` trong bất kỳ `*ViewController.swift` nào** + `BUILD SUCCEEDED`.

- **Nguyên tắc:** ViewModel **không import UIKit** (chỉ Foundation/Combine/CoreGraphics), expose `@Published` (hoặc data tĩnh + completion), View `sink`/đọc qua computed proxy để bind. Logic validate / mock data / gọi API / lưu UserDefaults / socket đều nằm trong ViewModel.
- **17 ViewModel** (thư mục `Feelit/ViewModel/`):
  - Có sẵn từ trước: `PollViewModel`, `PollListViewModel`, `FeedViewModel`, `CommentViewModel`, `AuthViewModel`, `ProfileViewModel`.
  - Tạo mới khi refactor: `ExploreViewModel`, `PortfolioViewModel`, `NewsViewModel`, `PollFeedViewModel`, `TrendingCardsViewModel`, `PollDetailViewModel`, `ChatViewModel`, `ChatLoginViewModel`, `OnboardingUsernameViewModel`, `OnboardingInterestViewModel`, `UsernameInputViewModel`, `SharePollViewModel`, `NotificationsViewModel`.
  - `FeedViewModel` được bổ sung: `trendingPolls`/`marketPulse*` (mock "Đang Hot") + `createPoll(...)`. `ProfileViewModel` bổ sung `profile`/`activities` (mock) cho `ProfileViewController` (vẫn giữ phần API `user: UserDTO?` cho tương lai).
  - `ChatViewModel` ôm trọn socket (`ChatSocketManager`) + messages + typing (in/out) + REST history/send, là delegate của socket; VC chỉ bind `$messages`/`$isPartnerTyping` + `sendDidFail`.
- **Lớp View-only (không cần ViewModel, đúng MVVM):** container/điều hướng (`HomeTabBarController`, `FeelitTabBarController`), splash/animation (`LogoLandingViewController`, `WelcomeViewController`), và toàn bộ cell/component (`PollCard`, `AvatarView`, …).
- **Repository / Service:** `PollRepository` (trung gian poll + lưu đã-vote), `NotificationCoordinator`/`NotificationManager` (service cấp app). ViewModel gọi `APIClient`/`AuthAPIClient`/Repository; **VC không gọi trực tiếp nữa**.

### Sơ đồ luồng dữ liệu (ví dụ luồng có ViewModel — Poll)

```
   ┌────────────────────┐   bind (Combine @Published)   ┌──────────────────┐
   │  PollViewController │  ◀───────────────────────────  │   PollViewModel  │
   │  (View / UIKit)     │   user action (submitVote)     │  (no UIKit)      │
   └────────────────────┘  ───────────────────────────▶  └──────────────────┘
                                                            │            │
                                          ┌─────────────────┘            └──────────────┐
                                          ▼                                               ▼
                                 ┌──────────────────┐                          ┌────────────────────┐
                                 │  PollRepository  │                          │   SocketManager     │
                                 └──────────────────┘                          │ (Starscream WS)     │
                                          │                                     └────────────────────┘
                                          ▼                                               │
                                 ┌──────────────────┐                                     │ vote_update /
                                 │    APIClient     │  ── URLSession REST ──▶  Backend     │ poll_finished
                                 └──────────────────┘                          ◀───────────┘ (Socket.IO)
                                          │                                        Node.js @ :3001
                                          ▼
                                    Backend (Node.js)
```

Luồng mock (ví dụ Explore): `ExploreViewController` → `ExploreViewModel` (giữ `FEMock.assets/investors`) → View bind/đọc qua VM → render. Không qua mạng (nguồn vẫn là mock, nhưng đã nằm trong ViewModel — xem §14).

### Network layer hoạt động thế nào

Có **5 class** mạng, chia 2 nhóm REST + 3 nhóm Socket:

| Class                       | Vai trò                                                                                                                                               | Singleton?                                      |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `APIClient`                 | REST chính: poll, vote, chart, chat messages, posts, comments, like, notifications, devices                                                           | **Singleton** (`APIClient.shared`)              |
| `AuthAPIClient`             | REST Auth/Profile: register/login/verify-otp/refresh/logout, `/api/users/me`. Tự đính `Authorization: Bearer`, tự refresh token khi 401 (retry 1 lần) | **Singleton** (`.shared`)                       |
| `SocketManager`             | Realtime cho 1 poll: `join_poll`, nhận `vote_update`/`poll_finished`                                                                                  | **Per-instance** (mỗi `PollViewModel` tạo 1)    |
| `CommentSocketManager`      | Realtime cho 1 post: `join_post`, nhận `new_comment`/`post_liked`                                                                                     | **Per-instance** (mỗi `CommentViewModel` tạo 1) |
| `NotificationSocketManager` | Realtime cấp app: join room `user:{id}`, nhận `notification`                                                                                          | **Singleton** (`.shared`)                       |

**Engine.IO / Socket.IO handshake — tự implement giống nhau ở cả 3 socket manager:**

1. Mở WS tới `ws://localhost:3001/socket.io/?EIO=4&transport=websocket`.
2. Nhận text bắt đầu bằng `"0"` (Engine.IO OPEN) → parse `sid` → gửi `"40"` (Socket.IO CONNECT).
3. Nhận `"40"` (`"4"` + `"0"`) → coi như Socket.IO connected → gửi join room (`join_poll`/`join_post`/`join_chat`).
4. Nhận `"2"` (PING) → trả `"3"` (PONG) giữ kết nối.
5. Event server: text dạng `42["event_name", {...}]` (`"4"`+`"2"`+payload) → parse JSON array → decode model.
6. Gửi event: `socket.write("42[\"event\",{json}]")`.
7. Mất kết nối còn context (pollId/postId/userId) → `scheduleReconnect()` sau 3s.

---

## 5. Navigation & Scheme

### SceneDelegate setup root

`SceneDelegate.scene(_:willConnectTo:options:)`:

- Tạo `UIWindow`, ép `overrideUserInterfaceStyle = .dark`.
- `window.rootViewController = AppRoot.makeRoot()`.
- Đăng ký observer `.authSessionExpired` → `AppRoot.switchToAuth()`.
- Gọi `NotificationCoordinator.shared.start()` (mở socket app + đồng bộ unread).
- `sceneDidBecomeActive` → `NotificationCoordinator.shared.appDidBecomeActive()`.

**`AppRoot`** (enum trong `SceneDelegate.swift`) quyết định root:

- `makeRoot()`: `TokenStore.shared.isLoggedIn` → `HomeTabBarController()` ; ngược lại → `AuthNavigationController(rootViewController: AuthWelcomeViewController())`.
- `switchToMain()` → `HomeTabBarController()`.
- `switchToAuth()` → `AuthNavigationController(AuthWelcomeViewController())`.

### Targets / Schemes trong project

| Tên                   | Loại             | Ghi chú                      |
| --------------------- | ---------------- | ---------------------------- |
| `Feelit`              | App chính        | Scheme `Feelit`              |
| `PollWidgetExtension` | Widget extension | Scheme `PollWidgetExtension` |
| `FeelitTests`         | Unit test bundle | Template trống               |
| `FeelitUITests`       | UI test bundle   | Template trống               |

### Luồng navigation tổng quát

```
LaunchScreen
   │
SceneDelegate → AppRoot.makeRoot()
   │
   ├── (chưa login) AuthNavigationController
   │       └── AuthWelcomeViewController
   │             ├── "Tạo tài khoản mới" → AuthEmailInputViewController(isRegister:true)
   │             └── "Đăng nhập"        → AuthEmailInputViewController(isRegister:false)
   │                    │  (link) → AuthPhoneViewController
   │                    ▼
   │             AuthPasswordViewController
   │                ├── register → AuthOTPViewController → AuthSuccessViewController
   │                │                                         └→ OnboardingUsernameViewController
   │                │                                               └→ OnboardingInterestViewController
   │                │                                                     └→ HomeTabBarController
   │                └── login → AppRoot.switchToMain() → HomeTabBarController
   │             (Quên MK) → AuthForgotPasswordViewController → AuthResetPasswordViewController
   │
   └── (đã login) HomeTabBarController  (tab nổi tự cuộn — FloatingTabBar)
            ├── [0] Poll    → UINav(PollFeedViewController) → PollDetailViewController
            ├── [1] Live    → HomePlaceholderViewController ("sắp ra mắt")
            ├── [2] Ý tưởng → HomePlaceholderViewController ("sắp ra mắt")
            └── [3] Profile → UINav(ProfileViewController)
```

### ⚠️ Có HAI tab bar controller song song

| Controller                         | Tabs                                                  | Dùng khi                                                        |
| ---------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------- |
| `HomeTabBarController` (Home/)     | Poll, Live, Ý tưởng, Profile (FloatingTabBar tự vẽ)   | Root chính qua `AppRoot`                                        |
| `FeelitTabBarController` (Feelit/) | Feed, Explore, Portfolio, Profile (UITabBar nổi blur) | Đích đến của flow `Welcome/` cũ + `OnboardingInterest.goHome()` |

→ Tuỳ đường vào mà người dùng rơi vào tab bar khác nhau. Đây là **technical debt** (xem §14). `FeelitTabBarController` setup 4 tab qua `wrap(_:icon:)`, ẩn label, icon SF Symbols: `chart.line.uptrend.xyaxis`, `magnifyingglass`, `briefcase`, `person`.

---

## 6. Danh sách màn hình (Screen Inventory)

| Screen                           | File                                            | Mô tả ngắn                                      | Vào từ đâu                                 |
| -------------------------------- | ----------------------------------------------- | ----------------------------------------------- | ------------------------------------------ |
| LogoLandingViewController        | Welcome/LogoLandingViewController.swift         | Splash logo, sau 3s bay sang Welcome            | (Không thấy nơi khởi tạo — xem §14)        |
| WelcomeViewController            | Welcome/WelcomeViewController.swift             | "Create a new account" (mock)                   | LogoLanding                                |
| UsernameInputViewController      | Welcome/UsernameInputViewController.swift       | Nhập username (mock) → FeelitTabBar             | Welcome                                    |
| AuthWelcomeViewController        | Auth/AuthWelcomeViewController.swift            | Màn chào flow Auth thật                         | `AppRoot` (chưa login)                     |
| AuthEmailInputViewController     | Auth/AuthEmailInputViewController.swift         | Nhập email                                      | AuthWelcome                                |
| AuthPhoneViewController          | Auth/AuthPhoneViewController.swift              | Nhập SĐT + mã quốc gia                          | AuthEmailInput ("Dùng SĐT")                |
| AuthPasswordViewController       | Auth/AuthPasswordViewController.swift           | Nhập mật khẩu → register/login                  | Email/Phone                                |
| AuthOTPViewController            | Auth/AuthOTPViewController.swift                | Nhập OTP 6 số                                   | Password (register)                        |
| AuthForgotPasswordViewController | Auth/AuthForgotPasswordViewController.swift     | Nhập email nhận mã reset                        | Password ("Quên mật khẩu?")                |
| AuthResetPasswordViewController  | Auth/AuthResetPasswordViewController.swift      | Mã + mật khẩu mới                               | ForgotPassword                             |
| AuthSuccessViewController        | Auth/AuthSuccessViewController.swift            | "Đăng nhập thành công"                          | OTP                                        |
| OnboardingUsernameViewController | Auth/OnboardingUsernameViewController.swift     | Chọn username                                   | AuthSuccess                                |
| OnboardingInterestViewController | Auth/OnboardingInterestViewController.swift     | Chọn chủ đề → FeelitTabBar                      | OnboardingUsername                         |
| CountryPickerViewController      | Auth/CountryPickerViewController.swift          | Picker quốc gia có search                       | AuthPhone (chip cờ)                        |
| HomeTabBarController             | Home/HomeTabBarController.swift                 | Container tab nổi (Poll/Live/Ý tưởng/Profile)   | `AppRoot` (đã login)                       |
| HomePlaceholderViewController    | Home/HomeTabBarController.swift                 | "sắp ra mắt" (Live, Ý tưởng)                    | HomeTabBar                                 |
| PollFeedViewController           | Home/PollFeedViewController.swift               | Feed thẻ poll full-screen (mock)                | Tab Poll                                   |
| PollDetailViewController         | Home/PollDetailViewController.swift             | Chi tiết poll (chart, rules)                    | PollFeed (chạm thẻ)                        |
| FeelitTabBarController           | Feelit/FeelitTabBarController.swift             | Tab Feed/Explore/Portfolio/Profile              | Welcome/Onboarding cũ                      |
| FeedViewController               | Feed/FeedViewController.swift                   | Market Pulse + Đang Hot + posts                 | FeelitTabBar tab 0                         |
| TrendingCardsViewController      | Feed/TrendingCardsViewController.swift          | "Xem tất cả" Đang Hot (mock)                    | (Có VC, xem §14 về điểm gọi)               |
| CommentViewController            | Feed/CommentViewController.swift                | Bottom sheet bình luận realtime                 | PostCard (nút comment)                     |
| ExploreViewController            | Explore/ExploreViewController.swift             | Search + chips + assets + investors (mock)      | FeelitTabBar tab 1                         |
| PortfolioViewController          | Portfolio/PortfolioViewController.swift         | Accuracy + chart 7 ngày + rewards (mock)        | FeelitTabBar tab 2                         |
| ProfileViewController            | Profile/ProfileViewController.swift             | Header + badges + activity (mock `FEMock.user`) | Tab Profile (cả 2 tab bar)                 |
| NewsViewController               | News/NewsViewController.swift                   | Feed flash card (mock, 6 card)                  | (Có VC, không thấy điểm gắn vào tab — §14) |
| MainViewController               | Main/MainViewController.swift                   | Danh sách poll "Realtime Poll" cũ               | (Có VC, không thấy điểm khởi tạo — §14)    |
| PollViewController               | Poll/PollViewController.swift                   | Live poll: countdown, vote, chart, winner       | createPoll, share poll, mở từ notification |
| ChatLoginViewController          | Chat/ChatLoginViewController.swift              | Nhập ID chat (test01/test02)                    | (Có VC, không thấy điểm gắn — §14)         |
| ChatViewController               | Chat/ChatViewController.swift                   | Chat 1-1 realtime                               | ChatLogin                                  |
| SharePollViewController          | Chat/SharePollViewController.swift              | Chọn người nhận share poll                      | PollViewController (nút share)             |
| NotificationsViewController      | Notifications/NotificationsViewController.swift | Danh sách thông báo                             | FeedViewController (chuông)                |

> Nhiều màn (`MainViewController`, `NewsViewController`, `ChatLoginViewController`, `TrendingCardsViewController`, `LogoLandingViewController`) **có code đầy đủ nhưng không tìm thấy điểm khởi tạo/điều hướng trong source được paste**. Khả năng là tàn dư demo hoặc gắn ở chỗ chưa paste → **cần hỏi team** để xác nhận còn dùng không (xem §14).

---

## 7. Data Models

> Lấy đúng theo `Codable struct` trong code. Backend trả **camelCase** cho hầu hết domain mới, riêng `Poll` dùng **snake_case** (có `CodingKeys`).

### Poll (Model/Poll.swift)

```swift
struct Poll: Codable {
    let id: String
    let title: String
    let status: String        // "active" | "completed"
    let startsAt: String      // CodingKey "starts_at"
    let endsAt: String        // CodingKey "ends_at"
    let yesCount: Int         // CodingKey "yes_count"
    let noCount: Int          // CodingKey "no_count"
    let winner: String?       // "YES" | "NO" | "TIE" | "NO_RESULT" | nil
}
// computed: totalVotes, yesPercentage, noPercentage, endsAtDate, isActive, winnerDisplayText
```

Liên quan: `VoteRequest{voterId, choice}`, `VoteResponse{pollId,yesCount,noCount,totalVotes,yesPercentage,noPercentage}`, `ChartPoint{yesCount,noCount,yesPercentage,noPercentage,recordedAt}`, `PollFinished{pollId,winner,yesCount,noCount,totalVotes,yesPercentage,noPercentage}`, `APIError{error,message}`.

### Comment (Model/Comment.swift)

```swift
struct Comment: Codable {
    let id, postId, userId, username, content, createdAt: String
}
// computed: formattedTime (HH:mm hôm nay / dd/MM), avatarLetter
```

### Message + SharedPoll (Chat/Message.swift)

```swift
struct Message: Codable {
    let id, senderId, receiverId, content, createdAt: String
    static var currentUserId: String   // set khi login chat → phân biệt bubble
}
// computed: isSentByMe, formattedTime, sharedPoll
struct SharedPoll: Codable { let pollId, title: String; let status: String? }
// poll share nhúng vào content: prefix "📊POLL_SHARE::" + JSON
```

### AppNotification (Model/AppNotification.swift)

```swift
struct AppNotification: Codable {
    let id, userId, type, title, body: String
    let data: NotificationData?
    let pollId: String?
    let isRead: Bool
    let createdAt: String
}
struct NotificationData: Codable { let type, pollId, winner: String?; let yesCount, noCount: Int? }
// responses: NotificationListResponse{notifications, unreadCount}, ReadAllResponse, DeviceRegisterResponse
```

### Auth models (Model/Auth/AuthModels.swift)

```swift
struct UserDTO: Codable {
    let id: String; let email, phone: String?
    let username, displayName: String; let avatarUrl, bio: String?
    let isVerified: Bool; let createdAt: String
    let reputation: ReputationDTO
}
struct ReputationDTO: Codable { let xp: Int; let accuracy: Double; let streak, rank, totalUsers: Int }
// Requests: RegisterRequest, VerifyOTPRequest, LoginRequest, RefreshTokenRequest,
//           ForgotPasswordRequest, ResetPasswordRequest
// Responses: RegisterResponse{userId, verificationRequired},
//            AuthSessionResponse{accessToken, refreshToken, user},
//            RefreshTokenResponse, ForgotPasswordResponse{userId, channel}
// enum AuthError: map từ error code server (EMAIL_EXISTS, INVALID_OTP, ...)
```

### PostDTO → FEPost (Feelit/FeelitModels.swift)

```swift
struct PostDTO: Codable {            // decode GET /api/posts (camelCase, field optional)
    let id: String
    let userId, username, badge: String?
    let content: String
    let tags: [String]?
    let likes, commentCount: Int?
    let createdAt, pollId: String?
    func toFEPost() -> FEPost          // map sang model UI
}
```

### Models UI "FE\*" (Feelit/FeelitModels.swift) — chỉ phục vụ render, phần lớn là mock

`FEPoll`, `FEPost`, `FEUser`, `FEBadge`, `FEAsset`, `FEInvestor`, `FEPrediction`, `FEResult`, `FEActivity`, `FlashCard`. Mock tập trung trong `enum FEMock`.

### Models mock khác

- `PollCardItem` + `PollFeedData` (Home/PollFeedModels.swift).
- `NewsCard`/`NewsOption` + `NewsSampleData` (News/NewsCard.swift).
- `WidgetCard`/`WidgetOption`/`WidgetHeadline` + `WidgetSampleData` (PollWidget/PollWidgetData.swift).

---

## 8. Networking Layer chi tiết

### APIClient (Network/APIClient.swift)

- **Singleton** `APIClient.shared`, `URLSession.shared`, `timeoutInterval = 10`.
- `baseURL = "http://localhost:3001"` (hardcode — lưu ý comment trong code ghi 3000 nhưng giá trị thật là **3001**).
- Generic `request<T: Decodable>(path:method:body:completion:)`: set `Content-Type: application/json`, encode body, nếu `statusCode >= 400` thử decode `APIError` → `PollError.serverError`. Có thêm `requestVoid` cho endpoint không trả body.
- Completion-handler (không async/await), `Result<T, Error>`. JSONDecoder/Encoder mặc định (không set keyDecodingStrategy).

**Các method có sẵn:**

| Method                                         | Endpoint                                         |
| ---------------------------------------------- | ------------------------------------------------ |
| `getActivePoll`                                | `GET /api/polls/active`                          |
| `getPoll(pollId:)`                             | `GET /api/polls/:id`                             |
| `getPolls`                                     | `GET /api/polls`                                 |
| `createPoll(title:durationSeconds:)`           | `POST /api/polls` (default 60s)                  |
| `submitVote(pollId:choice:)`                   | `POST /api/polls/:id/votes` (voterId = deviceId) |
| `getChart(pollId:)`                            | `GET /api/polls/:id/chart`                       |
| `getMessages(userId1:userId2:)`                | `GET /api/messages/:u1/:u2`                      |
| `sendMessage(senderId:receiverId:content:)`    | `POST /api/messages`                             |
| `getPosts`                                     | `GET /api/posts`                                 |
| `getComments(postId:)`                         | `GET /api/posts/:postId/comments`                |
| `postComment(postId:userId:username:content:)` | `POST /api/posts/:postId/comments`               |
| `likePost(postId:userId:)`                     | `POST /api/posts/:postId/like`                   |
| `getNotifications(userId:unreadOnly:)`         | `GET /api/notifications/:userId[?unread=true]`   |
| `markNotificationRead(notificationId:)`        | `POST /api/notifications/:id/read` (void)        |
| `markAllNotificationsRead(userId:)`            | `POST /api/notifications/:userId/read-all`       |
| `registerDevice(userId:token:platform:)`       | `POST /api/devices`                              |

### AuthAPIClient (Network/AuthAPIClient.swift)

- **Singleton**, base URL theo build config: **DEBUG** `http://localhost:3001`, **RELEASE** `https://api.feelit.vn`.
- Tự đính `Authorization: Bearer {accessToken}` cho endpoint cần auth.
- **Auto refresh token:** gặp `401` ở request cần auth → gọi `/api/auth/refresh` (1 lần) rồi retry; refresh fail → `clearSession()` + post `.authSessionExpired`.
- Endpoints: `register`, `verifyOTP` (lưu session), `resendOTP`, `login` (lưu session), `forgotPassword`, `resetPassword`, `logout`, `getCurrentUser` (`/api/users/me`), `updateProfile` (`PATCH /api/users/me`).

### 3 Socket Manager — khác nhau ở điểm nào

- **Giống nhau:** đều `WebSocketDelegate` (Starscream), cùng `serverURL = ws://localhost:3001/...EIO=4`, cùng cách parse Engine.IO (`0/2/4`), cùng `scheduleReconnect()` 3s.
- **Khác nhau:**
  - `SocketManager` — **per-instance**, theo dõi `currentPollId`, event `join_poll`/`leave_poll`; delegate nhận `vote_update`, `poll_finished`. Có `socketDidConnect/Disconnect` để cập nhật badge "Live".
  - `CommentSocketManager` — **per-instance**, theo dõi `currentPostId`, `join_post`/`leave_post`; delegate nhận `new_comment`, `post_liked`.
  - `NotificationSocketManager` — **singleton** `.shared`, theo dõi `userId`, join room cá nhân bằng `join_chat` (`{userId}`); delegate nhận `notification`. Luôn reconnect khi còn `userId`.

### Danh sách Socket.IO events (tìm thấy trong code)

| Hướng           | Event                      | Nơi dùng                                        |
| --------------- | -------------------------- | ----------------------------------------------- |
| client → server | `join_poll` / `leave_poll` | SocketManager                                   |
| client → server | `join_post` / `leave_post` | CommentSocketManager                            |
| client → server | `join_chat`                | ChatSocketManager, NotificationSocketManager    |
| client → server | `typing`                   | ChatSocketManager                               |
| server → client | `vote_update`              | SocketManager → PollViewModel                   |
| server → client | `poll_finished`            | SocketManager → PollViewModel                   |
| server → client | `new_comment`              | CommentSocketManager                            |
| server → client | `post_liked`               | CommentSocketManager (delegate có default rỗng) |
| server → client | `new_message`              | ChatSocketManager                               |
| server → client | `typing`                   | ChatSocketManager                               |
| server → client | `notification`             | NotificationSocketManager                       |

> Lưu ý: `CommentSocketManager` có `join_post`/`new_comment` nhưng `CommentViewModel` đang gọi `connectForPost`; `FeedViewModel` thì **không dùng socket** (comment trong code ghi rõ Feed không có socket, "Đang Hot" dùng mock tĩnh).

---

## 9. UI / Design System

### FeelitColors (Feelit/FeelitColors.swift) — theme **dark**

| Token           | Hex                                   |
| --------------- | ------------------------------------- |
| background      | `#0A0A0F`                             |
| surface         | `#13131A`                             |
| surfaceElevated | `#1C1C27`                             |
| primary         | `#6C63FF` (+ `primarySoft` alpha .10) |
| bullish         | `#00D085` (+ `bullishSoft`)           |
| bearish         | `#FF4D6A` (+ `bearishSoft`)           |
| gold            | `#FFB547` (+ `goldSoft`)              |
| textPrimary     | `#F0F0FF`                             |
| textSecondary   | `#8888AA`                             |
| textTertiary    | `#44445A`                             |
| border          | white alpha .06                       |
| overlay         | black alpha .50                       |
| avatarGradient  | primary → bullish                     |

`UIColor(hex:)` hỗ trợ `0xRRGGBB` và `0xRRGGBBAA`. (News/Widget có thêm `UIColor(hex:String)`/`Color(hex:)` từ chuỗi "#RRGGBB".)

### AuthTheme (Feelit/Auth/AuthTheme.swift) — theme **light** riêng cho flow Auth

nền `#FBFBFB`, inputField `#F7F7F7`, green `#4CAF50`, textPrimary `#202020`, bad `#F44336`, fieldBorder `#CCCCCC`, fieldBorderActive `#366837`… (flow Auth ép `.light`, các màn còn lại `.dark`).

### FeelitFonts (Feelit/FeelitFonts.swift)

| Style   | Giá trị                                 |
| ------- | --------------------------------------- |
| display | SF Pro Rounded Bold 32                  |
| heading | SF Pro Rounded Bold 22                  |
| title   | SF Pro Semibold 17                      |
| body    | SF Pro Regular 15                       |
| caption | SF Pro Regular 13                       |
| micro   | SF Pro Medium 11 (uppercase + kern 0.5) |

`FeelitFonts.rounded(_:weight:)` → SF Pro Rounded (fallback system). Không có font custom bundle.

### Component tái sử dụng

- **Feelit/FeelitUI.swift:** `GradientView` (CAGradientLayer), `AvatarView` (gradient + chữ cái đầu), `ChipLabel` (label bo có inset), `VoteBar` (thanh YES/NO animate). Extension `UIView.applyCardStyle(...)`, `animateTapScale()`.
- **Auth:** `AuthUI` (factory backButton/fieldContainer/continueButton…), `FeelitLogoView` (wordmark vẽ tay), `OTPInputView`, `ChipsFlowView`, `CountryPickerViewController`.
- **Khác:** `NotificationBanner`, `VoteModal`, `SentimentChartView`, `PaddingLabel`/`ActionRailItem` (Home), `FlashVoteView`/`IllustrationView` (Feed), `TypingIndicatorView` (Chat).

### Spacing / Radius / Motion tokens (Feelit/FeelitFonts.swift)

```swift
enum Spacing { xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32, huge=48 }
enum Radius  { badge=8, button=12, smallCard=16, card=20, largeCard=24 }
enum Motion  { duration=0.3, damping=0.75, velocity=0.5 }
enum FeelitLayout { scrollBottomInset=110 }   // chừa chỗ cho tab bar nổi
```

> Lưu ý: 2 theme (Auth dùng số literal/`AuthTheme`, phần FEELIT dùng token). Không thống nhất hoàn toàn.

---

## 10. Localization

> Mục này đã được **rà soát theo Apple String Catalog workflow** (https://developer.apple.com/documentation/xcode/localization) và **fix lại cho đúng**. Xem cuối mục để biết phần đã sửa & phần còn lại.

### Cơ chế (đúng theo Apple)

- App dùng **String Catalog** `Feelit/Localizable.xcstrings` — định dạng `.xcstrings` (JSON) Xcode quản lý, thay cho `.strings` cũ.
- File khai báo `"sourceLanguage" : "vi"` và có **2 ngôn ngữ dịch đầy đủ: `vi` (nguồn) + `en`** cho ~60 key (symbolic key kiểu `auth.button.continue`, `poll.winner.yes`…), gồm cả **plural variations** (`feed.comments_title`, `poll.votes_count` có `one`/`other` cho en).
- `Util/L10n.swift` là lớp truy cập tập trung, mỗi accessor gọi `String(localized: "key")`. Xcode auto-extract các key này tại build time.
- Build settings bật `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` (đúng khuyến nghị Xcode mới). Catalog được đưa vào build **tự động** qua `fileSystemSynchronizedGroups` (objectVersion 77 / Xcode 16) — không cần khai báo thủ công trong pbxproj.

### Nguyên tắc Apple liên quan (đã áp dụng khi fix)

- **Source/development language phải khớp** giữa: ngôn ngữ literal trong code, `sourceLanguage` của catalog, và `developmentRegion` của project. App này literal là tiếng Việt + catalog `vi` → development region phải là `vi`.
- Xcode **auto-extract** chuỗi từ `String(localized:)` và SwiftUI `Text(...)` mỗi lần build; key chỉ được giữ nếu **được tham chiếu trong code**, nếu không sẽ bị đánh dấu **stale**.
- `state` của mỗi string: `new` (vừa trích) / `translated` / `needs_review` / `stale` (không còn trong code).
- Apple khuyến nghị dùng **natural-language key** (chính chuỗi hiển thị làm key); project này chọn **symbolic key** — vẫn hợp lệ vì mỗi key có value `vi`/`en` tường minh trong catalog.

### Cấu trúc `L10n`

Các enum lồng theo nhóm: `Common`, `Auth`, `Poll`, `Feed`, `Chat`, `Tab`, `Profile`. Hàm format tham số: `Poll.votesCount(_:)`, `Poll.voteTotals(yes:no:total:)`, `Feed.commentsTitle(_:)`, `Chat.chatWithTitle(_:)`.

### Ngôn ngữ support

**Tiếng Việt (nguồn) + Tiếng Anh.** `knownRegions = (en, Base, vi)`. Format số/ngày dùng `Locale(identifier: "vi_VN")` ở `PostDTO.relativeTime`, `Comment/AppNotification.formattedTime` (chưa theo locale máy — xem §14).

### Vấn đề đã phát hiện & ĐÃ FIX

1. **Sai source language (config):** project để `developmentRegion = en` trong khi catalog `sourceLanguage = vi` và mọi literal là tiếng Việt → mâu thuẫn theo Apple. **Đã sửa `developmentRegion = vi`** (`Feelit.xcodeproj/project.pbxproj`).
2. **Catalog + `L10n` là code chết:** trước đây `L10n.` / `String(localized:)` **không được gọi ở bất kỳ đâu** (0 lần) — toàn bộ ~60 key đã dịch nhưng vô dụng, UI hardcode tiếng Việt. **Đã wire `L10n` vào code thật** cho các vùng có key sẵn:
   - **Auth chrome dùng chung** (`AuthUI.swift`, `AuthFormViewController.swift`): nút "Trở lại"/"Tiếp tục" + dòng điều khoản → áp dụng cho **toàn bộ màn Auth**.
   - **Auth placeholders**: email/password/phone (`AuthEmailInput`, `AuthPassword`, `AuthPhone`, `AuthForgotPassword`).
   - **Chat**: `ChatLoginViewController` (placeholder/nút/alert), `ChatViewController` (title, placeholder, nút Gửi, alert).
   - **Comment**: `CommentViewController` (placeholder, empty state, tiêu đề số bình luận dùng plural `Feed.commentsTitle`).
   - **Common**: alert `OK`/`Lỗi`/`Gửi` ở các màn trên.
   - Tất cả là swap literal → accessor `L10n` (giá trị `vi` trùng literal cũ ⇒ không đổi behavior tiếng Việt, nhưng nay có sẵn bản `en`). **Đã build `BUILD SUCCEEDED`.**

### Phần CÒN LẠI (technical debt localization — chưa fix)

- Phần lớn UI vẫn hardcode tiếng Việt và **chưa có key**: `MainViewController`, `FeedViewController` ("🔥 Đang Hot", "Tạo Poll Mới"…), `Explore/Portfolio/Profile`, `Home/PollFeed/PollDetail`, `News`, `Welcome/Onboarding`, `PollViewController` (winner/connection build bằng nội suy + emoji), `NotificationBanner`… → cần thêm key vào catalog rồi wire tiếp theo đúng pattern trên.
- **Catalog bị "ô nhiễm" auto-extract:** có vài entry rỗng (chưa dịch) Xcode tự trích từ SwiftUI/Swift Charts: `"Lần"`, `"Ngày"`, `"Phe"`, `"Độ chính xác"`, `"Waiting for votes..."`, `"%"`, `"%lld%%"` (từ `.value("Lần", …)` trong chart và `Text("Waiting for votes...")` ở `PollChartView`). Đây là các chuỗi _thực sự_ đang được localize duy nhất trước khi fix. Cần: dịch `"Waiting for votes..."` cho đúng, và xử lý nhãn chart (chuỗi định danh series, có thể bỏ qua dịch).
- Các key `L10n` chưa được wire (Poll/Tab/Profile/…) sẽ bị Xcode đánh dấu **stale** cho tới khi code tham chiếu — đúng theo cơ chế Apple, không phải lỗi.
- `formattedTime`/`relativeTime` hardcode `vi_VN` thay vì locale người dùng → khi chạy `en` ngày giờ vẫn ra tiếng Việt.

---

## 11. Authentication Flow

### Có 2 flow song song (lưu ý kỹ)

**A) Flow Auth THẬT — gọi backend (Auth/\* + AuthViewModel + AuthAPIClient):**

- `AuthWelcome → Email/Phone → Password`:
  - Đăng ký: `AuthViewModel.register` → `POST /api/auth/register` → có `userId` → `AuthOTPViewController` → `verifyOTP` (`POST /api/auth/verify-otp`) → lưu session (Keychain) → `AuthSuccess` → onboarding → Home.
  - Đăng nhập: `AuthViewModel.login` → `POST /api/auth/login` → lưu session → `AppRoot.switchToMain()`.
  - Quên/đặt lại MK: `/api/auth/forgot-password`, `/api/auth/reset-password`.
- → Phần Auth **không phải mock**, nó nối API thật. Tuy nhiên backend mặc định trỏ `localhost:3001` (DEBUG) nên phải chạy server.

**B) Flow Welcome CŨ — MOCK, KHÔNG gọi API:**

- `LogoLanding → Welcome → UsernameInput`: các nút "Continue with Google/Apple", "Log In", "Sign In" chỉ chuyển màn rồi vào thẳng `FeelitTabBarController`/`HomeTabBarController`, **không xác thực gì**. `UsernameInput`/`Onboarding` chỉ `UserDefaults.set(...)`.
- **ĐANG DÙNG MOCK, CHƯA NỐI API THẬT** cho nhóm màn Welcome này. Đăng nhập Google/Apple chưa được hiện thực.

> Hai flow này khởi đầu khác nhau và dẫn tới 2 tab bar khác nhau → cần thống nhất (xem §14).

### Token storage

- **Keychain** qua `TokenStore` (service `vn.feelit.auth`): `accessToken`, `refreshToken`, `userId`. `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- `isLoggedIn = accessToken != nil`. `AppRoot.makeRoot()` dựa vào đây.
- Session hết hạn (refresh cũng fail) → post `.authSessionExpired` → SceneDelegate → `AppRoot.switchToAuth()`.

> Lưu ý: `userId` cho chat/notification/vote **không** lấy từ TokenStore mà từ `DeviceIdManager.deviceId` (UUID thiết bị). Tức danh tính "đã đăng nhập" (auth) và danh tính dùng cho poll/notification (deviceId) là **hai hệ riêng** — cần lưu ý khi nối backend thật.

---

## 12. Persistent Storage

### UserDefaults keys (rải rác trong code)

| Key                | Nơi dùng                                 | Ý nghĩa                        |
| ------------------ | ---------------------------------------- | ------------------------------ |
| `poll_device_id`   | `DeviceIdManager`                        | UUID thiết bị (voterId/userId) |
| `voted_poll_ids`   | `PollRepository`                         | Danh sách pollId đã vote       |
| `liked_post_ids`   | `LikeStore`                              | Danh sách postId đã like       |
| `feelit_username`  | Onboarding/Username VC, CommentViewModel | Username người dùng            |
| `feelit_interests` | OnboardingInterest                       | Mảng chủ đề quan tâm           |
| `chat_my_id`       | ChatLogin / SharePoll                    | ID chat đã chọn lần trước      |

### Keychain

- Chỉ `TokenStore` (xem §11): `accessToken`, `refreshToken`, `userId` (service `vn.feelit.auth`).

---

## 13. Background Features

### Notification system

- **APNs:** `AppDelegate.didFinishLaunching` → `NotificationManager.requestAuthorizationAndRegister()` (xin quyền `.alert/.badge/.sound`, được cấp → `registerForRemoteNotifications`). Nhận device token → `APIClient.registerDevice(userId: NotificationCoordinator.shared.currentUserId, token:, platform:"ios")`.
- **Foreground:** `willPresent` trả `[]` (ẩn push hệ thống, vì socket đã hiện `NotificationBanner` in-app — tránh trùng).
- **Tap push:** `didReceive` đọc `pollId` (top-level hoặc trong `data`) → `NotificationCoordinator.shared.openPoll(pollId:)`.
- **Realtime in-app:** `NotificationSocketManager` (singleton) nhận event `notification` → `NotificationCoordinator.didReceiveAppNotification` → `unreadCount += 1` + hiện `NotificationBanner` (tap → mở poll).
- **`NotificationCoordinator`** (Util): điều phối — `start()` khi app mở, `appDidBecomeActive()` khi vào foreground, `refreshUnread()` (`GET /api/notifications/:id?unread=true`), `openPoll()` (chọn tab 0, push `PollViewController`). Phát `.feelitUnreadDidChange` để cập nhật badge chuông ở `FeedViewController`.
- **Local notification (fallback):** `NotificationManager.schedulePollFinished(pollId:title:at:)` — hẹn local notification tại thời điểm poll kết thúc (chạy được cả trên Simulator, nơi APNs không hoạt động). `PollViewModel.scheduleCompletionNotification()` gọi khi vote thành công; `cancel(pollId:)` khi nhận `poll_finished` realtime.

### Widget (PollWidget extension)

- **Provider:** `PollProvider: TimelineProvider`. `getTimeline` tạo entry **xoay vòng 6 card, mỗi card 30 phút** (`Calendar.date(byAdding: .minute, value: i*30)`), policy `.atEnd`.
- **Nguồn dữ liệu:** `WidgetSampleData.cards` — **mock fix sẵn** (cùng nội dung với feed app), KHÔNG gọi backend/không share data với app (không thấy App Group).
- **Families hỗ trợ:** `.systemSmall`, `.systemMedium`, `.systemLarge` (layout riêng từng cỡ). Bundle `PollWidgetBundle` (`@main`).

---

## 14. Known Issues / Technical Debt

> Phần quan trọng nhất — đọc kỹ trước khi sửa.

1. **Hai tab bar controller song song** (`HomeTabBarController` vs `FeelitTabBarController`) với 2 bộ tab khác nhau, vào từ 2 flow khác nhau → trải nghiệm không nhất quán. Cần quyết định giữ cái nào.
2. **Hai flow onboarding/welcome song song**: `Welcome/` (mock, Google/Apple giả) và `Auth/` (API thật). Dễ gây nhầm. `LogoLandingViewController` (splash) **không thấy được khởi tạo** trong source paste — cần xác nhận có còn là entry point không.
3. **Nhiều VC "mồ côi"**: `MainViewController` (Realtime Poll cũ), `NewsViewController`, `ChatLoginViewController`, `TrendingCardsViewController` — code đầy đủ nhưng **không tìm thấy điểm điều hướng**. Cần làm rõ còn dùng/đã chết.
4. **URL hardcode, chưa tách DEBUG/RELEASE đồng bộ:**
   - `APIClient.baseURL = "http://localhost:3001"` (hardcode, **không** có nhánh RELEASE) — comment còn ghi nhầm 3000.
   - Tất cả Socket manager hardcode `ws://localhost:3001/...` (comment "⚠️ Đổi IP khi test trên device thật").
   - Chỉ `AuthAPIClient` có `#if DEBUG / #else` (`api.feelit.vn`). → Build Release sẽ gọi REST/socket vào localhost → hỏng. **Cần gom config về 1 nơi.**
5. **`ATS` / HTTP cleartext:** dùng `http://` + `ws://` localhost → cần `NSAppTransportSecurity` exception trong Info.plist (không thấy plist trong source — cần kiểm tra).
6. **OTP / auth phụ thuộc backend demo:** mã OTP do server cấp; nếu server demo cố định mã thì lưu ý khi test. **Cần hỏi team** quy ước OTP môi trường dev. Chat giới hạn cứng `["test01","test02"]`.
7. **Hai hệ danh tính**: auth dùng Keychain `userId`, còn poll/comment/notification dùng `DeviceIdManager.deviceId`. Khi nối backend thật cần hợp nhất, nếu không thông báo/vote sẽ không gắn đúng user đã đăng nhập.
8. **Mock lẫn real (sau khi đã chuyển hết sang MVVM):** dữ liệu giờ nằm trong ViewModel nhưng **nguồn vẫn là mock** cho: Explore, Portfolio, Profile (`ProfileViewModel.profile` = `FEMock.user`; phần API `user: UserDTO?` đã có nhưng chưa nối UI), News, PollFeed/PollDetail, TrendingCards, và section "Đang Hot"/Market Pulse của Feed. Cần thay mock bằng API thật trong các ViewModel này. `FeedViewModel` vẫn không có socket realtime cho comment/like ở feed.
9. **Localization (ĐÃ FIX MỘT PHẦN — xem §10):** `Localizable.xcstrings` **có tồn tại** (vi nguồn + en, ~60 key, có plural). Trước đây `L10n`/catalog là code chết (0 lần gọi) và `developmentRegion=en` lệch với `sourceLanguage=vi`. Đã sửa: căn lại `developmentRegion=vi` + wire `L10n` cho Auth/Chat/Comment/Common (build pass). **Còn lại:** phần lớn UI khác vẫn hardcode (thiếu key), catalog bị auto-extract vài chuỗi rỗng từ SwiftUI/Charts, ngày giờ hardcode `vi_VN`, và đa số thiếu accessibility label (dù `L10n` đã có key `*.accessibility`).
10. **`PollViewController` dùng `objc_setAssociatedObject` + key `static var` (`AssociatedKeys.closeAction`)** để giữ closure đóng popup — pattern dễ lỗi, nên refactor sang property thường.
11. **Emoji vỡ trong source**: `PollViewController.yesButton` có `config.title = "��  YES"` (ký tự emoji bị hỏng khi lưu file) — cần sửa lại "👍".
12. **Reconnect socket đơn giản**: timer cố định 3s, không backoff, không giới hạn số lần; nhiều socket chạy song song (mỗi poll/post 1 instance) — cần để ý tải kết nối khi mở nhiều màn.
13. **Widget không chia sẻ dữ liệu với app** (mock riêng, không App Group) → số liệu widget luôn tĩnh.
14. **`fastlane beta` đang hỏng build** (ngữ cảnh hiện tại): scheme auto-generated bị mất sau khi rename `RealtimePoll → Feelit` khiến `xcodebuild` báo "no destinations". Đang xử lý bằng cách thêm shared scheme `Feelit.xcscheme` (xem §16).

---

## 15. Cách chạy project (Setup Instructions)

1. **Yêu cầu:**
   - Xcode 26.x (môi trường hiện tại: Xcode 26.5) + iOS SDK 26.5.
   - iOS minimum target: **Chưa xác định trong source paste** (không thấy `IPHONEOS_DEPLOYMENT_TARGET` trong các đoạn pbxproj đã đọc) → cần kiểm tra Build Settings.
2. **Mở project:** mở `Feelit.xcodeproj` (KHÔNG có workspace). Scheme: `Feelit`.
3. **Swift Package dependencies:** Xcode tự resolve. Package duy nhất:
   - **Starscream** — `https://github.com/daltoniam/Starscream` (pinned `4.0.8`).
4. **Backend chạy song song (BẮT BUỘC cho phần realtime/auth/feed):**
   - App gọi REST + WebSocket vào **`localhost:3001`** (cả `APIClient`, các SocketManager; `AuthAPIClient` DEBUG cũng `:3001`).
   - **Lệnh start server / repo backend: Chưa có trong source iOS này → cần hỏi team** (đây là project Node.js riêng).
   - Device thật: sửa `baseURL`/`serverURL` thành IP LAN của Mac.
5. **Build & run Simulator:** chọn scheme `Feelit` + 1 iPhone Simulator → Run. Nếu chưa login (chưa có token Keychain) sẽ vào flow Auth (`AuthWelcomeViewController`).
   - Có thể đi đường mock (Welcome/Onboarding) để vào Home mà không cần backend, nhưng các tab dữ liệu thật (poll live, feed posts, chat, notifications) cần server.

---

## 16. Build & Deploy

- **Build configurations:** `Debug` và `Release` (cho cả app & widget).
- **Bundle ID:** `vn.feelit.app` (app). **Team:** `3KYTL85W67`. **Code signing:** Automatic (`CODE_SIGN_STYLE = Automatic`). Entitlements: `Feelit/Feelit.entitlements`.
- **Targets cần signing:** `Feelit`, `PollWidgetExtension`.
- **MARKETING_VERSION:** `1.0`. **CURRENT_PROJECT_VERSION:** quản lý bằng `agvtool` (Fastlane tự tăng — hiện build ~11).
- **TestFlight / Fastlane:** Có `Gemfile` + thư mục `fastlane/`. Lane `ios beta` (theo log) làm: `app_store_connect_api_key` → `increment_build_number` (agvtool) → `update_code_signing_settings` (Automatic, targets `Feelit` + `PollWidgetExtension`) → `build_app` (gym, scheme `Feelit`, export `app-store`).
  - **Đang lỗi:** `build_app` fail vì scheme `Feelit` báo "no destinations" sau khi rename project. Nguyên nhân: `xcschememanagement.plist` khai báo shared scheme `Feelit.xcscheme` / `PollWidgetExtension.xcscheme` nhưng **file scheme không tồn tại trên đĩa** → Xcode tạo scheme fallback hỏng (`SUPPORTED_PLATFORMS` rỗng). Cách khắc phục đang làm: tạo file shared scheme thật trong `Feelit.xcodeproj/xcshareddata/xcschemes/`. (Nội dung Fastfile đầy đủ không nằm trong source paste — tham khảo `fastlane/Fastfile`.)

---

## 17. Coding Conventions quan sát được

- **Cấu trúc ViewController:** Hầu hết dùng UIKit programmatic, chia method `setupUI()/setupLayout()` + `setupActions()`/`bindViewModel()`, gọi trong `viewDidLoad`. UI element khai báo là `private let ... = { ... }()` (closure init). Nhiều `final class`.
- **MARK comments:** Dùng dày đặc, style `// MARK: - Tên` để chia vùng (Lifecycle / UI / Actions / Helpers…). Mỗi class thường có doc comment `///` tiếng Việt mô tả vai trò + node Figma tương ứng.
- **Naming:**
  - Model UI mock prefix `FE*` (tránh trùng `Poll` thật trong `Model/`).
  - Cell có `static let reuseId`.
  - Biến private không có prefix `_`; dùng `private`/`private(set)`.
  - `required init?(coder:) { fatalError(...) }` ở hầu hết view custom.
- **Threading:** Network callback luôn `DispatchQueue.main.async { ... }` trước khi đụng UI. ViewModel `@Published` + `.receive(on: DispatchQueue.main)` ở View. Socket parse cũng `DispatchQueue.main.async` trước khi gọi delegate.
- **Error/Optional handling:**
  - Dùng `guard let self = self else { return }` / `guard let self else { return }` trong closure (`[weak self]`).
  - `guard let ... else { return }` phổ biến; `try?` cho JSON parse trong socket.
  - **Force unwrap có xuất hiện** ở chỗ "chắc chắn": `Section(rawValue: ...)!`, `as! SomeCell` khi dequeue, `Countries.all.first { $0.iso == "VN" }!`. Force-cast cell là pattern xuyên suốt.
  - `Result<T, Error>` cho mọi REST completion; lỗi map sang `PollError`/`AuthError` có message tiếng Việt.
- **Combine:** ViewModel expose `@Published private(set)`; View giữ `Set<AnyCancellable>`; nhiều chỗ dùng `Future`/`Publishers.CombineLatest`.
- **Memory:** `[weak self]` trong closure async/timer; `deinit` chủ động `invalidate()` timer, `disconnect()` socket, `removeObserver`.

---

_Hết tài liệu. Các mục ghi "Chưa xác định / cần hỏi team" cần xác nhận trực tiếp vì không suy ra được từ source code đã cung cấp._
