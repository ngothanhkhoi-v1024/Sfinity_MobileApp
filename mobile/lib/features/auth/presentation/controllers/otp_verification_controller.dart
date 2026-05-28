import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class OtpVerificationController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await SfinityApp.auth.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return true;
    } on DioException catch (e) {
      errorMessage = ApiClient.instance.errorMessage(e);
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
