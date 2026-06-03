# Deploy Backend Len Google Cloud Run Tu backend/.env

Cap nhat lan cuoi: `2026-06-03`

Tai lieu nay huong dan deploy backend len **Google Cloud Run** theo cach chi tiet, dung chinh file `backend/.env` lam nguon cau hinh.

Muc tieu cua tai lieu nay:

1. Ban chua cai `gcloud CLI` van lam duoc tu dau.
2. Ban doc gia tri cau hinh tu `backend/.env`, khong phai go lai tung gia tri.
3. Ban deploy bang `gcloud run deploy --source .`, khong can Docker local.

Tai lieu nay duoc viet theo repo hien tai:

- Build script: `npm run build`
- Start script: `node dist/main.js`
- Cau hinh moi truong doc tu `.env`
- Backend dang dung Firebase Admin / Firestore

## 1. Ban can biet truoc khi deploy

Backend hien tai co cac nhom cau hinh sau trong `backend/.env`:

- `PORT`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `DATABASE_URL`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`

Luu y quan trong:

- `PORT` khong can dua len Cloud Run. Cloud Run tu cap `PORT`.
- `DATABASE_URL="file:./dev.db"` chi phu hop local/dev. File system cua Cloud Run la tam thoi, nen khong duoc xem day la database production ben vung.
- `API_BASE_URL` khong co trong `backend/.env` hien tai, nhung ban nen them no vao Cloud Run sau khi deploy lan dau.
- Neu `.env` cua ban chua secret that, tuyet doi khong commit no len git.
- Neu `.env` da tung bi chia se, ban nen rotate lai `JWT_SECRET`, `SMTP_PASS`, va Firebase private key.

## 2. Cach map tung key tu `.env` len Cloud Run

Bang duoi day la cach dua tung key len Cloud Run:

| Key trong `.env` | Dua len dau | Cach dung |
|---|---|---|
| `PORT` | Khong can | Cloud Run tu set |
| `JWT_SECRET` | Secret Manager | Secret |
| `JWT_EXPIRES_IN` | Cloud Run env var | Env var |
| `DATABASE_URL` | Thuong bo qua | Neu dua len thi chi de tuong thich, khong de luu du lieu production |
| `FIREBASE_PROJECT_ID` | Cloud Run env var | Env var |
| `FIREBASE_CLIENT_EMAIL` | Cloud Run env var | Env var |
| `FIREBASE_PRIVATE_KEY` | Secret Manager | Secret |
| `SMTP_HOST` | Cloud Run env var | Env var |
| `SMTP_PORT` | Cloud Run env var | Env var |
| `SMTP_SECURE` | Cloud Run env var | Env var |
| `SMTP_USER` | Secret Manager | Secret |
| `SMTP_PASS` | Secret Manager | Secret |
| `SMTP_FROM` | Cloud Run env var | Env var |
| `API_BASE_URL` | Cloud Run env var | Tao sau khi co URL Cloud Run |

Quy tac copy gia tri tu `.env`:

- Chi copy **phan value** sau dau `=`.
- Khong copy ten key.
- Khong copy dau ngoac kep bao ngoai neu co.
- Rieng `FIREBASE_PRIVATE_KEY`, giu nguyen noi dung dang co trong `.env`, bao gom ca chuoi `\n`.

Vi du:

```env
JWT_SECRET="my-secret"
```

Khi dua len Secret Manager, gia tri ban luu phai la:

```text
my-secret
```

Khong phai:

```text
"my-secret"
```

## 3. Neu chua muon cai gcloud CLI

Neu ban muon deploy ngay ma chua cai `gcloud CLI`, ban co the dung **Cloud Shell** trong Google Cloud Console.

Cach nay nhanh nhat:

1. Mo Google Cloud Console
2. Bam icon `>_` de mo Cloud Shell
3. Clone repo vao Cloud Shell
4. Chay cac lenh `gcloud` ngay trong trinh duyet

Tuy nhien, tai lieu nay uu tien huong dan theo cach **cai `gcloud CLI` tren Windows** vi ban dang lam viec trong PowerShell.

## 4. Cai gcloud CLI tren Windows

Tai lieu chinh thuc:

- Install Google Cloud CLI:
  https://docs.cloud.google.com/sdk/docs/install-sdk
- Initialize Google Cloud CLI:
  https://docs.cloud.google.com/sdk/docs/initializing

Lam theo cac buoc sau:

1. Mo trang cai dat chinh thuc:
   `https://docs.cloud.google.com/sdk/docs/install-sdk`
