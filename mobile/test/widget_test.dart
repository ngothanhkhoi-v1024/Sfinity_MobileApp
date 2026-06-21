import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sfinity/app.dart';

void main() {
  // Khởi tạo FFI cho sqflite để chạy trong môi trường kiểm thử (Desktop/Headless)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App loads home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SfinityApp());
    expect(find.byType(SfinityApp), findsOneWidget);
    
    // Tiêu thụ các Timer/Animation đang chạy ngầm trong SplashPage để tránh lỗi pending timer
    await tester.pump(const Duration(seconds: 5));
  });
}
