# Sfinity — Web Admin

Trang **quản trị** React + Vite + Ant Design, kết nối cùng backend với mobile.

## Tính năng

- Dashboard thống kê (Recharts)
- Quản lý người dùng & admin
- Nội dung: tài liệu và địa điểm (visibility + moderation)
- Danh mục tài liệu, tiện ích địa điểm
- Phản hồi, báo cáo vi phạm, thông báo
- Cài đặt hệ thống (ngôn ngữ, theme)

Trang **Media** hiện là placeholder.

## Chạy dev

```bash
cd web-admin
npm install
cp .env.example .env
npm run dev
```

Mặc định: `http://localhost:5173`

Trong `.env`:

```env
VITE_API_BASE_URL=http://localhost:3000/api
VITE_USE_MOCK_AUTH=false
```

## Đăng nhập admin

| Email | Mật khẩu |
|-------|----------|
| `admin@sfinity.com` | `admin123` |

Cần backend chạy và tài khoản seed (hoặc mock auth nếu `VITE_USE_MOCK_AUTH=true`).

## Cấu trúc

```text
web-admin/src/
├── api/           # Axios client → backend
├── pages/         # Dashboard, users, content, ...
├── components/    # Layout, table, form
├── contexts/      # Auth, settings
└── routes/        # React Router
```

## Build production

```bash
npm run build
npm run preview
```