2. Tai ban cai cho Windows.
3. Chay installer.
4. De nguyen tuy chon mac dinh, nhat la phan Python bundled.
5. Ket thuc cai dat, mo lai PowerShell moi.
6. Kiem tra:

```powershell
gcloud version
```

Neu lenh tren chay duoc, CLI da cai xong.

Khoi tao `gcloud`:

```powershell
gcloud init
```

Neu may cua ban khong mo duoc browser trong qua trinh dang nhap:

```powershell
gcloud init --console-only
```

Sau buoc nay, ban da co the dung `gcloud` tren PowerShell.

## 5. Chuan bi truoc khi deploy

### 5.1. Dam bao co Google Cloud Project

Ban can:

- co mot Google Cloud Project
- da bat Billing cho project

Neu chua co project, tao bang Google Cloud Console truoc.

### 5.2. Kiem tra backend build duoc local

Chay trong PowerShell:

```powershell
cd d:\Project\Sfinity_MobileApp\backend
npm ci
npm run build
```

Neu build fail, xu ly loi local truoc khi deploy.

### 5.3. Chon region

Co the dung `asia-southeast1` de gan Viet Nam.

Vi du:

```powershell
$PROJECT_ID="YOUR_GCP_PROJECT_ID"
$REGION="asia-southeast1"
$SERVICE="sfinity-backend"
$RUNTIME_SA="sfinity-backend-runtime@$PROJECT_ID.iam.gserviceaccount.com"
```

Luu y:

- `PROJECT_ID` nay la project tren Google Cloud de deploy Cloud Run.
- `FIREBASE_PROJECT_ID` doc tu `backend/.env` co the giong hoac khac `PROJECT_ID`.
- Neu backend cua ban dang noi vao Firebase project rieng, hay giu dung gia tri `FIREBASE_PROJECT_ID` trong `.env`.

## 6. Bat cac API can thiet

Dat project hien tai:

```powershell
gcloud config set project $PROJECT_ID
```

Bat cac API:

```powershell
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com iam.googleapis.com
```

Ghi chu:

- Theo tai lieu Cloud Run, deploy bang `--source` se dung Cloud Build va buildpacks.
- Neu project chua co Artifact Registry repository cho source deploy, Cloud Run se tu tao repository `cloud-run-source-deploy`.

## 7. Tao service account runtime cho Cloud Run

Tai lieu chinh thuc:

- Service identity:
  https://docs.cloud.google.com/run/docs/configuring/services/service-identity

Tao service account:

```powershell
gcloud iam service-accounts create sfinity-backend-runtime --display-name "Sfinity Backend Runtime"
```

Cap quyen doc secrets:

```powershell
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$RUNTIME_SA" --role="roles/secretmanager.secretAccessor"
```

Neu luc deploy ban gap loi lien quan `iam.serviceAccounts.actAs`, tai khoan dang deploy thuong can them quyen `Service Account User` tren runtime service account do.

## 8. Tao secrets trong Secret Manager tu `backend/.env`

Tai lieu chinh thuc:

- Secret Manager create secret:
  https://docs.cloud.google.com/secret-manager/docs/creating-and-accessing-secrets
- Secret versions:
  https://docs.cloud.google.com/secret-manager/docs/add-secret-version
- Cloud Run secrets:
  https://docs.cloud.google.com/run/docs/configuring/services/secrets

Voi repo nay, minh khuyen dung **Google Cloud Console** de tao secrets thay vi PowerShell, vi:

- `FIREBASE_PRIVATE_KEY` dai va de nham
- PowerShell de them newline ngoai y muon neu paste qua pipe
- Ban de kiem tra hon khi copy tu `.env`

### 8.1. Cac secret can tao

Tao 4 secret sau:

| Ten secret tren Google Cloud | Lay tu key nao trong `backend/.env` |
|---|---|
| `sfinity-jwt-secret` | `JWT_SECRET` |
| `sfinity-smtp-user` | `SMTP_USER` |
| `sfinity-smtp-pass` | `SMTP_PASS` |
| `sfinity-firebase-private-key` | `FIREBASE_PRIVATE_KEY` |

### 8.2. Cach tao bang Console

Lap lai cho tung secret:

1. Mo `Security` -> `Secret Manager`
2. Bam `Create Secret`
3. Dien ten secret
4. O phan `Secret value`, dan gia tri tu `backend/.env`
5. Chon `Automatic replication`
6. Bam `Create Secret`

### 8.3. Cach copy dung tu `.env`

Neu dong trong `.env` la:

