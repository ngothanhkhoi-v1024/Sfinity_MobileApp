# Sfinity — Backend

API server dùng chung cho **mobile** và **web-admin**.

## Phạm vi

- Auth (JWT / refresh token), RBAC (user, admin, roles)
- CRUD: users, content, categories, media
- Notifications, feedback, reports, analytics cho dashboard

## Stack gợi ý (chọn một)

| Stack | Khởi tạo |
|-------|----------|
| Node.js (NestJS) | `npx @nestjs/cli new .` trong thư mục này |
| Spring Boot | start.spring.io hoặc Spring Initializr |
| Firebase / Supabase | console cloud — phù hợp đồ án nhanh |

## Cấu trúc gợi ý (NestJS)

```
backend/
├── src/
│   ├── main.ts
│   ├── auth/
│   ├── users/
│   ├── content/
│   ├── categories/
│   ├── media/
│   ├── notifications/
│   └── admin/          # endpoints chỉ admin
├── prisma/ hoặc entities/
└── package.json
```

## Biến môi trường

Tạo `.env` (không commit) — tham khảo `.env.example` khi có.

## Chạy dev (ví dụ NestJS)

```bash
npm run start:dev
```

Mobile & web-admin trỏ `BASE_URL` tới server local (ví dụ `http://localhost:3000`).
