# Login rework guide

Mac dinh minh bam theo app Flutter trong `mobile/`, vi repo nay da co:

- `mobile/lib/features/auth/presentation/pages/login_page.dart`
- `mobile/lib/core/auth/auth_repository.dart`
- `backend/prisma/schema.prisma`

Neu ban dang muon sua `web-admin` thay vi `mobile`, noi minh biet la minh doi guide theo React/Vite.

## Luu y truoc khi copy code

- Cac file hien tai dang co dau hieu loi encoding UTF-8 trong chuoi tieng Viet.
- Neu ban muon hien thi chu co dau dep, luu file bang `UTF-8`.
- Trong snippet ben duoi, minh de label UI theo dang ASCII de tranh tiep tuc bi moji-bake.

## Muc tieu

- Giao dien login tong mau vang cam.
- Co icon hien/an mat khau.
- Co nut dang nhap bang Google va Facebook.
- Mobile dang nhap social qua Firebase Auth.
- Backend verify Firebase ID token roi luu/doi chieu user bang Prisma + SQLite.
- Khong sua source cho ban, chi dua code trong file MD de ban tu copy.

## 1. Them dependencies

### `mobile/pubspec.yaml`

Them vao `dependencies`:

```yaml
firebase_core: ^4.9.0
firebase_auth: ^6.2.0
google_sign_in: ^7.2.0
flutter_facebook_auth: ^7.1.6
```

### `backend/package.json`

Them vao `dependencies`:

```json
  "firebase-admin": "^13.5.0"
```

## 2. Mobile app