```env
SMTP_PASS="your-app-password"
```

Thi value dua vao Secret Manager la:

```text
your-app-password
```

Neu dong trong `.env` la:

```env
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nABC...\n-----END PRIVATE KEY-----\n"
```

Thi value dua vao Secret Manager phai la:

```text
-----BEGIN PRIVATE KEY-----\nABC...\n-----END PRIVATE KEY-----\n
```

Tuc la:

- bo dau ngoac kep ben ngoai
- giu nguyen cac chuoi `\n`

## 9. Doc gia tri khong nhay cam tu `.env` bang PowerShell

De tranh go lai tay cac env var khong nhay cam, ban co the dung helper sau.

Chay trong thu muc root cua repo:

```powershell
function Get-DotEnvValue {
  param(
    [string]$Path,
    [string]$Key
  )

  $pattern = '^\s*' + [regex]::Escape($Key) + '\s*=\s*(.*)$'
  $line = Get-Content $Path | Where-Object { $_ -match $pattern } | Select-Object -First 1

  if (-not $line) {
    return $null
  }

  $value = ($line -split '=', 2)[1].Trim()

  if (
    ($value.StartsWith('"') -and $value.EndsWith('"')) -or
    ($value.StartsWith("'") -and $value.EndsWith("'"))
  ) {
    $value = $value.Substring(1, $value.Length - 2)
  }

  return $value
}

$EnvFile = "d:\Project\Sfinity_MobileApp\backend\.env"

$JWT_EXPIRES_IN = Get-DotEnvValue $EnvFile "JWT_EXPIRES_IN"
$FIREBASE_PROJECT_ID = Get-DotEnvValue $EnvFile "FIREBASE_PROJECT_ID"
$FIREBASE_CLIENT_EMAIL = Get-DotEnvValue $EnvFile "FIREBASE_CLIENT_EMAIL"
$SMTP_HOST = Get-DotEnvValue $EnvFile "SMTP_HOST"
$SMTP_PORT = Get-DotEnvValue $EnvFile "SMTP_PORT"
$SMTP_SECURE = Get-DotEnvValue $EnvFile "SMTP_SECURE"
$SMTP_FROM = Get-DotEnvValue $EnvFile "SMTP_FROM"
```

Sau do ban co the kiem tra xem doc da dung chua:

```powershell
$JWT_EXPIRES_IN
$FIREBASE_PROJECT_ID
$SMTP_HOST
```

Khong can in `JWT_SECRET`, `SMTP_PASS`, `FIREBASE_PRIVATE_KEY` ra terminal.

## 10. Deploy Cloud Run lan dau

Tai lieu chinh thuc:

- Deploy from source:
  https://docs.cloud.google.com/run/docs/deploying-source-code
- `gcloud run deploy`:
  https://docs.cloud.google.com/sdk/gcloud/reference/run/deploy

Ban can deploy tu thu muc `backend`:

```powershell
cd d:\Project\Sfinity_MobileApp\backend
```

Lenh deploy de xuat:

```powershell
gcloud run deploy $SERVICE `
  --source . `
  --region $REGION `
  --allow-unauthenticated `
  --service-account $RUNTIME_SA `
  --set-env-vars JWT_EXPIRES_IN="$JWT_EXPIRES_IN" `
  --set-env-vars FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" `
  --set-env-vars FIREBASE_CLIENT_EMAIL="$FIREBASE_CLIENT_EMAIL" `
  --set-env-vars SMTP_HOST="$SMTP_HOST" `
  --set-env-vars SMTP_PORT="$SMTP_PORT" `
  --set-env-vars SMTP_SECURE="$SMTP_SECURE" `
  --set-env-vars SMTP_FROM="$SMTP_FROM" `
  --set-secrets JWT_SECRET=sfinity-jwt-secret:1,SMTP_USER=sfinity-smtp-user:1,SMTP_PASS=sfinity-smtp-pass:1,FIREBASE_PRIVATE_KEY=sfinity-firebase-private-key:1
```

Ghi chu:

- Khong set `PORT`.
- Chua can set `API_BASE_URL` o lan deploy dau.
- Minh dang pin secret version ve `:1` thay vi `:latest` de on dinh hon cho production.
- Neu sau nay ban update secret, tao version moi roi update service dung version do.

### 10.1. Neu ban muon dua ca `DATABASE_URL`

Chi dung neu ban can tuong thich tam thoi:

```powershell
--set-env-vars DATABASE_URL="file:./dev.db"
```

Nhung can nho:

