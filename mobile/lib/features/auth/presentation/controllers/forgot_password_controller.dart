import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

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
