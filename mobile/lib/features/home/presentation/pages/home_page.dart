import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.article_outlined),
              title: Text(l10n.viewContent),
              subtitle: Text(l10n.publishedPostsList),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.documentList),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.notifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.notifications),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.feedback_outlined),
              title: Text(l10n.sendFeedback),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.feedback),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.reportViolationTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.report),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.settings),
          ),
        ),
        ],
      ),
    );
  }
}