- Day khong phai luu tru ben vung
- Restart revision co the lam mat du lieu local SQLite

## 11. Lay URL Cloud Run va cap nhat API_BASE_URL

Sau khi deploy xong, lay URL service:

```powershell
$SERVICE_URL = gcloud run services describe $SERVICE --region $REGION --format="value(status.url)"
$SERVICE_URL
```

Backend nay dung `API_BASE_URL` de tao link email, nen ban can update no thanh:

```text
<service-url>/api
```

Vi du:

```text
https://sfinity-backend-xxxxx-uc.a.run.app/api
```

Cap nhat:

```powershell
gcloud run services update $SERVICE `
  --region $REGION `
  --update-env-vars API_BASE_URL="$SERVICE_URL/api"
```

Neu ban co custom domain cho API, hay dat:

```text
https://api.yourdomain.com/api
```

thay vi URL mac dinh cua Cloud Run.

## 12. Kiem tra sau khi deploy

Kiem tra 3 URL sau tren browser:

- `$SERVICE_URL/api`
- `$SERVICE_URL/api/docs`
- `$SERVICE_URL/api/openapi.json`

Doc logs neu can:

```powershell
gcloud run services logs read $SERVICE --region $REGION --limit=50
```

Neu muon loc loi:

```powershell
gcloud run services logs read $SERVICE --region $REGION --log-filter="severity>=ERROR" --limit=50
```

## 13. Deploy lai khi code thay doi

Moi lan sua code backend:

```powershell
cd d:\Project\Sfinity_MobileApp\backend
gcloud run deploy $SERVICE --source . --region $REGION
```

Neu chi doi env vars:

```powershell
gcloud run services update $SERVICE --region $REGION --update-env-vars KEY=VALUE
```

Neu chi doi secret version:

```powershell
gcloud run services update $SERVICE --region $REGION --update-secrets JWT_SECRET=sfinity-jwt-secret:2
```

## 14. Loi thuong gap va cach xu ly

### 14.1. `gcloud` khong duoc nhan dien

Mo PowerShell moi sau khi cai dat.

Neu van loi:

- khoi dong lai terminal
- chay lai installer
- kiem tra `gcloud version`

### 14.2. Loi quyen khi deploy

Thuong do:

- chua bat API
- tai khoan dang deploy khong du quyen
- service account runtime chua duoc gan dung

Thuong gap nhat:

- thieu quyen deploy Cloud Run
- thieu quyen Cloud Build
- thieu quyen `Service Account User`

### 14.3. Firebase loi khi app boot

Kiem tra lai:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

Hay chac chan rang:

- ban copy dung value tu `.env`
- ban khong giu dau ngoac kep ben ngoai
- ban giu nguyen cac chuoi `\n` trong private key

### 14.4. Gui mail that bai

Kiem tra lai:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`

Neu dung Gmail:

- nen dung App Password
- khong dung mat khau dang nhap thuong

### 14.5. Mat du lieu sau khi revision restart

Neu du lieu dang nam trong SQLite local file thi do la hanh vi binh thuong tren Cloud Run. Ban can chuyen phan du lieu can ben sang Firestore, Cloud SQL, hoac database production khac.

## 15. Luu y rieng cho backend nay

- `API_BASE_URL` nen la URL co hau to `/api`
- vi app mount router tai `/api`
- backend hien co route swagger tai `/api/docs`
- openapi json tai `/api/openapi.json`

Them mot luu y:

- backend co tao link verify email dua tren `API_BASE_URL`
- neu ban kiem thu flow email, hay test ky endpoint lien quan auth sau khi deploy

## 16. Nguon chinh thuc

- Install Google Cloud CLI:
  https://docs.cloud.google.com/sdk/docs/install-sdk
- Initialize Google Cloud CLI:
  https://docs.cloud.google.com/sdk/docs/initializing
- Cloud Run deploy from source:
  https://docs.cloud.google.com/run/docs/deploying-source-code
- gcloud run deploy reference:
  https://docs.cloud.google.com/sdk/gcloud/reference/run/deploy
- Cloud Run service identity:
  https://docs.cloud.google.com/run/docs/configuring/services/service-identity
- Cloud Run secrets:
  https://docs.cloud.google.com/run/docs/configuring/services/secrets
- Secret Manager create/access:
  https://docs.cloud.google.com/secret-manager/docs/creating-and-accessing-secrets
- Secret versions:
  https://docs.cloud.google.com/secret-manager/docs/add-secret-version
- Cloud Run logs:
  https://docs.cloud.google.com/run/docs/logging
