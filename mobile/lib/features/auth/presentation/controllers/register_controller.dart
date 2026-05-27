import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class RegisterController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<bool> register(String email, String password, String name) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await SfinityApp.auth.register(email, password, name);
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
