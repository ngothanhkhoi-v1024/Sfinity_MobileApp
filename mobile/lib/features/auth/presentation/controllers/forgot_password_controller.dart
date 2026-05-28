import 'package:flutter/foundation.dart';
import '../../../../app.dart';

class ForgotPasswordController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<bool> submit(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await SfinityApp.auth.forgotPassword(email);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
