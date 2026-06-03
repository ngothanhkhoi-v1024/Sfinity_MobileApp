# Deploy Bang Google Cloud SDK Shell CMD

Cap nhat lan cuoi: `2026-06-03`

Tai lieu nay danh cho truong hop ban dang mo **Google Cloud SDK Shell** va terminal hien ra dang:

```cmd
C:\Users\PLAK\AppData\Local\Google\Cloud SDK>
```

Day la moi truong `cmd`, khong phai PowerShell.

## 1. Loi vua gap la gi

Neu ban chay rieng:

```cmd
--set-env-vars ...
```

hoac:

```cmd
--set-secrets ...
```

thi se bi loi:

```text
'--set-env-vars' is not recognized as an internal or external command
```

Ly do:

- `--set-env-vars` khong phai lenh rieng.
- `--set-secrets` khong phai lenh rieng.
- Chung la tham so cua lenh `gcloud run deploy`.
- Trong `cmd`, khong dung dau backtick `` ` `` de xuong dong nhu PowerShell.

Vay trong Google Cloud SDK Shell, cach de nhat la chay **mot dong day du**.

## 2. Vao dung thu muc backend

Chay:

```cmd
cd /d D:\Project\Sfinity_MobileApp\backend
```

Kiem tra dung thu muc:

```cmd
dir package.json
```

Neu thay `package.json`, ban dang o dung thu muc backend.

## 3. Kiem tra gcloud

```cmd
gcloud --version
```

Neu hien version, tiep tuc.

Dang nhap:

```cmd
gcloud auth login
```

Set project:

```cmd
gcloud config set project YOUR_GCP_PROJECT_ID
```

Thay `YOUR_GCP_PROJECT_ID` bang Google Cloud Project ID cua ban.

## 4. Bat cac API can thiet

```cmd
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com iam.googleapis.com
```

## 5. Tao secrets truoc khi deploy

Truoc khi chay deploy co `--set-secrets`, ban phai tao cac secret nay trong Google Cloud Secret Manager:

```text
sfinity-jwt-secret
sfinity-firebase-private-key
sfinity-smtp-user
sfinity-smtp-pass
```

Map gia tri tu `backend/.env`:

```text
JWT_SECRET           -> sfinity-jwt-secret
FIREBASE_PRIVATE_KEY -> sfinity-firebase-private-key
SMTP_USER            -> sfinity-smtp-user
SMTP_PASS            -> sfinity-smtp-pass
```

Luu y an toan:

- Khong dua nguyen file `.env` len Cloud Run.
- Khong paste secret vao terminal neu khong can.
- Gia tri `SMTP_PASS` da tung bi lo trong chat/terminal nen nen tao Gmail App Password moi va thay vao secret `sfinity-smtp-pass`.

## 6. Lenh deploy dung cho CMD

Chay mot dong duy nhat:

```cmd
gcloud run deploy sfinity-backend --source . --region asia-southeast1 --allow-unauthenticated --set-env-vars JWT_EXPIRES_IN=7d,FIREBASE_PROJECT_ID=mobile-e1ac5,FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@mobile-e1ac5.iam.gserviceaccount.com,SMTP_HOST=smtp.gmail.com,SMTP_PORT=587,SMTP_SECURE=false,SMTP_FROM="Sfinity <no-reply@sfinity.com>" --set-secrets JWT_SECRET=sfinity-jwt-secret:latest,FIREBASE_PRIVATE_KEY=sfinity-firebase-private-key:latest,SMTP_USER=sfinity-smtp-user:latest,SMTP_PASS=sfinity-smtp-pass:latest
```

Khong tach rieng cac phan sau:

```cmd
--set-env-vars ...
--set-secrets ...
```

Hai phan nay phai nam chung trong lenh `gcloud run deploy`.

## 7. Neu muon tach thanh nhieu dong trong CMD

Trong `cmd`, ky tu xuong dong la dau caret `^`, khong phai backtick.

Co the chay nhu sau:

```cmd
gcloud run deploy sfinity-backend ^
  --source . ^
  --region asia-southeast1 ^
  --allow-unauthenticated ^
  --set-env-vars JWT_EXPIRES_IN=7d,FIREBASE_PROJECT_ID=mobile-e1ac5,FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@mobile-e1ac5.iam.gserviceaccount.com,SMTP_HOST=smtp.gmail.com,SMTP_PORT=587,SMTP_SECURE=false,SMTP_FROM="Sfinity <no-reply@sfinity.com>" ^
  --set-secrets JWT_SECRET=sfinity-jwt-secret:latest,FIREBASE_PRIVATE_KEY=sfinity-firebase-private-key:latest,SMTP_USER=sfinity-smtp-user:latest,SMTP_PASS=sfinity-smtp-pass:latest
```

Luu y:

- Dau `^` phai nam cuoi dong.
- Sau dau `^` khong nen co ky tu thua.
- Neu khong chac, hay dung lenh mot dong o muc 6.

## 8. Cap nhat API_BASE_URL sau khi deploy

Sau khi deploy thanh cong, lay URL:

```cmd
gcloud run services describe sfinity-backend --region asia-southeast1 --format="value(status.url)"
```

Gia su URL tra ve la:

```text
https://sfinity-backend-xxxxx.a.run.app
```

Cap nhat `API_BASE_URL`:

```cmd
gcloud run services update sfinity-backend --region asia-southeast1 --update-env-vars API_BASE_URL=https://sfinity-backend-xxxxx.a.run.app/api
```

Hay thay URL bang URL that ma lenh describe tra ve.

## 9. Kiem tra sau deploy

Mo tren trinh duyet:

```text
https://YOUR_CLOUD_RUN_URL/api/docs
```

Hoac test bang CMD:

```cmd
curl https://YOUR_CLOUD_RUN_URL/api/openapi.json
```

## 10. Loi thuong gap

### Secret chua ton tai

Neu gap loi secret khong ton tai, quay lai Google Cloud Console va tao secret trong Secret Manager.

### Sai shell

PowerShell dung dau:

```powershell
`
```

CMD dung dau:

```cmd
^
```

Neu dang o Google Cloud SDK Shell mac dinh, kha nang cao ban dang dung `cmd`.

### Chua dung thu muc backend

Neu deploy tu root repo, Cloud Run co the khong thay dung `package.json`.

Dung:

```cmd
cd /d D:\Project\Sfinity_MobileApp\backend
```
