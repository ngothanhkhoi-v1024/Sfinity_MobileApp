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

> Chạy Android emulator thì đổi `apiBaseUrl` trong `app_config.dart` thành `http://10.0.2.2:3000/api`.

## API

Gọi backend tại `backend/` — cấu hình base URL trong `lib/core/config/app_config.dart`.

## Gói gợi ý (thêm sau)

`go_router`, `dio`, `flutter_riverpod`, `shared_preferences`, `image_picker`, `firebase_messaging`
