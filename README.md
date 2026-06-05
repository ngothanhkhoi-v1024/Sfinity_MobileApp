# Sfinity

Nền tảng mobile và quản trị web giúp sinh viên **khám phá địa điểm học tập**, **chia sẻ tài liệu**, và **kết nối cộng đồng học tập** (bạn bè, nhóm học, bản đồ thành viên).

Monorepo gồm ba thành phần: ứng dụng Flutter (người dùng cuối), web admin (quản trị viên), và backend REST API dùng chung.

---

## Tính năng chính

### Mobile (Flutter)

| Module | Mô tả |
|--------|--------|
| **Khám phá** | Tìm kiếm tài liệu/địa điểm, nội dung nổi bật, biểu đồ hoạt động tuần, bảng xếp hạng người dùng xuất sắc |
| **Địa điểm** | Bản đồ OSM, cluster marker, lọc cộng đồng/cá nhân, check-in, đánh giá, chỉ đường, Học gần tôi |
| **Tài liệu** | Danh sách, chi tiết, tải xuống, CRUD, quản lý tài liệu/địa điểm của tôi |
| **Cộng đồng** | Bạn bè, nhóm học tập, lời mời, tab trò chuyện & lưu trữ file |
| **Bản đồ nhóm** | Chia sẻ vị trí thành viên realtime; marker avatar trên bản đồ khi mở tab Map |
| **Cá nhân** | Hồ sơ, yêu thích, thông báo, phản hồi, báo cáo, cài đặt (ngôn ngữ, theme) |
| **Xác thực** | Đăng ký/đăng nhập, OTP, quên mật khẩu, đăng nhập Google, đổi mật khẩu |

Hỗ trợ **tiếng Việt / English** (i18n).

### Web Admin (React + Vite + Ant Design)

Dashboard thống kê, quản lý người dùng & admin, nội dung (tài liệu & địa điểm), danh mục, tiện ích, phản hồi, báo cáo, thông báo, cài đặt hệ thống.

### Backend (Express + TypeScript)

REST API với JWT, phân quyền **RBAC** (`user` / `admin`), Swagger UI, lưu trữ chính trên **Firebase Firestore**, email OTP qua Nodemailer, upload file.

Quản lý nội dung theo hai trục: **visibility** (private/public) và **moderationStatus** (duyệt/ẩn/từ chối).

---

## Kiến trúc

```text
┌─────────────┐     ┌─────────────┐
│   mobile/   │     │ web-admin/  │
│   Flutter   │     │ React+Vite  │
└──────┬──────┘     └──────┬──────┘
       │    JWT / REST     │
       └─────────┬─────────┘
                 ▼
         ┌───────────────┐
         │   backend/    │
         │ Express + TS  │
         └───────┬───────┘
                 ▼
         ┌───────────────┐
         │   Firestore   │  (+ Firebase Auth, Storage)
         └───────────────┘
```

Chat nhóm và tin nhắn realtime ghi trực tiếp Firestore từ mobile; phần lớn nghiệp vụ khác đi qua API Express.

---

## Cấu trúc thư mục

```text
Sfinity/
├── mobile/          # App Flutter — Android, iOS, Web
├── web-admin/       # Trang quản trị React
├── backend/         # API server Express
│   └── docs/        # Firestore schema, hướng dẫn deploy Cloud Run
└── README.md
```

Chi tiết từng package: [`mobile/README.md`](mobile/README.md) · [`web-admin/README.md`](web-admin/README.md) · [`backend/README.md`](backend/README.md)

---

## Tech stack

| Thành phần | Công nghệ |
|------------|-----------|
| Mobile | Flutter 3, go_router, dio, flutter_map, geolocator, Firebase |
| Web Admin | React 19, Vite, Ant Design, Recharts, Axios |
| Backend | Node.js, Express, TypeScript, class-validator, Swagger |
| Dữ liệu | Firebase Firestore, Firebase Auth; Prisma (SQLite) cho một số metadata |
| Bản đồ | OpenStreetMap tiles, OSRM routing |

---

## Yêu cầu hệ thống

- **Node.js** 18+ và npm
- **Flutter** 3.11+ (SDK trong `mobile/pubspec.yaml`)
- **Firebase project** đã cấu hình (service account cho backend, config cho mobile)
- Tùy chọn: Android Studio / Xcode / Chrome để chạy mobile

---

## Chạy dự án

### 1. Backend

```bash
cd backend
npm install
cp .env.example .env   # điền Firebase, JWT, mail, ...
npm run start:dev
```

- API: `http://localhost:3000/api`
- Swagger: `http://localhost:3000/api/docs`

Lần đầu có thể chạy migrate/seed theo [`backend/README.md`](backend/README.md).

### 2. Web Admin

```bash
cd web-admin
npm install
cp .env.example .env   # VITE_API_BASE_URL=http://localhost:3000/api
npm run dev
```

Mặc định: `http://localhost:5173`

### 3. Mobile

```bash
cd mobile
flutter pub get
```

Cấu hình API trong `mobile/assets/env/` (xem comment trong file env). Ví dụ cho máy thật / emulator:

| Môi trường | `API_BASE_URL` gợi ý |
|------------|----------------------|
| Web / desktop | `http://127.0.0.1:3000/api` |
| Android Emulator | `http://10.0.2.2:3000/api` |
| iOS Simulator | `http://localhost:3000/api` |
| Thiết bị thật (LAN) | `http://<IP-máy-dev>:3000/api` |

```bash
flutter run              # thiết bị mặc định
flutter run -d chrome    # web
```

---

## Tài khoản demo

| Vai trò | Email | Mật khẩu |
|---------|-------|----------|
| Admin | `admin@sfinity.com` | `admin123` |
| User | `user@sfinity.com` | `user123` |

---

## API modules (tóm tắt)

| Prefix | Mô tả |
|--------|--------|
| `/auth` | Đăng ký, đăng nhập, profile, OTP |
| `/document` | Tài liệu CRUD, tải xuống, duyệt |
| `/places` | Địa điểm, check-in, review, ảnh |
| `/study-near-me` | Gợi ý địa điểm gần vị trí hiện tại |
| `/explore` | Nổi bật, thống kê tuần, top contributors |
| `/groups` | Nhóm học, thành viên, lời mời, **vị trí thành viên** |
| `/friends` | Kết bạn, lời mời |
| `/favorites` | Yêu thích / bookmark |
| `/notifications` | Thông báo in-app |
| `/feedback`, `/reports` | Phản hồi & báo cáo vi phạm |
| `/admin/dashboard` | Thống kê admin |
| `/users`, `/categories`, `/amenities`, `/upload`, `/settings` | Quản trị & hỗ trợ |

Danh sách đầy đủ: Swagger tại `/api/docs` hoặc [`backend/docs/firestore_schema.md`](backend/docs/firestore_schema.md).

---

## Trạng thái triển khai

**Đã hoàn thiện:** auth, bản đồ địa điểm, tài liệu, nhóm (chat + map thành viên), bạn bè, khám phá, admin dashboard, moderation nội dung.

**Đang placeholder / chưa làm đủ:** lịch sử hoạt động, 2FA, quản lý phiên đăng nhập, đánh giá app, trang Media trên web-admin.

---

## Tài liệu bổ sung

- [Firestore schema](backend/docs/firestore_schema.md)
- [Deploy backend lên Google Cloud Run](backend/docs/google-cloud-run-deploy.md)
- [Prisma usage audit](backend/docs/prisma-usage-audit.md)

---

## Giấy phép

Dự án đồ án học thuật — Sfinity © 2026.
