# Sfinity — Mobile

App **Flutter** cho người dùng cuối (Android & iOS).

## Phạm vi

- Authentication, profile, onboarding
- Danh sách / chi tiết nội dung, tìm kiếm, CRUD, bookmark
- Thông báo, cài đặt, feedback, media, chia sẻ, lịch sử

## Cấu trúc `lib/`

| Thư mục | Nội dung (PDF) |
|---------|----------------|
| `core/` | Config, theme, routes, API client |
| `features/auth/` | Login, Register, Forgot password, OTP |
| `features/onboarding/` | Welcome, giới thiệu, xin quyền |
| `features/home/` | Shell: BottomNav, Drawer, FAB |
| `features/content/` | List, detail, CRUD form |
| `features/search/` | Tìm kiếm, filter, sort |
| `features/profile/` | Profile, edit, avatar |
| `features/favorites/` | Bookmark |
| `features/history/` | Lịch sử, đã xem |
| `features/notifications/` | In-app, cài đặt |
| `features/settings/` | App, ngôn ngữ, theme |
| `features/feedback/` | Feedback, rate app |
| `features/security/` | Đổi MK, 2FA, session |
| `features/media/` | Upload / xem ảnh |
| `shared/` | Widget dùng chung |

Các file `*_page.dart` hiện là **placeholder** — bổ sung logic sau.

## Chạy

**Chrome (web):**
```bash
cd mobile
flutter pub get
flutter run -d chrome
```

**Android / iOS:**
```bash
flutter run
```

> Base URL backend: chỉnh trong `assets/env/app.env` — file có chú thích từng kiểu run (Chrome, Android emulator, iOS simulator, máy thật / LAN).

## API

Gọi backend tại `backend/`. Base URL và timeout đọc từ `assets/env/app.env` (được load trong `main.dart` qua `flutter_dotenv`). Đọc [AppConfig](lib/core/config/app_config.dart) trong code.

## Gói gợi ý (thêm sau)

`go_router`, `dio`, `flutter_riverpod`, `shared_preferences`, `image_picker`, `firebase_messaging`