### Thay file `mobile/lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/app.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SfinityApp());
}
```

Ghi chu:

- File `firebase_options.dart` duoc tao boi `flutterfire configure`.
- Neu ban dung Facebook login tren Flutter Web, can them `webInitialize()` rieng theo doc cua package.

### Thay file `mobile/lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _primary = Color(0xFFF59E0B);
  static const _secondary = Color(0xFFF97316);
  static const _surface = Color(0xFFFFFBF5);
  static const _textDark = Color(0xFF2F1B05);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      onPrimary: _textDark,
      onSecondary: Colors.white,
      onSurface: _textDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFFF7ED),
      appBarTheme: const AppBarTheme(centerTitle: true),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _textDark,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
  }
}
```

### Thay file `mobile/lib/core/auth/auth_repository.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class AuthRepository {
  static const _tokenKey = 'access_token';

  final _api = ApiClient.instance;
  bool _googleInitialized = false;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    await _saveSession(data);
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    await _ensureGoogleInitialized();

    final account = await GoogleSignIn.instance.authenticate();
    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google login khong tra ve idToken.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await FirebaseAuth.instance.signInWithCredential(credential);

    return _loginWithFirebase('google.com');
  }

  Future<Map<String, dynamic>> loginWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception(result.message ?? 'Facebook login that bai.');
    }

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
    return _loginWithFirebase('facebook.com');
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    final data = await _api.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    await _saveSession(data);
    return data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _api.get('/auth/me');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _api.setToken(null);

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _loginWithFirebase(String provider) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Khong lay duoc Firebase ID token.');
    }

    final data = await _api.post('/auth/firebase-login', {
      'idToken': idToken,
      'provider': provider,
    });

    await _saveSession(data);
    return data;
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;

    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['accessToken'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _api.setToken(token);
  }
}
```

Ghi chu:

- Doan `GoogleSignIn.instance.initialize()` can duoc goi 1 lan roi moi `authenticate()`.
- Flow nay phu hop Android/iOS. Neu ban can Google login cho Flutter Web, can them phan `google_sign_in_web` theo doc cua package.

### Thay file `mobile/lib/core/auth/auth_state.dart`

```dart
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import 'auth_repository.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._repo);

  final AuthRepository _repo;
  Map<String, dynamic>? user;
  bool isLoading = true;

  bool get isAuthenticated => user != null;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    try {
      final token = await _repo.getToken();
      if (token != null) {
        ApiClient.instance.setToken(token);
        user = await _repo.getProfile();
      }
    } catch (_) {
      await _repo.clearSession();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final result = await _repo.login(email, password);
    user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    final result = await _repo.loginWithGoogle();
    user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> loginWithFacebook() async {
    final result = await _repo.loginWithFacebook();
    user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> register(String email, String password, String name) async {
    final result = await _repo.register(email, password, name);
    user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.clearSession();
    user = null;
    notifyListeners();
  }

  void setUser(Map<String, dynamic> data) {
    user = data;
    notifyListeners();
  }
}
```

### Thay file `mobile/lib/features/auth/presentation/pages/login_page.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'user@sfinity.com');
  final _password = TextEditingController(text: 'user123');

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _runAction(() async {
      FocusScope.of(context).unfocus();
      await SfinityApp.auth.login(
        _email.text.trim(),
        _password.text,
      );
      if (mounted) context.go(RouteNames.home);
    });
  }

  Future<void> _loginWithGoogle() async {
    await _runAction(() async {
      await SfinityApp.auth.loginWithGoogle();
      if (mounted) context.go(RouteNames.home);
    });
  }

  Future<void> _loginWithFacebook() async {
    await _runAction(() async {
      await SfinityApp.auth.loginWithFacebook();
      if (mounted) context.go(RouteNames.home);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await action();
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = ApiClient.instance.errorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFF59E0B);
    const brandOrange = Color(0xFFF97316);
    const brandDark = Color(0xFF2F1B05);

    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF3C4),
              Color(0xFFFFD89A),
              Color(0xFFFFB76B),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -40,
                child: Container(
                  height: 220,
                  width: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.20),
                  ),
                ),
              ),
              Positioned(
                bottom: -70,
                left: -10,
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.16),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x331E1204),
                            blurRadius: 30,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 72,
                                width: 72,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [brandYellow, brandOrange],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_person_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Dang nhap',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: brandDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chao mung ban quay lai voi Sfinity.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: brandDark.withOpacity(0.75),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Demo: user@sfinity.com / user123',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: brandDark.withOpacity(0.60),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_error != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFDA4AF),
                                    ),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFF9F1239),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || !value.contains('@')) {
                                    return 'Nhap email hop le.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Mat khau',
                                  prefixIcon: const Icon(Icons.key_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return 'Mat khau toi thieu 6 ky tu.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => context.push(RouteNames.forgotPassword),
                                  child: const Text('Quen mat khau?'),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: brandYellow,
                                  foregroundColor: brandDark,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: brandDark,
                                        ),
                                      )
                                    : const Text('Dang nhap'),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: brandDark.withOpacity(0.14),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'Hoac tiep tuc voi',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: brandDark.withOpacity(0.65),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: brandDark.withOpacity(0.14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _SocialButton(
                                label: 'Dang nhap voi Google',
                                color: const Color(0xFFFFFAF0),
                                borderColor: const Color(0xFFFAC97D),
                                icon: const _LetterBadge(
                                  letter: 'G',
                                  background: Color(0xFFFFB020),
                                ),
                                onPressed: _loading ? null : _loginWithGoogle,
                              ),
                              const SizedBox(height: 12),
                              _SocialButton(
                                label: 'Dang nhap voi Facebook',
                                color: const Color(0xFFFFFAF0),
                                borderColor: const Color(0xFFFAC97D),
                                icon: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Color(0xFF1877F2),
                                  child: Icon(
                                    Icons.facebook_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: _loading ? null : _loginWithFacebook,
                              ),
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context.push(RouteNames.register),
                                child: const Text('Chua co tai khoan? Dang ky'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final Color color;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F1B05),
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({
    required this.letter,
    required this.background,
  });

  final String letter;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: background,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
```

### Kiem tra `mobile/assets/env/app.env`

File nay hien tai da dung duoc. Chi can chon dung URL:

```env
# Android Emulator
API_BASE_URL=http://10.0.2.2:3000/api

# iOS Simulator
# API_BASE_URL=http://127.0.0.1:3000/api

# Real device
# API_BASE_URL=http://YOUR_LAN_IP:3000/api
```

Neu ban test tren dien thoai that ma de `10.0.2.2` thi login se fail vi app khong cham duoc backend.

## 3. Backend Prisma + SQLite + Firebase

### Sua `backend/prisma/schema.prisma`

Them enum moi:

```prisma
enum AuthProvider {
  LOCAL
  GOOGLE
  FACEBOOK
}
```

Cap nhat model `User` thanh:

```prisma
model User {
  id             String       @id @default(cuid())
  email          String       @unique
  passwordHash   String?
  name           String
  avatar         String?
  role           UserRole     @default(USER)
  status         UserStatus   @default(ACTIVE)
  authProvider   AuthProvider @default(LOCAL)
  providerUserId String?
  createdAt      DateTime     @default(now())
  updatedAt      DateTime     @updatedAt

  contents      Content[]
  favorites     Favorite[]
  feedbacks     Feedback[]
  reports       Report[]
  notifications Notification[]

  @@unique([authProvider, providerUserId])
}
```

Ghi chu:

- `passwordHash` phai doi thanh nullable de user social login van luu duoc.
- Backend van dung SQLite qua Prisma, chi la schema user co them thong tin provider.

### Thay file `backend/src/lib/config.ts`

```ts
import 'dotenv/config';

export const config = {
  port: Number(process.env.PORT ?? 3000),
  jwtSecret: process.env.JWT_SECRET ?? 'dev-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? '',
  firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL ?? '',
  firebasePrivateKey: process.env.FIREBASE_PRIVATE_KEY ?? '',
} as const;
```

### Tao file moi `backend/src/lib/firebase.ts`

```ts
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

import { config } from './config';

const firebaseApp =
  getApps()[0] ??
  initializeApp({
    credential: cert({
      projectId: config.firebaseProjectId,
      clientEmail: config.firebaseClientEmail,
      privateKey: config.firebasePrivateKey.replace(/\\n/g, '\n'),
    }),
  });

export const firebaseAuth = getAuth(firebaseApp);
```

### Tao file moi `backend/src/dto/firebase-login.dto.ts`

```ts
import { IsIn, IsString, MinLength } from 'class-validator';

export class FirebaseLoginDto {
  @IsString()
  @MinLength(20)
  idToken!: string;

  @IsString()
  @IsIn(['google.com', 'facebook.com'])
  provider!: 'google.com' | 'facebook.com';
}
```

### Thay file `backend/src/services/auth.service.ts`

```ts
import { AuthProvider, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

import { config } from '../lib/config';
import { firebaseAuth } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';
import type {
  ChangePasswordDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  UpdateProfileDto,
} from '../dto/password.dto';
import type { LoginDto, RegisterDto } from '../dto/login.dto';
import type { FirebaseLoginDto } from '../dto/firebase-login.dto';

function sanitizeUser(user: {
  id: string;
  email: string;
  name: string;
  avatar: string | null;
  role: UserRole;
  status: string;
  authProvider: AuthProvider;
  createdAt: Date;
}) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    avatar: user.avatar ?? undefined,
    role: user.role.toLowerCase() as 'admin' | 'user',
    status: user.status,
    authProvider: user.authProvider.toLowerCase() as 'local' | 'google' | 'facebook',
    createdAt: user.createdAt,
  };
}

function signToken(user: { id: string; email: string; role: UserRole }) {
  const accessToken = jwt.sign(
    { sub: user.id, email: user.email, role: user.role },
    config.jwtSecret,
    { expiresIn: config.jwtExpiresIn as jwt.SignOptions['expiresIn'] },
  );

  return { accessToken };
}

function mapFirebaseProvider(provider: string): AuthProvider {
  switch (provider) {
    case 'google.com':
      return AuthProvider.GOOGLE;
    case 'facebook.com':
      return AuthProvider.FACEBOOK;
    default:
      throw new HttpError(400, 'Firebase provider khong hop le', 'Bad Request');
  }
}

export const authService = {
  async login(dto: LoginDto, adminOnly = false) {
    const user = await prisma.user.findUnique({ where: { email: dto.email } });

    if (!user) {
      throw new HttpError(401, 'Email hoac mat khau khong dung', 'Unauthorized');
    }

    if (!user.passwordHash) {
      throw new HttpError(
        400,
        'Tai khoan nay dang su dung Google/Facebook login. Hay dang nhap bang social button.',
        'Bad Request',
      );
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new HttpError(401, 'Email hoac mat khau khong dung', 'Unauthorized');
    }

    if (user.status === 'BANNED') {
      throw new HttpError(401, 'Tai khoan da bi khoa', 'Unauthorized');
    }

    if (adminOnly && user.role !== UserRole.ADMIN) {
      throw new HttpError(401, 'Tai khoan khong co quyen quan tri', 'Unauthorized');
    }

    return {
      ...signToken(user),
      user: sanitizeUser(user),
    };
  },

  async loginWithFirebase(dto: FirebaseLoginDto) {
    let decoded: Awaited<ReturnType<typeof firebaseAuth.verifyIdToken>>;

    try {
      decoded = await firebaseAuth.verifyIdToken(dto.idToken);
    } catch {
      throw new HttpError(401, 'Firebase token khong hop le', 'Unauthorized');
    }

    const tokenProvider = decoded.firebase?.sign_in_provider ?? '';

    if (tokenProvider !== dto.provider) {
      throw new HttpError(400, 'Provider khong khop voi Firebase token', 'Bad Request');
    }

    const authProvider = mapFirebaseProvider(tokenProvider);
    const email = decoded.email?.trim().toLowerCase();

    if (!email) {
      throw new HttpError(400, 'Firebase token khong co email', 'Bad Request');
    }

    const displayName =
      decoded.name?.trim() ||
      email.split('@').first ||
      'Sfinity User';

    const avatar =
      typeof decoded.picture === 'string' && decoded.picture.trim().length > 0
        ? decoded.picture
        : null;

    let user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email,
          name: displayName,
          avatar,
          role: UserRole.USER,
          authProvider,
          providerUserId: decoded.uid,
        },
      });
    } else {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          name: user.name.trim().length > 0 ? user.name : displayName,
          avatar: user.avatar ?? avatar,
          authProvider,
          providerUserId: decoded.uid,
        },
      });
    }

    if (user.status === 'BANNED') {
      throw new HttpError(401, 'Tai khoan da bi khoa', 'Unauthorized');
    }

    return {
      ...signToken(user),
      user: sanitizeUser(user),
    };
  },

  async register(dto: RegisterDto) {
    const exists = await prisma.user.findUnique({ where: { email: dto.email } });

    if (exists) {
      throw new HttpError(409, 'Email da duoc su dung', 'Conflict');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        name: dto.name,
        role: UserRole.USER,
        authProvider: AuthProvider.LOCAL,
      },
    });

    return {
      ...signToken(user),
      user: sanitizeUser(user),
    };
  },

  async getProfile(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }

    return sanitizeUser(user);
  },

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: { name: dto.name, avatar: dto.avatar },
    });

    return sanitizeUser(user);
  },

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }

    if (!user.passwordHash) {
      throw new HttpError(
        400,
        'Tai khoan social chua co mat khau local',
        'Bad Request',
      );
    }

    const valid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!valid) {
      throw new HttpError(401, 'Mat khau hien tai khong dung', 'Unauthorized');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);
    await prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash,
        authProvider: AuthProvider.LOCAL,
      },
    });

    return { success: true };
  },

  generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  },

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await prisma.user.findUnique({ where: { email: dto.email } });

    if (!user) {
      throw new HttpError(404, 'Khong tim thay tai khoan voi email nay', 'Not Found');
    }

    const code = authService.generateOtp();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await prisma.passwordReset.updateMany({
      where: { email: dto.email, used: false },
      data: { used: true },
    });

    await prisma.passwordReset.create({
      data: { email: dto.email, code, expiresAt },
    });

    return {
      message: 'Ma OTP da duoc gui (demo: hien thi truc tiep)',
      code,
      expiresInMinutes: 15,
    };
  },

  async resetPassword(dto: ResetPasswordDto) {
    const record = await prisma.passwordReset.findFirst({
      where: {
        email: dto.email,
        code: dto.code,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!record) {
      throw new HttpError(400, 'Ma OTP khong hop le hoac da het han', 'Bad Request');
    }

    const user = await prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);

    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: {
          passwordHash,
          authProvider: AuthProvider.LOCAL,
        },
      }),
      prisma.passwordReset.update({
        where: { id: record.id },
        data: { used: true },
      }),
    ]);

    return { success: true };
  },
};
```

### Thay file `backend/src/routes/auth.routes.ts`

```ts
import { Router } from 'express';

