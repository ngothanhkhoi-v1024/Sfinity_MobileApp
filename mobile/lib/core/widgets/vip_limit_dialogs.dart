import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_names.dart';
import '../i18n/app_text.dart';

abstract final class VipLimitDialogs {
  static void showLimitReached(
    BuildContext context, {
    required String message,
  }) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.limitReachedTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(RouteNames.subscription);
            },
            child: Text(l10n.upgradeVip),
          ),
        ],
      ),
    );
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: context.l10n.upgradeVip,
          onPressed: () => context.push(RouteNames.subscription),
        ),
      ),
    );
  }

  static bool handleFriendshipError(BuildContext context, String? error) {
    if (error == 'FRIEND_LIMIT') {
      showLimitReached(context, message: context.l10n.limitFriendsReached);
      return true;
    }
    return false;
  }
}
