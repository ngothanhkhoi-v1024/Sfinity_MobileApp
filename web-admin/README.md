# Sfinity — Web Admin

Ứng dụng **web** cho quản trị viên (chạy trên trình duyệt).

## Phạm vi

- Đăng nhập admin, quản lý user / admin / role
- Quản lý nội dung, category, media
- Thông báo, feedback, báo cáo, dashboard thống kê

## Khởi tạo project (gợi ý React + Vite)

```bash
cd web-admin
npm create vite@latest . -- --template react-ts
npm install
npm install antd axios react-router-dom
```

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