import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { authService } from '../services/auth.service';
import { LoginDto, RegisterDto } from '../dto/login.dto';
import { FirebaseLoginDto } from '../dto/firebase-login.dto';
import {
  ChangePasswordDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  UpdateProfileDto,
} from '../dto/password.dto';

export const authRouter = Router();

authRouter.post(
  '/login',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(LoginDto, req.body);
    res.json(await authService.login(dto));
  }),
);

authRouter.post(
  '/firebase-login',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(FirebaseLoginDto, req.body);
    res.json(await authService.loginWithFirebase(dto));
  }),
);

authRouter.post(
  '/admin/login',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(LoginDto, req.body);
    res.json(await authService.login(dto, true));
  }),
);

authRouter.post(
  '/register',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(RegisterDto, req.body);
    res.json(await authService.register(dto));
  }),
);

authRouter.post(
  '/forgot-password',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(ForgotPasswordDto, req.body);
    res.json(await authService.forgotPassword(dto));
  }),
);

authRouter.post(
  '/reset-password',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(ResetPasswordDto, req.body);
    res.json(await authService.resetPassword(dto));
  }),
);

authRouter.get(
  '/me',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(await authService.getProfile(req.user!.sub));
  }),
);

authRouter.patch(
  '/profile',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateProfileDto, req.body);
    res.json(await authService.updateProfile(req.user!.sub, dto));
  }),
);

