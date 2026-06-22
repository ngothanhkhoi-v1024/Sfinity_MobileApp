import 'package:flutter/foundation.dart';

import '../models/user_limits.dart';
import '../network/api_client.dart';

class UserLimitsService extends ChangeNotifier {
  UserLimits? limits;
  bool isLoading = false;

  bool get canCreateGroup => limits?.canCreateGroup ?? false;
  bool get canDownloadDocument => limits?.documentDownloads.canUse ?? true;
  bool get canCreatePlace => limits?.placesCreated.canUse ?? true;
  bool get canAddFriend => limits?.friends.canUse ?? true;

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.instance.get('/auth/me/limits');
      limits = UserLimits.fromJson(res);
    } catch (e) {
      debugPrint('Failed to load user limits: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    limits = null;
    notifyListeners();
  }
}
