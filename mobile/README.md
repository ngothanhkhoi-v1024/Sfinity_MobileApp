# Sfinity Mobile

Flutter app — người dùng cuối (theo yêu cầu đồ án).

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

```bash
cd mobile
flutter pub get
flutter run
```

## Gói gợi ý (thêm sau)

`go_router`, `dio`, `flutter_riverpod`, `shared_preferences`, `image_picker`, `firebase_messaging`
