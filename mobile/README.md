# Sfinity — Mobile

Ứng dụng **Flutter** cho người dùng cuối (Android, iOS, Web).

## Tính năng

- **Khám phá** — tìm kiếm, nội dung nổi bật, hoạt động tuần, bảng xếp hạng người dùng
- **Địa điểm** — bản đồ OSM, check-in, review, Học gần tôi, địa điểm của tôi
- **Tài liệu** — xem, tải, tạo/sửa, quản lý tài liệu cá nhân
- **Cộng đồng** — bạn bè, nhóm học (chat, lưu trữ, thành viên, **bản đồ vị trí thành viên**)
- **Cá nhân** — hồ sơ, yêu thích, thông báo, phản hồi, cài đặt
- **Auth** — email/password, Google, OTP, quên mật khẩu

## Cấu trúc `lib/`

| Thư mục | Nội dung |
|---------|----------|
| `core/` | Config, theme, routes, API client, i18n |
| `features/auth/` | Đăng nhập, đăng ký, OTP |
| `features/home/` | Shell 5 tab, Khám phá, Cộng đồng |
| `features/places/` | Bản đồ, chi tiết, CRUD địa điểm |
| `features/document/` | Tài liệu CRUD & chi tiết |
| `features/groups/` | Nhóm học, chat, bản đồ thành viên |
| `features/friendships/` | Bạn bè, lời mời |
| `features/study_near_me/` | Gợi ý địa điểm gần bạn |
| `features/profile/` | Hồ sơ, chỉnh sửa |
| `features/favorites/` | Bookmark |
| `features/notifications/` | Thông báo |
| `features/settings/` | Ngôn ngữ, theme |
| `features/feedback/`, `report/` | Phản hồi, báo cáo |
| `shared/` | Widget dùng chung |

Một số màn hình phụ vẫn placeholder: lịch sử, 2FA, quản lý phiên, rate app.

## Chạy

```bash
cd mobile
flutter pub get
flutter run              # thiết bị mặc định
flutter run -d chrome    # web
```

### Cấu hình API

Base URL đọc từ `assets/env/` (qua `flutter_dotenv` trong `main.dart`).

| Môi trường | Gợi ý `API_BASE_URL` |
|------------|----------------------|
| Web | `http://127.0.0.1:3000/api` |
| Android Emulator | `http://10.0.2.2:3000/api` |
| Thiết bị thật | `http://<IP-LAN>:3000/api` |

Xem [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart).

## Phụ thuộc chính

`go_router`, `dio`, `flutter_map`, `geolocator`, `firebase_core`, `cloud_firestore`, `google_sign_in`, `flutter_dotenv`

## API

Gọi backend tại [`../backend/`](../backend/). Cần backend chạy trước khi test đầy đủ tính năng.
