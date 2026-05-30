# 📂 Sơ Đồ Cấu Trúc Cơ Sở Dữ Liệu Google Cloud Firestore (Sfinity)

Tài liệu này đóng vai trò là **Source of Truth (Nguồn thông tin chuẩn)** về sơ đồ cấu trúc dữ liệu NoSQL Firestore của dự án Sfinity. Vì Firestore là cơ sở dữ liệu phi quan hệ (schema-less), tài liệu này giúp toàn bộ thành viên trong nhóm phát triển nắm bắt chính xác các Collection, cấu trúc các Document, kiểu dữ liệu và ý nghĩa của từng thuộc tính.

---

## 📌 Các Collection Chính Trong Hệ Thống

| Tên Collection | Mô tả chức năng | Khóa chính (Document ID) |
| :--- | :--- | :--- |
| `users` | Lưu thông tin hồ sơ và phân quyền tài khoản sinh viên. | `uid` (Trùng khớp với Firebase Auth UID) |
| `documents` | Lưu trữ tài liệu học tập (PDF) và địa điểm bản đồ (Polymorphic). | Mã chuỗi tự sinh ngẫu nhiên |
| `categories` | Phân mục các loại tài liệu học tập (Bài giảng, Đề thi...). | Mã chuỗi tự sinh ngẫu nhiên |
| `document_reviews`| Lưu trữ điểm số sao và bình luận đánh giá tài liệu học tập. | Mã chuỗi tự sinh ngẫu nhiên |
| `favorites` | Lưu danh sách tài liệu sinh viên đánh dấu yêu thích/lưu lại. | Mã chuỗi tự sinh ngẫu nhiên |
| `place_reviews` | Điểm số và nhận xét các địa điểm trên bản đồ. | Mã chuỗi tự sinh ngẫu nhiên |
| `place_photos` | Danh sách hình ảnh thực tế của địa điểm do sinh viên chụp. | Mã chuỗi tự sinh ngẫu nhiên |
| `notifications` | Lịch sử thông báo đẩy gửi tới thiết bị người dùng. | Mã chuỗi tự sinh ngẫu nhiên |
| `feedbacks` | Phản hồi góp ý của người dùng gửi cho ban quản trị. | Mã chuỗi tự sinh ngẫu nhiên |
| `reports` | Báo cáo vi phạm các tài liệu/địa điểm chờ duyệt. | Mã chuỗi tự sinh ngẫu nhiên |
| `password_resets` | OTP và thời gian hết hạn khôi phục mật khẩu tạm thời. | Mã chuỗi tự sinh ngẫu nhiên |
| `friendships` | Trạng thái quan hệ bạn bè giữa các người dùng. | `requesterId_addresseeId` |
| `groups` | Thông tin nhóm học tập/thảo luận. | Mã chuỗi tự sinh ngẫu nhiên |
| `group_members` | Thành viên tham gia nhóm và vai trò tương ứng. | `groupId_userId` |

---

## 🛠️ Chi Tiết Thuộc Tính & Kiểu Dữ Liệu Từng Bộ Sưu Tập

### 1. Collection `users`
Mỗi tài liệu tương ứng với một hồ sơ người dùng.

```typescript
interface UserDocument {
  id: string;              // UID đồng bộ trực tiếp với Firebase Auth UID
  email: string;           // Email đăng nhập sinh viên (chữ thường)
  name: string;            // Tên hiển thị đầy đủ
  avatar: string | null;   // URL ảnh đại diện (Firebase Storage / Google URL)
  role: 'USER' | 'ADMIN';  // Quyền hạn tài khoản
  status: 'ACTIVE' | 'BANNED'; // Trạng thái hoạt động của tài khoản
  authProvider: 'LOCAL' | 'GOOGLE' | 'FACEBOOK'; // Phương thức đăng nhập
  providerUserId: string;  // ID tài khoản bên mạng xã hội (hoặc trùng với UID)
  passwordHash?: string;   // Chuỗi mã hóa bcrypt mật khẩu (chỉ có ở LOCAL)
  createdAt: Timestamp;    // Thời gian đăng ký tài khoản
  updatedAt: Timestamp;    // Thời gian cập nhật thông tin gần nhất
}
```

---

### 2. Collection `documents`
Sử dụng mô hình đa hình (Polymorphic) phân biệt bằng trường `type`:
* **`type === 'document'`**: Tài liệu học tập (.pdf)
* **`type === 'place'`**: Địa điểm học tập trên bản đồ

