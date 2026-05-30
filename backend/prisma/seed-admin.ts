import { getDb, getFirebaseAuth, isFirebaseReady } from '../src/lib/firebase';
import { AuthProvider, UserRole, UserStatus } from '../src/types/enums';
import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';

// Tải các biến môi trường từ .env
dotenv.config();

async function main() {
  const email = process.env.ADMIN_EMAIL || 'admin@sfinity.com';
  const password = process.env.ADMIN_PASSWORD || 'admin123';
  const name = process.env.ADMIN_NAME || 'Quản trị viên Sfinity';

  console.log('==================================================');
  console.log('⏳ Bắt đầu tiến trình Seed tài khoản Admin trên Firebase...');
  console.log('==================================================');

  // 1. Mã hóa mật khẩu
  const passwordHash = await bcrypt.hash(password, 10);

  // 2. Đồng bộ hóa Firebase (Firebase Auth & Firestore)
  let firebaseSeeded = false;
  let uid = 'admin-default-uid';

  if (isFirebaseReady()) {
    try {
      console.log('🔥 Đang kiểm tra/khởi tạo tài khoản trên Firebase Auth...');
      let fbUser;
      try {
        fbUser = await getFirebaseAuth().getUserByEmail(email);
        uid = fbUser.uid;
        // Cập nhật thông tin và mật khẩu cho tài khoản Firebase Auth hiện có
        await getFirebaseAuth().updateUser(uid, {
          password,
          displayName: name,
        });
        console.log('   ✅ Đã cập nhật mật khẩu & tên hiển thị trên Firebase Auth.');
      } catch (err: any) {
        if (err.code === 'auth/user-not-found') {
          // Tạo tài khoản mới trên Firebase Auth
          fbUser = await getFirebaseAuth().createUser({
            email,
            password,
            displayName: name,
            emailVerified: true,
          });
          uid = fbUser.uid;
          console.log('   ✅ Đã tạo tài khoản mới thành công trên Firebase Auth.');
        } else {
          throw err;
        }
      }

      console.log('🔥 Đang kiểm tra/đồng bộ dữ liệu lên Firestore (users collection)...');
      const firestoreUser = {
        id: uid,
        email,
        passwordHash,
        name,
        avatar: null,
        role: UserRole.ADMIN,
        status: UserStatus.ACTIVE,
        authProvider: AuthProvider.LOCAL,
        providerUserId: uid,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      
      await getDb().collection('users').doc(uid).set(firestoreUser, { merge: true });
      console.log('   ✅ Đã ghi nhận tài khoản Admin vào Firestore.');
      firebaseSeeded = true;
    } catch (firebaseErr: any) {
      console.error('   ❌ Lỗi đồng bộ Firebase:', firebaseErr.message);
      console.warn('   ⚠️ Tiến trình seed trên Firebase bị bỏ qua hoặc thất bại.');
    }
  } else {
    console.warn('⚠️ Lỗi: Biến môi trường FIREBASE_* chưa được khai báo đầy đủ.');
    process.exit(1);
  }

  console.log('\n==================================================');
  console.log('🎉 TIẾN TRÌNH SEED TÀI KHOẢN ADMIN HOÀN TẤT! 🎉');
  console.log('==================================================');
  console.log(`📍 Email đăng nhập:     ${email}`);
  console.log(`📍 Mật khẩu tài khoản:   ${password}`);
  console.log(`📍 Tên Admin hiển thị:   ${name}`);
  console.log(`📍 Trạng thái Firebase:  ${firebaseSeeded ? 'THÀNH CÔNG (Auth & Firestore)' : 'THẤT BẠI'}`);
  console.log('==================================================\n');
}

main().catch((err) => {
  console.error('❌ Lỗi nghiêm trọng xảy ra trong tiến trình seed:', err);
  process.exit(1);
});
