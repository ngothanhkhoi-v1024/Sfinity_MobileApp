# Prisma Usage Audit

Cap nhat lan cuoi: `2026-06-03`

Tai lieu nay ghi lai ket qua kiem tra xem backend hien tai con dung Prisma o dau.

## Ket luan nhanh

Backend runtime hien tai **khong dung Prisma cho cac API dang chay**.

Du lieu runtime dang duoc doc/ghi chu yeu qua **Firebase Admin SDK / Google Cloud Firestore**, thong qua helper `getDb()` trong:

```text
backend/src/lib/firebase.ts
```

Prisma hien tai chi con xuat hien nhu phan legacy / cong cu dev:

- schema SQLite
- script migrate/generate trong `package.json`
- seed cu ghi vao SQLite
- wrapper `src/lib/prisma.ts` chua thay route/service nao import

## Noi Prisma con xuat hien

### 1. Dependency va script

File:

```text
backend/package.json
```

Con cac script:

```json
"prisma:generate": "prisma generate",
"prisma:migrate": "prisma migrate dev",
"prisma:seed": "tsx prisma/seed.ts",
"db:setup": "prisma migrate dev --name init && npm run prisma:seed"
```

Con dependency:

```json
"@prisma/client": "^6.4.0"
```

Con devDependency:

```json
"prisma": "^6.4.0"
```

### 2. Prisma schema

File:

```text
backend/prisma/schema.prisma
```

Schema dang cau hinh SQLite:

```prisma
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}
```

### 3. Seed cu dung Prisma

File:

```text
backend/prisma/seed.ts
```

File nay import Prisma:

```ts
import { PrismaClient, ContentStatus, UserRole } from '@prisma/client';
```

Va ghi vao cac model:

```text
user
category
content
```

Day la seed SQLite cu, khong phai seed Firestore runtime hien tai.

### 4. Prisma client wrapper

File:

```text
backend/src/lib/prisma.ts
```

Noi dung:

```ts
import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();
```

Ket qua kiem tra cho thay file nay **khong duoc import boi route/service runtime**.

## Noi runtime dang dung Firestore

Runtime backend dang dung `getDb()` rat nhieu trong:

```text
backend/src/services
backend/src/middleware
backend/prisma/seed-admin.ts
```

Mot so vi du:

- `auth.service.ts`
- `users.service.ts`
- `document.service.ts`
- `categories.service.ts`
- `dashboard.service.ts`
- `group.service.ts`
- `notifications.service.ts`
- `reports.service.ts`
- `feedback.service.ts`
- `favorites.service.ts`
- `jwt.middleware.ts`

Seed admin hien tai cung dung Firebase/Firestore:

```text
backend/prisma/seed-admin.ts
```

File nay goi:

```ts
getFirebaseAuth()
getDb().collection('users')
```

## Anh huong khi deploy Google Cloud Run

Voi trang thai hien tai:

- Khong can chay `prisma migrate` khi deploy Cloud Run neu backend production dung Firestore.
- Khong can dua `DATABASE_URL` len Cloud Run neu khong co code runtime nao dung Prisma.
- Khong nen dung SQLite local file tren Cloud Run de luu du lieu production.
- Can cau hinh day du `FIREBASE_*`, `JWT_*`, va `SMTP_*`.

## Tai lieu dang bi lech

File:

```text
backend/README.md
```

Dang mo ta backend la:

```text
Express + Swagger UI + Prisma (SQLite)
```

Mo ta nay khong con phan anh dung runtime hien tai, vi cac API dang dung Firestore.

Nen cap nhat README thanh:

```text
Express + Swagger UI + Firebase Admin / Firestore
```

Va neu van muon giu Prisma de tham chieu legacy, nen ghi ro:

```text
Prisma/SQLite hien chi con dung cho schema hoac seed cu, khong phai database runtime production.
```

## Khuyen nghi

### Neu tiep tuc dung Firestore

Co the xem Prisma la legacy. Nen:

- cap nhat `backend/README.md`
- cap nhat tai lieu deploy Cloud Run neu con nhac `DATABASE_URL`
- khong chay `npm run db:setup` tren production
- chi chay `npm run seed:admin` neu can tao admin tren Firebase/Firestore

### Neu muon don Prisma khoi backend

Can lam theo tung buoc nho:

1. Xac nhan chac chan khong route/service nao can SQLite.
2. Xoa `backend/src/lib/prisma.ts`.
3. Xoa `backend/prisma/seed.ts` neu khong can seed SQLite nua.
4. Xoa scripts Prisma khoi `backend/package.json`.
5. Xoa dependency `@prisma/client` va devDependency `prisma`.
6. Xoa hoac archive `backend/prisma/schema.prisma` va migrations.
7. Chay lai install/build/test.

Khong nen xoa ngay neu team van can schema/migration cu de tham khao.

## Lenh da dung de kiem tra

```powershell
rg -n "PrismaClient|@prisma/client|prisma\.|prisma:|db:setup|DATABASE_URL" backend
```

```powershell
rg -n "getDb\(|firebase-admin|collection\(" backend/src backend/prisma
```
