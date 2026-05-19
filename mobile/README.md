# Sfinity — Mobile

App **Flutter** cho người dùng cuối (Android & iOS).

## Phạm vi

- Authentication, profile, onboarding
- Danh sách / chi tiết nội dung, tìm kiếm, CRUD, bookmark
- Thông báo, cài đặt, feedback, media, chia sẻ, lịch sử

## Khởi tạo project (khi bắt đầu code)

```bash
cd mobile
flutter create . --org com.sfinity --project-name sfinity
```

## Cấu trúc gợi ý (sau khi `flutter create`)

```
mobile/
├── lib/
│   ├── main.dart
│   ├── core/           # router, theme, network, errors
│   ├── features/       # auth, home, profile, ...
│   └── shared/         # widgets dùng chung
├── android/
├── ios/
└── pubspec.yaml
```

## API

Gọi backend tại `backend/` — cấu hình base URL trong `lib/core/config/`.