authRouter.post(
  '/change-password',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(ChangePasswordDto, req.body);
    res.json(await authService.changePassword(req.user!.sub, dto));
  }),
);
```

### Cap nhat `backend/.env.example`

```env
DATABASE_URL="file:./dev.db"
JWT_SECRET="change-me-in-production"
JWT_EXPIRES_IN="7d"
PORT=3000

FIREBASE_PROJECT_ID=""
FIREBASE_CLIENT_EMAIL=""
FIREBASE_PRIVATE_KEY=""
```

`FIREBASE_PRIVATE_KEY` can duoc paste theo dang 1 dong, vi code da doi `\\n` thanh newline that.

Vi du:

```env
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nABC...\n-----END PRIVATE KEY-----\n"
```

## 4. Cac buoc chay sau khi ban tu sua code

### Mobile

```bash
cd mobile
flutter pub get
flutterfire configure
```

Neu ban chua bat Google/Facebook trong Firebase Console:

1. Vao Firebase Console.
2. Bat `Authentication`.
3. Enable `Google`.
4. Enable `Facebook`.
5. Dien `App ID` va `App Secret` cua Facebook.

### Backend

```bash
cd backend
npm install
npx prisma migrate dev --name add-social-login
npx prisma generate
npm run start:dev
```

## 5. Flow API sau khi sua

### Email/password

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@sfinity.com",
  "password": "user123"
}
```

