# Deploy Backend Len Google Cloud Run

Tai lieu nay huong dan deploy `backend/` len **Google Cloud Run** ma **khong can sua source code**.

Phu hop voi repo hien tai vi:

- `backend/package.json` da co script build: `npm run build`
- app production start bang: `node dist/main.js`
- backend dang dung Firebase Admin / Firestore qua cac bien `FIREBASE_*`

## 1. Pham vi va luu y cua repo hien tai

- Backend nay doc cac bien moi truong trong `backend/.env.example`.
- Code hien tai **bat buoc** can:
  - `FIREBASE_PROJECT_ID`
  - `FIREBASE_CLIENT_EMAIL`
  - `FIREBASE_PRIVATE_KEY`
- `JWT_SECRET` nen dat bang secret rieng cho production.
- Neu khong cau hinh `SMTP_*`, backend se roi ve mail test Ethereal. Cach nay khong phu hop production.
- `DATABASE_URL="file:./dev.db"` chi phu hop local/dev. File system cua Cloud Run la tam thoi, khong nen dung SQLite local de luu du lieu production.

## 2. Dieu kien can co

- Da tao Google Cloud Project.
- Da bat Billing cho project.
- Da cai `gcloud CLI`.
- Tai khoan deploy co du quyen. Neu khong phai Project Owner, toi thieu thuong se can them:
  - quyen deploy Cloud Run
  - quyen dung Cloud Build
  - quyen su dung service account runtime
  - quyen truy cap Secret Manager

Tai lieu chinh thuc:

- Cloud Run deploy from source: https://cloud.google.com/run/docs/deploying-source-code
- `gcloud run deploy`: https://cloud.google.com/sdk/gcloud/reference/run/deploy
- Cloud Run env vars: https://cloud.google.com/run/docs/configuring/services/environment-variables
- Cloud Run secrets: https://cloud.google.com/run/docs/configuring/services/secrets
- Cloud Run service identity: https://cloud.google.com/run/docs/configuring/services/service-identity

## 3. Chuan bi gia tri can nhap

### Bien moi truong thuong

- `JWT_EXPIRES_IN=7d`
- `SMTP_HOST=smtp.gmail.com`
- `SMTP_PORT=587`
- `SMTP_SECURE=false`
- `SMTP_FROM=Sfinity <no-reply@yourdomain.com>`
- `FIREBASE_PROJECT_ID=...`
- `FIREBASE_CLIENT_EMAIL=...`

### Secret nen dua vao Secret Manager

- `JWT_SECRET`
- `SMTP_USER`
- `SMTP_PASS`
- `FIREBASE_PRIVATE_KEY`

### Lay gia tri Firebase o dau

Trong Firebase Console:

`Project settings` -> `Service accounts` -> `Generate new private key`

Tu file JSON vua tai ve, ban can:

- `project_id` -> `FIREBASE_PROJECT_ID`
- `client_email` -> `FIREBASE_CLIENT_EMAIL`
- `private_key` -> `FIREBASE_PRIVATE_KEY`

Voi `FIREBASE_PRIVATE_KEY`, hay luu **dung nguyen van** gia tri private key, bao gom:

- `-----BEGIN PRIVATE KEY-----`
- cac dong noi dung o giua
- `-----END PRIVATE KEY-----`

## 4. Di vao dung thu muc backend

Chay lenh tu thu muc `backend`:

```powershell
cd d:\Project\Sfinity_MobileApp\backend
```

## 5. Dang nhap va cau hinh project

```powershell
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

Khai bao bien tam cho de dung:

```powershell
$PROJECT_ID="YOUR_PROJECT_ID"
$REGION="asia-southeast1"
$SERVICE="sfinity-backend"
$SERVICE_ACCOUNT="$SERVICE@$PROJECT_ID.iam.gserviceaccount.com"
```

## 6. Bat cac API can thiet

```powershell
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com iam.googleapis.com
```

## 7. Tao service account cho Cloud Run

Runtime service account nay chu yeu dung de doc secret trong Secret Manager.

```powershell
gcloud iam service-accounts create $SERVICE --display-name "Sfinity Backend"
```

Cap quyen doc secret:

```powershell
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT" --role="roles/secretmanager.secretAccessor"
```

Neu lenh deploy sau do bao loi `iam.serviceAccounts.actAs`, hay nho admin cap them `roles/iam.serviceAccountUser` cho tai khoan dang deploy tren service account nay.

## 8. Tao secrets trong Secret Manager

Cach de nhat la tao bang giao dien web:

1. Mo `Secret Manager` trong Google Cloud Console
2. Tao cac secret sau:
   - `sfinity-jwt-secret`
   - `sfinity-smtp-user`
   - `sfinity-smtp-pass`
   - `sfinity-firebase-private-key`
3. Dan gia tri that vao tung secret

Neu ban khong dung SMTP that, co the bo qua `sfinity-smtp-user` va `sfinity-smtp-pass`, nhung production khong nen lam vay.

## 9. Deploy len Cloud Run tu source code

Cloud Run co the deploy truc tiep tu source code trong thu muc hien tai. Vi backend da co `package.json`, `build`, va `start`, Cloud Run se dung co che build tu source cua no de build service.

Lenh deploy lan dau:

```powershell
gcloud run deploy $SERVICE `
  --source . `
  --region $REGION `
  --allow-unauthenticated `
  --service-account $SERVICE_ACCOUNT `
  --set-env-vars JWT_EXPIRES_IN=7d `
  --set-env-vars SMTP_HOST=smtp.gmail.com `
  --set-env-vars SMTP_PORT=587 `
  --set-env-vars SMTP_SECURE=false `
  --set-env-vars SMTP_FROM="Sfinity <no-reply@yourdomain.com>" `
  --set-env-vars FIREBASE_PROJECT_ID="YOUR_FIREBASE_PROJECT_ID" `
  --set-env-vars FIREBASE_CLIENT_EMAIL="YOUR_FIREBASE_CLIENT_EMAIL" `
  --set-secrets JWT_SECRET=sfinity-jwt-secret:latest,SMTP_USER=sfinity-smtp-user:latest,SMTP_PASS=sfinity-smtp-pass:latest,FIREBASE_PRIVATE_KEY=sfinity-firebase-private-key:latest
