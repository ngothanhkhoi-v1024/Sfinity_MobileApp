# Sfinity

Nền tảng mobile và quản trị web giúp sinh viên **khám phá địa điểm học tập**, **chia sẻ tài liệu**, và **kết nối cộng đồng học tập** (bạn bè, nhóm học, bản đồ thành viên).

Monorepo gồm ba thành phần:

| Thư mục | Mô tả |
|---------|--------|
| [`mobile/`](mobile/) | Ứng dụng Flutter (Android, iOS, Web) — người dùng cuối |
| [`web-admin/`](web-admin/) | Trang quản trị React + Vite |
| [`backend/`](backend/) | REST API Express + TypeScript dùng chung |

---

## 1. Công nghệ sử dụng

| Thành phần | Công nghệ |
|------------|-----------|
| **Mobile** | Flutter, Dart, go_router, dio, flutter_map, geolocator, Firebase (Auth, Firestore, Storage), Google Sign-In |
| **Web Admin** | React 19, Vite 6, TypeScript, Ant Design 5, Axios, Recharts |
| **Backend** | Node.js, Express 4, TypeScript, class-validator, Swagger UI, JWT, bcrypt, Nodemailer |
| **Cơ sở dữ liệu chính** | **Firebase Firestore** (+ Firebase Auth, Firebase Storage) |
| **Cơ sở dữ liệu phụ** | Prisma + SQLite (`backend/prisma/dev.db`) — metadata/legacy, không phải DB runtime chính |
| **Bản đồ** | OpenStreetMap tiles, OSRM routing |

### Kiến trúc

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

> Chat nhóm và tin nhắn realtime ghi **trực tiếp Firestore** từ mobile; phần lớn nghiệp vụ khác đi qua API Express.

---

## 2. Phiên bản Flutter / Dart

| Công cụ | Phiên bản (đã kiểm tra trên máy dev) |
|---------|--------------------------------------|
| **Flutter** | `3.41.4` (stable) |
| **Dart** | `3.11.1` |
| **Ràng buộc trong project** | `sdk: ^3.11.1` trong [`mobile/pubspec.yaml`](mobile/pubspec.yaml) |

Kiểm tra trên máy của bạn:

```bash
flutter --version
```

---

## 3. Yêu cầu hệ thống

- **Node.js** 18 trở lên và **npm**
- **Flutter SDK** 3.41+ (tương thích Dart 3.11+)
- **Firebase project** — project đồ án dùng `mobile-e1ac5`
- **Git**
- Tùy chọn: Android Studio (Android Emulator), Xcode (iOS Simulator), Chrome (Flutter Web)

---

## 4. Cấu trúc thư mục

```text
Sfinity/
├── mobile/                    # App Flutter
│   ├── android/app/google-services.json   # Firebase Android
│   ├── lib/firebase_options.dart          # Firebase config (FlutterFire)
│   └── assets/env/app.env                 # API base URL cho mobile
├── web-admin/                 # Trang quản trị
│   └── .env.example
├── backend/                   # API server
│   ├── .env.example
│   ├── prisma/migrations/     # Migration SQLite (phụ)
│   ├── prisma/seed-admin.ts   # Seed tài khoản admin lên Firebase
│   └── docs/
│       └── firestore_schema.md
└── README.md
```

Chi tiết từng package: [`mobile/README.md`](mobile/README.md) · [`web-admin/README.md`](web-admin/README.md) · [`backend/README.md`](backend/README.md)

---

## 5. Package / dependency cần cài

### Backend (`backend/`)

```bash
cd backend
npm install
```

Dependency chính: `express`, `firebase-admin`, `@prisma/client`, `jsonwebtoken`, `bcrypt`, `class-validator`, `multer`, `nodemailer`, `swagger-ui-express`.

### Web Admin (`web-admin/`)

```bash
cd web-admin
npm install
```

Dependency chính: `react`, `react-dom`, `react-router-dom`, `antd`, `axios`, `recharts`, `vite`.

### Mobile (`mobile/`)

```bash
cd mobile
flutter pub get
```

Dependency chính: `dio`, `go_router`, `flutter_map`, `geolocator`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `google_sign_in`, `flutter_dotenv`.

---

## 6. Cấu hình Firebase

Dự án dùng Firebase project **`mobile-e1ac5`**.

### 6.1. Mobile — Android

File đã có sẵn trong repo:

- [`mobile/android/app/google-services.json`](mobile/android/app/google-services.json)
- [`mobile/lib/firebase_options.dart`](mobile/lib/firebase_options.dart) — sinh bởi FlutterFire CLI

Package Android: `com.sfinity.sfinity` (xem `mobile/android/app/build.gradle.kts`).

### 6.2. Mobile — iOS