```typescript
interface BaseContentDocument {
  id: string;                  // ID tài liệu tự sinh
  title: string;               // Tiêu đề tài liệu hoặc Tên địa điểm học tập
  body: string;                // Mô tả chi tiết / Tóm tắt nội dung
  status: 'DRAFT' | 'PUBLISHED'; // 'DRAFT' = Chỉ mình tôi, 'PUBLISHED' = Công khai
  authorId: string;            // ID người đăng (Liên kết với users.id)
  categoryId: string | null;   // ID danh mục (Liên kết với categories.id)
  type: 'document' | 'place'; // Kiểu tài nguyên
  createdAt: Timestamp;        // Thời gian khởi tạo
  updatedAt: Timestamp;        // Thời gian chỉnh sửa gần nhất
}

// 📄 Khi type === 'document' (Tài liệu học tập)
interface DocumentExtension {
  fileUrl: string | null;      // Link tải tệp tin PDF trên Firebase Storage
  fileType: 'pdf' | string;    // Định dạng tệp tin (Bắt buộc là pdf)
  fileSize: number | null;     // Kích thước tệp tin (bytes)
  subjectCode: string | null;  // Mã học phần/môn học (VD: MI1111)
  tags: string[];              // Mảng các thẻ tìm kiếm (VD: ["de-thi", "k68"])
  downloadsCount: number;      // Số lượt tải xuống tài liệu (mặc định: 0)
  likesCount: number;          // Số lượt yêu thích (mặc định: 0)
  placeId: string | null;      // ID địa điểm liên kết nếu tải lên tại địa điểm cụ thể
}

// 📍 Khi type === 'place' (Địa điểm bản đồ)
interface PlaceExtension {
  latitude: number;            // Vĩ độ trên bản đồ OpenStreetMap
  longitude: number;           // Kinh độ trên bản đồ OpenStreetMap
  address: string | null;      // Địa chỉ cụ thể
  zone: string | null;         // Khu vực trường (VD: "Khu A", "Thư viện")
  tags: string[];              // Các tiện ích tại điểm (VD: ["wifi", "o-cam-dien"])
}
```

---

### 3. Collection `categories`
Lưu trữ thông tin phân loại bài viết/tài liệu học tập.

```typescript
interface CategoryDocument {
  id: string;          // ID danh mục tự sinh
  name: string;        // Tên hiển thị (VD: "Đề thi", "Bài giảng")
  slug: string;        // Viết liền không dấu để query dễ dàng (VD: "de-thi")
  description: string; // Mô tả ngắn gọn về danh mục
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

### 4. Collection `document_reviews`
Lưu trữ đánh giá chất lượng tài liệu học tập của sinh viên.

```typescript
interface DocumentReviewDocument {
  id: string;          // ID tự sinh
  documentId: string;  // Liên kết đến documents.id (chỉ loại type: 'document')
  userId: string;      // ID sinh viên đánh giá (Liên kết với users.id)
  rating: number;      // Đánh giá sao số nguyên từ 1 đến 5
  comment: string | null; // Bình luận, nhận xét kèm theo
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

### 5. Collection `favorites`
Theo dõi các tài liệu sinh viên đã lưu lại để đọc sau.

```typescript
interface FavoriteDocument {
  id: string;          // ID tự sinh
  userId: string;      // ID sinh viên (Liên kết với users.id)
  contentId: string;   // ID tài liệu yêu thích (Liên kết với documents.id)
  createdAt: Timestamp;// Thời gian đánh dấu yêu thích
}
```

---

### 6. Collection `friendships`
Quản lý mối quan hệ bạn bè, yêu cầu kết bạn và chặn người dùng.

```typescript
interface FriendshipDocument {
  id: string;          // Khóa chính (định dạng: requesterId_addresseeId)
  requesterId: string; // ID người gửi lời mời (users.id)
  addresseeId: string; // ID người nhận lời mời (users.id)
  status: 'PENDING' | 'ACCEPTED' | 'BLOCKED'; // Trạng thái quan hệ
  createdAt: Timestamp; // Thời gian gửi lời mời
  updatedAt: Timestamp; // Thời gian cập nhật trạng thái mới nhất
}
```

---

### 7. Collection `groups`
Quản lý thông tin các phòng học nhóm/thảo luận.

```typescript
interface GroupDocument {
  id: string;          // ID nhóm tự sinh
  name: string;        // Tên hiển thị của nhóm
  description: string | null; // Mô tả nhóm học tập
  avatarUrl: string | null;   // Link ảnh đại diện của nhóm
  isPublic: boolean;   // Nhóm công khai (true) hoặc nhóm riêng tư (false)
  creatorId: string;   // ID của chủ sở hữu nhóm (users.id)
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

### 8. Collection `group_members`
Quản lý thành viên trong từng nhóm học tập.

```typescript
interface GroupMemberDocument {
  id: string;          // Khóa chính (định dạng: groupId_userId)
  groupId: string;     // ID nhóm (groups.id)
  userId: string;      // ID người dùng (users.id)
  role: 'OWNER' | 'ADMIN' | 'MEMBER'; // Vai trò của thành viên trong nhóm
  joinedAt: Timestamp; // Thời gian gia nhập nhóm
}
```

---

## 💡 Phương Pháp Tốt Nhất Để Quản Lý Schema Trong Nhóm Phát Triển

Để tất cả các thành viên trong dự án không bị mơ hồ về cơ sở dữ liệu Firestore, nhóm của bạn nên áp dụng đồng thời 2 quy chuẩn sau:

### Quy chuẩn 1: Khai báo TypeScript Interfaces
Định nghĩa sẵn các kiểu dữ liệu của Document tại một file tập trung, ví dụ: `backend/src/types/database.ts`. Bất kỳ khi nào làm việc với Firestore, lập trình viên sẽ ép kiểu dữ liệu để nhận được gợi ý Code (Autocomplete) tự động từ IDE:
```typescript
// Ví dụ khi lấy dữ liệu người dùng:
const snapshot = await getDb().collection('users').doc(uid).get();
const user = snapshot.data() as UserDocument;
// Gõ user. -> IDE sẽ tự động gợi ý các thuộc tính: name, email, role, status...
```

### Quy chuẩn 2: Viết Firestore Security Rules (`firestore.rules`)
Viết file định nghĩa quyền truy cập và ràng buộc kiểu dữ liệu ngay tại gốc dự án. Nó không chỉ bảo vệ dữ liệu mà còn hoạt động giống như một schema động xác thực dữ liệu gửi lên.
