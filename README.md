# Sfinity

Monorepo cho đồ án: ứng dụng mobile (end-user) + web admin + backend API.

## Cấu trúc

```
Sfinity/
├── mobile/       # Flutter — app Android & iOS (người dùng cuối)
├── web-admin/    # Web — trang quản trị (admin)
└── backend/      # API server — dùng chung cho mobile & web-admin
```

## Thứ tự triển khai gợi ý

1. **backend** — auth, user, content API (tối thiểu)
2. **mobile** — giao diện & chức năng end-user
3. **web-admin** — quản trị sau khi API đã ổn

## Yêu cầu đồ án

- Mobile: Flutter (UI + chức năng end-user)
- Web: Admin dashboard (React/Vue/… tùy nhóm)
- Backend: REST/GraphQL + phân quyền RBAC

Chi tiết từng thư mục xem README trong `mobile/`, `web-admin/`, `backend/`.