- File `GoogleService-Info.plist` **chưa đưa vào repo**.
- Cấu hình iOS đã có trong [`mobile/lib/firebase_options.dart`](mobile/lib/firebase_options.dart).
- Để build iOS: tải `GoogleService-Info.plist` từ [Firebase Console](https://console.firebase.google.com/) → Project `mobile-e1ac5` → Project settings → Your apps → iOS app → đặt vào `mobile/ios/Runner/GoogleService-Info.plist`.

### 6.3. Backend — Firebase Admin SDK (bắt buộc để chạy local)

1. Mở [Firebase Console](https://console.firebase.google.com/) → project `mobile-e1ac5`
2. **Project settings** → **Service accounts** → **Generate new private key**
3. Sao chép `backend/.env.example` thành `backend/.env`
4. Điền các biến từ file JSON vừa tải:

```env
FIREBASE_PROJECT_ID=mobile-e1ac5
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@mobile-e1ac5.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

> **Lưu ý:** `FIREBASE_PRIVATE_KEY` phải giữ nguyên `\n` trong chuỗi nếu viết trên một dòng. Không commit file `.env` hoặc private key lên GitHub.

### 6.4. Firestore Security Rules

Repo **chưa đính kèm** file `firestore.rules`. Mobile ghi trực tiếp một số collection (chat nhóm, sync user profile) nên Firestore Rules trên Firebase Console cần cho phép người dùng đã đăng nhập đọc/ghi các collection tương ứng.

Khi chạy với project Firebase của nhóm (`mobile-e1ac5`), rules đã được cấu hình sẵn trên Console. Nếu tự tạo Firebase project mới, cần cấu hình rules tương ứng — tham khảo danh sách collection tại mục [8. Dữ liệu mẫu / Firestore](#8-dữ-liệu-mẫu--firestore).

---

## 7. Cấu hình môi trường (.env)

### Backend — `backend/.env`

```bash
cd backend
cp .env.example .env
```

Biến bắt buộc:

| Biến | Mô tả |
|------|--------|
| `FIREBASE_PROJECT_ID` | ID Firebase project |
| `FIREBASE_CLIENT_EMAIL` | Email service account |
| `FIREBASE_PRIVATE_KEY` | Private key service account |
| `JWT_SECRET` | Chuỗi bí mật ký JWT (đổi giá trị mặc định) |

Biến tùy chọn: `SMTP_*` (OTP email — nếu bỏ trống, backend dùng Ethereal Mail test và in preview URL ra terminal).

### Web Admin — `web-admin/.env`

```bash
cd web-admin
cp .env.example .env
```

```env
# Chạy local cùng backend trên máy
VITE_API_BASE_URL=http://localhost:3000/api
VITE_USE_MOCK_AUTH=false
```

### Mobile — `mobile/assets/env/app.env`

Mở file và **bật đúng một dòng** `API_BASE_URL` (bỏ `#` ở đầu dòng), tùy cách chạy:

| Môi trường | `API_BASE_URL` |
|------------|----------------|
| Flutter Web / Chrome | `http://127.0.0.1:3000/api` |
| Android Emulator | `http://10.0.2.2:3000/api` |
| iOS Simulator | `http://127.0.0.1:3000/api` |
| Thiết bị thật (cùng Wi‑Fi/LAN) | `http://<IP-máy-chạy-backend>:3000/api` |

> Nếu không set `API_BASE_URL`, app fallback `http://10.0.2.2:3000/api` (chỉ đúng với Android Emulator).

---

## 8. Dữ liệu mẫu / Firestore

### Cơ sở dữ liệu runtime

Hệ thống lưu dữ liệu chính trên **Firestore**, không phải SQLite. Schema đầy đủ: [`backend/docs/firestore_schema.md`](backend/docs/firestore_schema.md).

### Collections chính

| Collection | Mô tả |
|------------|--------|
| `users` | Hồ sơ người dùng, phân quyền `USER` / `ADMIN` |
| `documents` | Tài liệu PDF và địa điểm (polymorphic: `type: document \| place`) |
| `categories` | Danh mục tài liệu |
| `amenities` | Tiện ích địa điểm (WiFi, ổ cắm, …) |
| `groups`, `group_members` | Nhóm học và thành viên |
| `friendships` | Quan hệ bạn bè |
| `favorites`, `notifications`, `feedbacks`, `reports` | Yêu thích, thông báo, phản hồi, báo cáo |
| `place_reviews`, `place_photos`, `place_checkins` | Đánh giá, ảnh, check-in địa điểm |

Subcollection chat nhóm: `groups/{groupId}/messages` (mobile ghi trực tiếp Firestore).

### Dữ liệu tự seed khi khởi động

Khi backend chạy với Firebase đã cấu hình:

- **`amenities`** — seed 6 tiện ích mặc định (WiFi, Điều hòa, Ổ cắm, …) nếu collection trống
- **`categories`** — seed 4 danh mục (Bài giảng, Đề thi, Ghi chú, Khác) khi gọi API danh mục lần đầu

### Seed tài khoản admin (bắt buộc lần đầu)

```bash
cd backend
npm run seed:admin
```

Tạo/cập nhật tài khoản admin trên **Firebase Auth** và **Firestore** (`users` collection).

### Prisma / SQLite (phụ — không bắt buộc cho runtime)

```bash
cd backend
npx prisma migrate dev
npm run prisma:seed
```

> Script Prisma seed tạo dữ liệu trên SQLite local. API runtime hiện tại đọc/ghi **Firestore** — xem [`backend/docs/prisma-usage-audit.md`](backend/docs/prisma-usage-audit.md).

---

## 9. Các bước cài đặt và chạy project

Chạy theo thứ tự sau:

### Bước 1 — Clone repository

```bash
git clone <url-repo-github>
cd Sfinity
```

### Bước 2 — Cấu hình và chạy Backend

```bash
cd backend
npm install
cp .env.example .env
# Điền FIREBASE_* và JWT_SECRET vào .env (xem mục 6.3, 7)
npm run seed:admin
npm run start:dev
```

Kiểm tra:

- API: [http://localhost:3000/api](http://localhost:3000/api)
- Swagger: [http://localhost:3000/api/docs](http://localhost:3000/api/docs)

### Bước 3 — Chạy Web Admin

Mở terminal mới:

```bash
cd web-admin
npm install
cp .env.example .env
# Đảm bảo VITE_API_BASE_URL=http://localhost:3000/api
npm run dev
```

Truy cập: [http://localhost:5173](http://localhost:5173)

### Bước 4 — Chạy Mobile

Mở terminal mới:

```bash
cd mobile
flutter pub get
# Chỉnh API_BASE_URL trong assets/env/app.env (xem mục 7)
flutter run              # thiết bị mặc định
flutter run -d chrome    # Flutter Web
```

---

## 10. Tài khoản test

| Vai trò | Email | Mật khẩu | Ghi chú |
|---------|-------|----------|---------|
| **Admin** | `admin@sfinity.com` | `admin123` | Tạo bằng `npm run seed:admin` — dùng cho web-admin và mobile |
| **User** | `user@sfinity.com` | `user123` | Đăng ký qua app **hoặc** đã có sẵn trên Firebase project nhóm |

Đăng nhập web-admin: dùng tài khoản **Admin**.

---

## 11. Lưu ý quan trọng

1. **Firebase là bắt buộc** — Backend không hoạt động đầy đủ nếu thiếu `FIREBASE_*` trong `backend/.env`. Hầu hết API đọc/ghi Firestore.

2. **Chạy `seed:admin` trước khi đăng nhập admin** — Tài khoản admin phải tồn tại trên Firebase Auth và Firestore, không chỉ trong SQLite.

3. **Thứ tự khởi động** — Backend trước → Web Admin / Mobile sau.

4. **API URL trên mobile** — Phải khớp môi trường chạy (emulator / thiết bị thật / web). Thiết bị thật cần máy dev và điện thoại **cùng mạng LAN**; dùng `ipconfig` (Windows) hoặc `ifconfig` (Mac/Linux) để lấy IP.

5. **Đăng nhập Google** — Cần cấu hình OAuth trên Firebase Console và SHA-1 fingerprint (Android). Package: `com.sfinity.sfinity`.

6. **Email OTP** — Nếu không cấu hình SMTP, backend in link xem email test (Ethereal) ra terminal khi gửi OTP.

7. **Không commit secrets** — `.env`, private key Firebase, mật khẩu SMTP đã được `.gitignore`.

8. **iOS** — Cần thêm `GoogleService-Info.plist` (mục 6.2) trước khi build trên thiết bị/simulator iOS.

9. **Backend đã deploy (tùy chọn)** — Có thể trỏ mobile/web-admin tới API production thay vì local:
   `https://sfinity-backend-947472672630.asia-southeast1.run.app/api`  
   Khi đó không cần chạy backend local, nhưng vẫn cần Firebase config trên mobile cho Auth/Firestore/Storage.

---

## 12. Tính năng chính

### Mobile

| Module | Mô tả |
|--------|--------|
| Khám phá | Tìm kiếm, nội dung nổi bật, hoạt động tuần, bảng xếp hạng |
| Địa điểm | Bản đồ OSM, check-in, review, Học gần tôi |
| Tài liệu | Xem, tải, CRUD tài liệu/địa điểm |
| Cộng đồng | Bạn bè, nhóm học, chat, bản đồ vị trí thành viên |
| Xác thực | Email/password, Google, OTP, quên mật khẩu |

Hỗ trợ **tiếng Việt / English**.

### Web Admin

Dashboard, quản lý người dùng, nội dung (tài liệu & địa điểm), danh mục, tiện ích, phản hồi, báo cáo, thông báo, cài đặt.

---

## 13. Tài liệu bổ sung

- [Firestore schema](backend/docs/firestore_schema.md) — cấu trúc collection/document
- [Deploy backend lên Google Cloud Run](backend/docs/google-cloud-run-deploy.md)
- [Prisma usage audit](backend/docs/prisma-usage-audit.md) — vai trò SQLite vs Firestore

---

## 14. Giấy phép

Dự án đồ án học thuật — Sfinity © 2026.
