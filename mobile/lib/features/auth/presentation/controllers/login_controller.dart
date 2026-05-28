import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class LoginController extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await SfinityApp.auth.login(email, password);
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

  Future<bool> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await SfinityApp.auth.loginWithGoogle();
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

  Future<bool> loginWithFacebook() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await SfinityApp.auth.loginWithFacebook();
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