```

Ghi chu:

- `--allow-unauthenticated` la de mobile app / web-admin goi API cong khai.
- Neu chua co SMTP that, co the bo `SMTP_USER` va `SMTP_PASS` khoi `--set-secrets`.
- Neu CLI cua ban bao loi vi chua ton tai secret nao do, tao secret do truoc roi deploy lai.

## 10. Lay URL service va cap nhat API_BASE_URL

Sau khi deploy xong, lay URL mac dinh cua Cloud Run:

```powershell
gcloud run services describe $SERVICE --region $REGION --format="value(status.url)"
```

Vi code dang tao link email dua tren `API_BASE_URL`, ban nen cap nhat bien nay sau deploy:

```powershell
gcloud run services update $SERVICE `
  --region $REGION `
  --update-env-vars API_BASE_URL="https://YOUR_CLOUD_RUN_URL/api"
```

Vi du:

```text
https://sfinity-backend-xxxxx-uc.a.run.app/api
```

Neu ban dung custom domain cho API, hay dat `API_BASE_URL` bang domain do thay vi URL mac dinh cua Cloud Run.

## 11. Kiem tra sau khi deploy

Thu cac dia chi sau:

- `https://YOUR_CLOUD_RUN_URL/api`
- `https://YOUR_CLOUD_RUN_URL/api/docs`
- `https://YOUR_CLOUD_RUN_URL/api/openapi.json`

Neu can test nhanh:

```powershell
curl https://YOUR_CLOUD_RUN_URL/api/openapi.json
```

## 12. Cap nhat khi thay doi code

Moi lan can deploy lai:

```powershell
cd d:\Project\Sfinity_MobileApp\backend
gcloud run deploy $SERVICE --source . --region $REGION
```

Neu chi doi env vars:

```powershell
gcloud run services update $SERVICE --region $REGION --update-env-vars KEY=VALUE
```

Neu chi doi secrets:

```powershell
gcloud run services update $SERVICE --region $REGION --update-secrets KEY=SECRET_NAME:latest
```

## 13. Loi thuong gap

### App boot len nhung API loi lien quan Firebase

Kiem tra lai:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

Neu `FIREBASE_PRIVATE_KEY` bi mat xuong dong hoac copy sai, Firebase Admin SDK se khoi tao that bai.

### Gui mail khong duoc

Kiem tra lai:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`

Voi Gmail, nen dung **App Password**, khong dung mat khau dang nhap thong thuong.

### Build thanh cong nhung du lieu mat sau khi restart

Neu du lieu dang nam trong SQLite local file thi day la hanh vi binh thuong tren Cloud Run. Can dua du lieu can ben vao Firestore, Cloud SQL, hoac mot database production khac.

## 14. Luu y rieng cho backend nay

- Repo hien tai tao link verify email dua tren `API_BASE_URL`.
- Tuy nhien route `/auth/verify-email` chua xuat hien trong `backend/src/routes/auth.routes.ts`.
- Neu ban dinh bat luong verify email production, nen kiem tra va hoan thien feature nay truoc.

## 15. Tai lieu tham khao

- Cloud Run deploy from source:
  https://cloud.google.com/run/docs/deploying-source-code
- `gcloud run deploy` reference:
  https://cloud.google.com/sdk/gcloud/reference/run/deploy
- Environment variables:
  https://cloud.google.com/run/docs/configuring/services/environment-variables
- Secrets:
  https://cloud.google.com/run/docs/configuring/services/secrets
- Service identity:
  https://cloud.google.com/run/docs/configuring/services/service-identity
