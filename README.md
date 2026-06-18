# 🗳️ FEELIT — Social Investing & Market Consensus

> **Feel what the market feels.**  
> Nền tảng bình chọn nhận định thị trường theo thời gian thực cho nhà đầu tư Việt Nam.

---

## 📋 Mục lục

- [Tổng quan](#tổng-quan)
- [Tính năng](#tính-năng)
- [Tech Stack](#tech-stack)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Cài đặt Backend](#cài-đặt-backend)
- [Cài đặt iOS App](#cài-đặt-ios-app)
- [Test 2 Simulator](#test-2-simulator-cùng-lúc)
- [Cấu trúc Project](#cấu-trúc-project)
- [API Reference](#api-reference)
- [Socket.IO Events](#socketio-events)
- [Cấu hình & Biến môi trường](#cấu-hình--biến-môi-trường)
- [Lỗi thường gặp](#lỗi-thường-gặp)
- [Architecture](#architecture)

---

## Tổng quan

FEELIT gồm 2 phần:

- **Backend** — Node.js server xử lý polls, votes, posts, comments, notifications
- **iOS App** — Swift + UIKit, realtime qua Socket.IO

---

## Tính năng

### Polls & Voting
- Tạo poll YES/NO với thời gian tùy chỉnh
- Vote realtime — cập nhật tức thì trên tất cả thiết bị
- Biểu đồ theo dõi diễn biến vote (CoreGraphics)
- Đồng hồ đếm ngược, tự động công bố winner
- Chống vote trùng theo device UUID
- Auto simulate ~1000 votes để test realtime

### Feed & Social
- Danh sách bài viết nhận định thị trường
- Flash cards dạng swipe (Tinder-style)
- Like, comment bài viết realtime
- Tag tài sản (#VN-INDEX, #BTC, #GOLD...)
- Embedded poll trong bài viết

### Explore
- Tìm kiếm cổ phiếu, nhà đầu tư
- Filter theo danh mục (Chứng khoán, Crypto, Vàng...)
- Trending assets grid
- Top investors leaderboard

### Portfolio & Profile
- Theo dõi độ chính xác dự đoán
- Xếp hạng trong cộng đồng
- Streak, badges, điểm thưởng
- Lịch sử dự đoán

### Auth
- Đăng nhập bằng Email hoặc Số điện thoại
- Quên mật khẩu, đặt lại mật khẩu
- Onboarding flow

### Notifications
- In-app banner realtime (Socket.IO)
- Push notification (APNs — thiết bị thật)
- Local notification fallback (Simulator)
- Badge unread count

### Widget (iOS Home Screen)
- Flash poll Widget (Small / Medium / Large)
- Xoay vòng 6 cards mỗi 30 phút

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS Language | Swift 5.9 |
| iOS UI | UIKit (programmatic, không Storyboard) |
| iOS Realtime | Starscream 4.0.8 (WebSocket) |
| iOS HTTP | URLSession + Codable |
| iOS Widget | WidgetKit + SwiftUI |
| Backend Runtime | Node.js v18+ |
| Backend Framework | Express.js |
| Realtime | Socket.IO |
| Database | SQLite (sql.js — thuần JS) |
| ID Generation | uuid |

---

## Yêu cầu hệ thống

| Tool | Phiên bản |
|------|-----------|
| macOS | 13.0+ (Ventura) |
| Xcode | 15.0+ |
| Node.js | 18.0+ |
| npm | 8.0+ |
| iOS Simulator | iOS 15.0+ |

Kiểm tra:
```bash
node --version   # >= 18
npm --version    # >= 8
xcodebuild -version  # >= 15
```

---

## Cài đặt Backend

### Bước 1 — Vào thư mục
```bash
cd realtime-poll-server
```

### Bước 2 — Cài dependencies
```bash
npm install
```

### Bước 3 — Chạy server

**Development** (tự restart khi sửa code):
```bash
npm run dev
```

**Production**:
```bash
npm start
```

### Bước 4 — Kiểm tra hoạt động

Mở browser: `http://localhost:3001`

Hoặc dùng curl:
```bash
curl http://localhost:3001/
# {"status":"ok","message":"🗳️ Realtime Poll Server is running!"}
```

### Output khi start thành công
```
🆕 Created new database.   (lần đầu)
✅ Database tables ready.

══════════════════════════════════════════
🚀 Realtime Poll Server started!
📡 http://localhost:3001
══════════════════════════════════════════
```

> **Lưu ý:** File `data/polls.db` tự động tạo khi chạy lần đầu. Không cần tạo thủ công.

---

## Cài đặt iOS App

### Bước 1 — Mở Xcode
```bash
open RealtimePoll.xcodeproj
```

### Bước 2 — Thêm Starscream (nếu chưa có)

`File → Add Package Dependencies`
```
https://github.com/daltoniam/Starscream
```
Version: **Up to Next Major 4.0.6**  
Target: **RealtimePoll** (không phải Tests)

### Bước 3 — Kiểm tra Info.plist

Đảm bảo có `NSAppTransportSecurity` để cho phép HTTP local:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Bước 4 — Build & Run

Chọn Simulator **iPhone 15 Pro Max** (hoặc bất kỳ iPhone iOS 15+)

Nhấn **⌘ + R**

---

## Test 2 Simulator cùng lúc

Cần 2 simulator để test realtime vote và comment.

### Bước 1 — Build lên simulator đầu tiên
Chọn destination **iPhone 15 Pro Max** → **⌘ + R**

### Bước 2 — Boot simulator thứ hai
```bash
# Xem danh sách simulators có sẵn
xcrun simctl list devices | grep -E "iPhone 15|iPhone 16"

# Boot iPhone 15 (tên chính xác tùy Xcode version)
xcrun simctl boot "iPhone 15"

# Mở app Simulator
open -a Simulator
```

### Bước 3 — Cài app lên simulator thứ hai
```bash
# Lấy đường dẫn app vừa build
APP=$(find ~/Library/Developer/Xcode/DerivedData \
  -name "RealtimePoll.app" -type d \
  -not -path "*/Index.noindex/*" 2>/dev/null | head -1)

echo "App path: $APP"

# Cài lên simulator thứ hai
xcrun simctl install "iPhone 15" "$APP"

# Chạy app
xcrun simctl launch "iPhone 15" $(defaults read "$APP/Info.plist" CFBundleIdentifier)
```

### Bước 4 — Tạo poll để test
```bash
curl -X POST http://localhost:3001/api/polls \
  -H "Content-Type: application/json" \
  -d '{"title": "VN-INDEX sẽ vượt 1300 tuần này?", "durationSeconds": 180}'
```

---

## Cấu trúc Project

### Backend
```
realtime-poll-server/
├── src/
│   ├── server.js          # Entry point — Express + Socket.IO + tất cả routes
│   ├── database.js        # SQLite (sql.js): initDatabase(), run(), get(), all()
│   ├── pollService.js     # Business logic: createPoll, submitVote, finishPoll
│   ├── socketHandler.js   # Socket.IO: join/leave rooms, broadcast events
│   └── autoVoter.js       # Simulate ~1000 votes trong 2.5 phút để test
├── data/
│   └── polls.db           # SQLite file (tự tạo khi start lần đầu)
├── package.json
└── README.md
```

### iOS App
```
RealtimePoll/
├── AppDelegate.swift                 # Setup UNUserNotificationCenter
├── SceneDelegate.swift               # Root = AuthNavigationController
│
├── PollWidget/                       # iOS Home Screen Widget
│   ├── PollWidget.swift              # WidgetKit + SwiftUI views
│   └── PollWidgetData.swift          # Models + mock data cho widget
│
├── RealtimePoll/
│   ├── Feelit/
│   │   ├── Auth/                     # Flow đăng nhập/đăng ký
│   │   │   ├── AuthWelcomeViewController.swift
│   │   │   ├── AuthFormViewController.swift    # Base class
│   │   │   ├── AuthEmailViewController.swift
│   │   │   ├── AuthPhoneViewController.swift
│   │   │   ├── AuthPasswordViewController.swift
│   │   │   ├── AuthForgotPasswordViewController.swift
│   │   │   ├── AuthResetPasswordViewController.swift
│   │   │   └── AuthNavigationController.swift
│   │   │
│   │   ├── Feed/                     # Tab 1 — Feed
│   │   │   ├── FeedViewController.swift        # FlashCards + Posts
│   │   │   ├── FlashCardCell.swift             # Swipe card cell
│   │   │   ├── PostCard.swift                  # Bài viết cell
│   │   │   ├── CommentViewController.swift     # Bottom sheet comments
│   │   │   └── CommentCell.swift               # 1 dòng comment
│   │   │
│   │   ├── Explore/                  # Tab 2 — Explore
│   │   │   └── ExploreViewController.swift
│   │   │
│   │   ├── Portfolio/                # Tab 3 — Portfolio
│   │   │   └── PortfolioViewController.swift
│   │   │
│   │   ├── Profile/                  # Tab 4 — Profile
│   │   │   └── ProfileViewController.swift
│   │   │
│   │   ├── FeelitTabBarController.swift  # Floating tab bar
│   │   ├── FeelitColors.swift            # Design tokens (colors, fonts, spacing)
│   │   ├── FeelitUI.swift                # Shared components (AvatarView, ChipLabel...)
│   │   └── FeelitMockData.swift          # Mock data (FlashCard, FEPost, FEUser...)
│   │
│   ├── Poll/                         # Poll detail screen
│   │   ├── PollViewController.swift  # Live poll với realtime chart
│   │   └── PollChartView.swift       # CoreGraphics line chart
│   │
│   ├── Main/
│   │   └── MainViewController.swift  # Danh sách polls
│   │
│   ├── Network/
│   │   ├── APIClient.swift           # Singleton, tất cả REST calls
│   │   ├── SocketManager.swift       # Per-instance, poll realtime
│   │   ├── CommentSocketManager.swift # Per-instance, comment realtime
│   │   └── NotificationSocketManager.swift # Singleton, app-level notifications
│   │
│   ├── Repository/
│   │   └── PollRepository.swift      # Abstraction layer cho poll operations
│   │
│   ├── Model/
│   │   └── Poll.swift                # Poll, VoteResponse, PollFinished, ChartPoint,
│   │                                 # Comment, Message, AppNotification, PostDTO...
│   │
│   └── Util/
│       ├── DeviceIdManager.swift     # UUID per install (UserDefaults)
│       ├── LikeStore.swift           # Track liked posts (UserDefaults)
│       ├── NotificationCoordinator.swift # App-level notification hub
│       └── NotificationManager.swift    # UNUserNotificationCenter wrapper
```

---

## API Reference

### Polls

| Method | Route | Body | Mô tả |
|--------|-------|------|-------|
| `GET` | `/` | — | Health check |
| `POST` | `/api/polls` | `{title, durationSeconds}` | Tạo poll mới |
| `GET` | `/api/polls` | — | Danh sách polls (20 gần nhất) |
| `GET` | `/api/polls/active` | — | Poll đang active |
| `GET` | `/api/polls/:id` | — | Poll theo ID |
| `POST` | `/api/polls/:id/votes` | `{voterId, choice}` | Gửi vote YES/NO |
| `GET` | `/api/polls/:id/chart` | — | Dữ liệu biểu đồ |
| `POST` | `/api/polls/:id/simulate` | — | Bật auto vote (~1000 votes) |

### Posts & Comments

| Method | Route | Body | Mô tả |
|--------|-------|------|-------|
| `GET` | `/api/posts` | — | Danh sách posts |
| `POST` | `/api/posts` | `{userId, username, badge, content, tags, pollId?}` | Tạo post |
| `GET` | `/api/posts/:id` | — | Post theo ID |
| `GET` | `/api/posts/:id/comments` | — | Comments của post |
| `POST` | `/api/posts/:id/comments` | `{userId, username, content}` | Gửi comment |
| `POST` | `/api/posts/:id/like` | `{userId}` | Like post |

### Chat

| Method | Route | Body | Mô tả |
|--------|-------|------|-------|
| `GET` | `/api/messages/:userId1/:userId2` | — | Lịch sử chat giữa 2 user |
| `POST` | `/api/messages` | `{senderId, receiverId, content}` | Gửi tin nhắn |

### Notifications

| Method | Route | Body | Mô tả |
|--------|-------|------|-------|
| `GET` | `/api/notifications/:userId` | — | Danh sách thông báo |
| `POST` | `/api/notifications/:id/read` | — | Đánh dấu đã đọc |
| `POST` | `/api/notifications/:userId/read-all` | — | Đánh dấu tất cả đã đọc |
| `POST` | `/api/devices` | `{userId, token, platform}` | Đăng ký device token (APNs) |

### Error Response Format
```json
{
  "error": "DUPLICATE_VOTE",
  "message": "Bạn đã vote rồi, không thể vote lại."
}
```

| Error Code | HTTP | Ý nghĩa |
|------------|------|---------|
| `POLL_NOT_FOUND` | 404 | Poll không tồn tại |
| `NO_ACTIVE_POLL` | 404 | Không có poll active |
| `POLL_NOT_ACTIVE` | 400 | Poll đã kết thúc |
| `POLL_EXPIRED` | 400 | Poll hết giờ |
| `INVALID_CHOICE` | 400 | Choice không hợp lệ |
| `DUPLICATE_VOTE` | 409 | Đã vote rồi |
| `MISSING_FIELDS` | 400 | Thiếu field bắt buộc |

---

## Socket.IO Events

### Client → Server

| Event | Payload | Mô tả |
|-------|---------|-------|
| `join_poll` | `{pollId}` | Vào room poll |
| `leave_poll` | `{pollId}` | Rời room poll |
| `join_feed` | — | Vào room feed (nhận post/like mới) |
| `leave_feed` | — | Rời room feed |
| `join_post` | `{postId}` | Vào room post (nhận comment mới) |
| `leave_post` | `{postId}` | Rời room post |
| `join_chat` | `{userId}` | Vào room cá nhân (nhận notification) |

### Server → Client

| Event | Payload | Mô tả |
|-------|---------|-------|
| `poll_state` | Poll object | Trạng thái poll khi mới join |
| `vote_update` | `{pollId, yesCount, noCount, totalVotes, yesPercentage, noPercentage}` | Vote realtime |
| `poll_finished` | `{pollId, winner, yesCount, noCount, ...}` | Poll kết thúc |
| `new_post` | Post object | Bài viết mới trên feed |
| `new_comment` | `{comment, commentCount}` | Comment mới |
| `post_liked` | `{postId, likes}` | Lượt like cập nhật |
| `new_message` | Message object | Tin nhắn mới (chat) |
| `notification` | AppNotification object | Thông báo in-app |

---

## Cấu hình & Biến môi trường

### Backend
```bash
PORT=3001   # mặc định, đổi nếu cần
```

Chạy với port khác:
```bash
PORT=3002 npm run dev
```

### iOS App

Đổi server URL trong **3 file**:

```swift
// Network/APIClient.swift
private let baseURL = "http://localhost:3001"

// Network/SocketManager.swift
private let serverURL = "ws://localhost:3001/socket.io/?EIO=4&transport=websocket"

// Network/CommentSocketManager.swift
private let serverURL = "ws://localhost:3001/socket.io/?EIO=4&transport=websocket"

// Network/NotificationSocketManager.swift
private let serverURL = "ws://localhost:3001/socket.io/?EIO=4&transport=websocket"
```

### URL theo platform

| Platform | URL |
|----------|-----|
| iOS Simulator | `http://localhost:3001` ✅ |
| Android Emulator | `http://10.0.2.2:3001` |
| iPhone thật | `http://<MAC_LAN_IP>:3001` |

Tìm IP LAN của Mac:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
# inet 192.168.1.x ...
```

---

## Lỗi thường gặp

| Lỗi | Nguyên nhân | Cách fix |
|-----|-------------|---------|
| `Cannot GET /api/polls` | Route không tồn tại | Dùng `/api/polls/active` để lấy poll đang chạy |
| `polls.db` không có trong zip | Đúng — file tự tạo | Chạy `npm start` lần đầu, DB tự tạo trong `data/` |
| `No such module 'Starscream'` | Chưa link vào Target | General → Frameworks → `+` → thêm Starscream |
| `Could not find storyboard 'Main'` | Info.plist còn reference | Xóa `UISceneStoryboardFile` + `UIMainStoryboardFile` trong Info.plist |
| `HTTP 404` khi Join Active Poll | Chưa tạo poll | Chạy `curl -X POST .../api/polls` trước |
| App bị đơ khi vào poll đã ended | SocketManager singleton conflict | Dùng per-instance SocketManager, guard `poll.isActive` trước khi connect |
| `The data couldn't be read because it is missing` | JSON decode fail | Kiểm tra server trả snake_case, decoder không dùng `.convertFromSnakeCase` khi đã có CodingKeys thủ công |
| `connection refused` từ iPhone thật | Dùng `localhost` trên device thật | Đổi sang IP LAN của Mac |
| Notification không nhận trên Simulator | APNs không hoạt động trên Simulator | Dùng local notification fallback (`schedulePollFinished`) |
| Widget không hiện trong Xcode 15+ | Target chưa được thêm | Build scheme phải include PollWidget target |

---

## Architecture

### Tổng quan flow

```
┌─────────────────────────────────────────────────────┐
│                   iOS App (MVC)                     │
│                                                     │
│  ViewController ──→ APIClient ──→ URLSession        │
│       │                                             │
│       └──────→ SocketManager ──→ WebSocket          │
│                 (Starscream)                        │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP REST + WebSocket
                       │ localhost:3001
┌──────────────────────┴──────────────────────────────┐
│                Node.js Server                       │
│                                                     │
│  Express Routes ──→ pollService ──→ database        │
│       │                               (sql.js)      │
│       └──→ Socket.IO ──→ Rooms                      │
│                  └──→ autoVoter                     │
└──────────────────────┬──────────────────────────────┘
                       │
               ┌───────┴───────┐
               │  SQLite DB    │
               │  polls.db     │
               │  (4 tables)   │
               └───────────────┘
```

### Database Schema

```sql
polls        (id, title, status, starts_at, ends_at, yes_count, no_count, winner)
votes        (id, poll_id, voter_id, choice, created_at) UNIQUE(poll_id, voter_id)
chart_points (id, poll_id, yes_count, no_count, recorded_at)
posts        (id, user_id, username, badge, content, tags, likes, comment_count, poll_id)
comments     (id, post_id, user_id, username, content, created_at)
messages     (id, sender_id, receiver_id, content, created_at)
```

### Vote flow (end-to-end)
```
User tap YES
  → PollViewController.voteTapped()
  → PollRepository.submitVote()
  → APIClient.submitVote() [POST /api/polls/:id/votes]
  → server: validate → insert vote → update counter → insert chart_point
  → server: broadcastVoteUpdate() [Socket.IO vote_update]
  → tất cả clients trong room "poll:{id}" nhận vote_update
  → PollViewController.socketDidReceiveVoteUpdate()
  → update UI: progress bar, labels, chart
```

### SocketManager Architecture

| Class | Scope | Dùng cho |
|-------|-------|---------|
| `SocketManager` | Per-instance | Poll realtime (vote, finish) |
| `CommentSocketManager` | Per-instance | Comment + like realtime |
| `NotificationSocketManager` | Singleton | In-app notifications cấp app |

---

## Development Workflow

```
VSCode / Cursor    → viết Swift + JavaScript
Terminal (split)   → tab 1: npm run dev   tab 2: xcrun / curl
Xcode              → chỉ ⌘+R để build & run
claude.ai          → AI assist + gửi ảnh UI (⌘+Shift+4 → ⌘+V)
```

---

## License

MIT License — xem file `LICENSE`
