import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/constants/place_tags.dart';
import 'core/network/api_client.dart';
import 'core/services/deep_link_handler.dart';
import "firebase_options.dart";

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: 'assets/env/app.local.env');
  } catch (_) {
    await dotenv.load(fileName: 'assets/env/app.env');
  }
}

Future<void> _fetchAndInitAmenities() async {
  try {
    final list = await ApiClient.instance.getList('/amenities');
    PlaceTags.initialize(list);
  } catch (e) {
    debugPrint('Failed to load amenities from Firebase/Backend: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lắng nghe deep link MoMo → Sfinity (`sfinity://payment-callback?orderId=...`)
  // Bắt đầu sớm để nhận cả cold-start (app mở từ link) lẫn warm-resume.
  // ignore: discarded_futures
  DeepLinkHandler.instance.start();

  // Load amenities asynchronously in the background
  _fetchAndInitAmenities();

  runApp(const SfinityApp());
}
