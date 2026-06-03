# Sau Khi Deploy Backend Va Cach Deploy Lai Khi Doi Code

Cap nhat lan cuoi: `2026-06-03`

Tai lieu nay huong dan cac viec can lam sau khi backend da deploy thanh cong len Google Cloud Run, va quy trinh deploy lai moi khi ban sua code backend.

Backend hien tai da deploy tai:

```text
https://sfinity-backend-947472672630.asia-southeast1.run.app
```

API base URL day du:

```text
https://sfinity-backend-947472672630.asia-southeast1.run.app/api
```

## 1. Cap nhat API_BASE_URL tren Cloud Run backend

Backend dung `API_BASE_URL` de tao cac link tu server, vi du link trong email.

Sau khi deploy thanh cong, chay lenh nay trong Google Cloud SDK Shell:

```cmd
gcloud run services update sfinity-backend --region asia-southeast1 --update-env-vars API_BASE_URL=https://sfinity-backend-947472672630.asia-southeast1.run.app/api
```

Luu y:

- Gia tri phai co `/api` o cuoi.
- Khong can sua `backend/src/config` hay `backend/src/app`.
- Bien nay nam tren Cloud Run, khong phai trong code.

## 2. Kiem tra backend da online

Mo Swagger:

```text
https://sfinity-backend-947472672630.asia-southeast1.run.app/api/docs
```

Kiem tra OpenAPI JSON:

```cmd
curl https://sfinity-backend-947472672630.asia-southeast1.run.app/api/openapi.json
```

Neu thay JSON tra ve, backend da online.

Neu loi, doc logs:

```cmd
gcloud run services logs read sfinity-backend --region asia-southeast1 --limit=50
```

## 3. Thay URL API trong mobile

File mobile dang doc cau hinh tu:

```text
mobile/assets/env/app.env
```

Dat:

```env
API_BASE_URL=https://sfinity-backend-947472672630.asia-southeast1.run.app/api
API_TIMEOUT_SECONDS=30
```

Luu y:

- Mobile can URL co `/api` o cuoi.
- Chi nen bat mot dong `API_BASE_URL`.
- Cac URL local nhu `localhost`, `10.0.2.2`, `127.0.0.1` nen comment lai khi test production.

Sau khi sua `app.env`, chay lai app mobile.

Neu app da build san, can build/chay lai de asset env moi duoc load.

## 4. Thay URL API trong web-admin

Neu dung web-admin, tao hoac sua file:

```text
web-admin/.env
```

Dat:

```env
VITE_API_BASE_URL=https://sfinity-backend-947472672630.asia-southeast1.run.app
```

Luu y:

- Web-admin khong them `/api` vao `VITE_API_BASE_URL`.
- Code web-admin tu noi `/api` trong `web-admin/src/api/client.ts`.
- Neu dat thanh `...run.app/api`, request se bi thanh `.../api/api`.

Sau khi sua `.env`, restart dev server web-admin.

## 5. Khi doi code backend thi lam gi

Moi lan ban sua code trong:

```text
backend/src
backend/package.json
backend/package-lock.json
backend/tsconfig.json
```

hay cac file backend lien quan, lam theo cac buoc sau.

### Buoc 1: Build local truoc

Trong terminal tai may:

```cmd
cd /d D:\Project\Sfinity_MobileApp\backend
npm run build
```

Neu build fail, sua loi truoc khi deploy.

### Buoc 2: Deploy lai Cloud Run

Trong Google Cloud SDK Shell:

```cmd
cd /d D:\Project\Sfinity_MobileApp\backend
gcloud run deploy sfinity-backend --source . --region asia-southeast1
```

Lenh ngan nay duoc dung cho cac lan deploy lai vi Cloud Run service da co san env vars va secrets tu lan deploy truoc.

Neu ban muon chac chan giu public access:

```cmd
gcloud run deploy sfinity-backend --source . --region asia-southeast1 --allow-unauthenticated
```

### Buoc 3: Kiem tra sau deploy lai

```cmd
curl https://sfinity-backend-947472672630.asia-southeast1.run.app/api/openapi.json
```

Doc revision moi:

```cmd
gcloud run services describe sfinity-backend --region asia-southeast1 --format="value(status.latestReadyRevisionName)"
```

