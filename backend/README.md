# Sfinity — Backend

API **Express** + **Swagger UI** + **Prisma** (SQLite), dùng chung cho **mobile** và **web-admin**. Hợp đồng endpoint giữ nguyên so với phiên bản NestJS trước đó.

## Chạy lần đầu

```bash
cd backend
npm install
npx prisma migrate dev --name init
npm run prisma:seed
npm run start:dev
```

- API: `http://localhost:3000/api`
- **Swagger (thử API):** `http://localhost:3000/api/docs`
- OpenAPI JSON: `http://localhost:3000/api/openapi.json`

## Tài khoản seed

| Vai trò | Email | Mật khẩu |
|---------|-------|----------|
| Admin | admin@sfinity.com | admin123 |
| User | user@sfinity.com | user123 |

## Endpoints chính

| Method | Path | Mô tả |
|--------|------|--------|
| POST | `/api/auth/login` | Đăng nhập user |
| POST | `/api/auth/admin/login` | Đăng nhập admin |
| POST | `/api/auth/register` | Đăng ký |
| GET | `/api/auth/me` | Profile (JWT) |
| GET | `/api/document` | Danh sách tài liệu |
| CRUD | `/api/users` | Admin only |
| CRUD | `/api/categories` | Admin write |
| GET | `/api/admin/dashboard/stats` | Thống kê admin |
| GET/POST | `/api/favorites` | Yêu thích |
| POST | `/api/feedback` | Gửi phản hồi |
