# Sfinity — Web Admin

Ứng dụng **web** cho quản trị viên (chạy trên trình duyệt).

## Phạm vi

- Đăng nhập admin, quản lý user / admin / role
- Quản lý nội dung, category, media
- Thông báo, feedback, báo cáo, dashboard thống kê

## Đã có sẵn

- **Login** (`/login`) — form đăng nhập admin, mock auth khi backend chưa chạy
- **Layout admin** — sidebar, header, menu điều hướng
- **Dashboard** (`/`) — trang tổng quan mẫu

### Tài khoản demo (mock)

| Email | Mật khẩu |
|-------|----------|
| `admin@sfinity.com` | `admin123` |

Copy `.env.example` → `.env` và chỉnh `VITE_USE_MOCK_AUTH=false` khi backend sẵn sàng.

## Cấu trúc gợi ý

```
web-admin/
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── api/            # axios client → backend
│   ├── pages/          # dashboard, users, content, ...
│   ├── components/     # layout, table, form
│   └── routes/
├── public/
└── package.json
```

## API

Dùng **cùng backend** với `mobile/` — token role `admin`.

## Chạy dev

```bash
npm run dev
```

Mở URL hiển thị trong terminal (thường `http://localhost:5173`).