Doc logs neu can:

```cmd
gcloud run services logs read sfinity-backend --region asia-southeast1 --limit=50
```

## 6. Khi doi bien moi truong backend

Neu chi doi env var khong nhay cam, vi du:

- `JWT_EXPIRES_IN`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_FROM`
- `API_BASE_URL`

Dung:

```cmd
gcloud run services update sfinity-backend --region asia-southeast1 --update-env-vars KEY=VALUE
```

Vi du:

```cmd
gcloud run services update sfinity-backend --region asia-southeast1 --update-env-vars JWT_EXPIRES_IN=7d
```

Neu muon xem env vars hien co:

```cmd
gcloud run services describe sfinity-backend --region asia-southeast1
```

## 7. Khi doi secret backend

Neu doi cac gia tri nhay cam:

- `JWT_SECRET`
- `FIREBASE_PRIVATE_KEY`
- `SMTP_USER`
- `SMTP_PASS`

Khong dua vao command deploy truc tiep.

Hay vao Google Cloud Console:

```text
Secret Manager
```

Chon secret can sua, them version moi.

Sau do update Cloud Run dung version moi:

```cmd
gcloud run services update sfinity-backend --region asia-southeast1 --update-secrets SMTP_PASS=sfinity-smtp-pass:latest
```

Neu dung version cu the:

```cmd
gcloud run services update sfinity-backend --region asia-southeast1 --update-secrets SMTP_PASS=sfinity-smtp-pass:2
```

## 8. Khi doi Firebase config

Neu doi Firebase project hoac service account:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

Can cap nhat ca env var va secret.

Vi du:

```cmd
gcloud run services update sfinity-backend --region asia-southeast1 --update-env-vars FIREBASE_PROJECT_ID=NEW_PROJECT_ID,FIREBASE_CLIENT_EMAIL=NEW_CLIENT_EMAIL
```

Sau do cap nhat secret:

```cmd
gcloud run services update sfinity-backend --region asia-southeast1 --update-secrets FIREBASE_PRIVATE_KEY=sfinity-firebase-private-key:latest
```

## 9. Khi doi mobile API URL

Sua:

```text
mobile/assets/env/app.env
```

Dung production:

```env
API_BASE_URL=https://sfinity-backend-947472672630.asia-southeast1.run.app/api
```

Dung Android Emulator local:

```env
API_BASE_URL=http://10.0.2.2:3000/api
```

Dung Flutter Web local:

```env
API_BASE_URL=http://localhost:3000/api
```

Moi lan doi file env mobile, hay restart app de dam bao env moi duoc load.

## 10. Khi doi web-admin API URL

Sua:

```text
web-admin/.env
```

Dung production:

```env
VITE_API_BASE_URL=https://sfinity-backend-947472672630.asia-southeast1.run.app
```

Dung local:

```env
VITE_API_BASE_URL=http://localhost:3000
```

Restart web-admin dev server sau khi doi `.env`.

## 11. Checklist deploy lai backend

Dung checklist nay moi lan sua code backend:

```text
[ ] Chay npm run build trong backend
[ ] Neu build pass, chay gcloud run deploy sfinity-backend --source . --region asia-southeast1
[ ] Test /api/openapi.json
[ ] Mo /api/docs
[ ] Test flow quan trong: login, register, document, group, notification
[ ] Neu doi API contract, cap nhat mobile/web-admin neu can
```

## 12. Cac lenh hay dung

Deploy lai:

```cmd
gcloud run deploy sfinity-backend --source . --region asia-southeast1
```

Xem URL service:

```cmd
gcloud run services describe sfinity-backend --region asia-southeast1 --format="value(status.url)"
```

Xem revision moi nhat:

```cmd
gcloud run services describe sfinity-backend --region asia-southeast1 --format="value(status.latestReadyRevisionName)"
```

Xem logs:

```cmd
gcloud run services logs read sfinity-backend --region asia-southeast1 --limit=50
```

Rollback ve revision cu:

```cmd
gcloud run services update-traffic sfinity-backend --region asia-southeast1 --to-revisions REVISION_NAME=100
```

Thay `REVISION_NAME` bang ten revision cu ma ban muon rollback.
