# Sfinity — Backend

API **Express + TypeScript** dùng chung cho **mobile** và **web-admin**. Swagger UI, JWT auth, RBAC, dữ liệu chính trên **Firebase Firestore**.

## Chạy lần đầu

```bash
cd backend
npm install
cp .env.example .env   # Firebase, JWT_SECRET, mail, ...
npm run start:dev
```

- API: `http://localhost:3000/api`
- **Swagger:** `http://localhost:3000/api/docs`
- OpenAPI JSON: `http://localhost:3000/api/openapi.json`

Tùy chọn migrate/seed Prisma (SQLite metadata):

```bash
npx prisma migrate dev --name init
npm run prisma:seed
```

## Tài khoản seed

| Vai trò | Email | Mật khẩu |
|---------|-------|----------|
| Admin | `admin@sfinity.com` | `admin123` |
| User | `user@sfinity.com` | `user123` |

## Modules API

| Prefix | Mô tả |
|--------|--------|
| `/auth` | Login, register, profile, OTP, Google |
| `/document` | Tài liệu CRUD, download logs |
| `/places` | Địa điểm, check-in, review, photos |
| `/study-near-me` | Địa điểm gần tọa độ GPS |
| `/explore` | Featured, weekly stats, top users |
| `/groups` | Nhóm học, thành viên, lời mời, **member locations** |
| `/friends` | Kết bạn |
| `/favorites` | Bookmark |
| `/notifications` | Thông báo |
| `/feedback`, `/reports` | Phản hồi & báo cáo |
| `/admin/dashboard` | Thống kê admin |
| `/users`, `/categories`, `/amenities` | Quản trị |
| `/upload`, `/settings` | Upload file, cài đặt app |

## Nội dung & kiểm duyệt

Mỗi tài liệu/địa điểm có:

- `visibility`: `PRIVATE` | `PUBLIC`
- `moderationStatus`: `NONE` | `PENDING` | `APPROVED` | `REJECTED` | `HIDDEN`

Logic dùng chung: [`src/lib/content-state.ts`](src/lib/content-state.ts).

## Tài liệu

- [Firestore schema](docs/firestore_schema.md)
- [Deploy Cloud Run](docs/google-cloud-run-deploy.md)

## Scripts

| Lệnh | Mô tả |
|------|--------|
| `npm run start:dev` | Dev server (tsx watch) |
| `npm run build` | Compile TypeScript |
| `npm run prisma:seed` | Seed dữ liệu mẫu |