### Google/Facebook

Mobile flow:

1. Flutter dang nhap bang Firebase SDK.
2. Lay `Firebase ID token`.
3. Goi backend:

```http
POST /api/auth/firebase-login
Content-Type: application/json

{
  "idToken": "FIREBASE_ID_TOKEN",
  "provider": "google.com"
}
```

Hoac:

```http
POST /api/auth/firebase-login
Content-Type: application/json

{
  "idToken": "FIREBASE_ID_TOKEN",
  "provider": "facebook.com"
}
```

Backend se:

- verify token bang `firebase-admin`
- doc email / uid / picture
- tao hoac cap nhat user trong `sqlite`
- tra JWT hien tai cua backend de app dung chung voi cac API con lai

## 6. Diem can check khi neu van loi

- `API_BASE_URL` dung hay chua.
- Firebase provider da bat trong Console chua.
- Android da co `google-services.json` chua.
- iOS da co `GoogleService-Info.plist` chua.
- Facebook app da khai bao package name / bundle id chua.
- Backend env da co `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` chua.
- Da migrate lai Prisma chua.

## 7. Nhan xet nhanh ve code hien tai

- Login page hien tai cua ban rat gon, nhung chua co social login va chua co toggle hien/an mat khau.
- Backend hien tai chi co `email/password`; chua co route verify Firebase token.
- Prisma dang dung `sqlite` san roi, nen phan "sua ket noi sqlite" chu yeu la mo rong schema va service auth, khong can doi sang DB khac.

Neu ban muon, buoc tiep theo minh co the viet them mot file MD nua danh rieng cho `register_page.dart` de dong bo cung style vang cam voi login.
