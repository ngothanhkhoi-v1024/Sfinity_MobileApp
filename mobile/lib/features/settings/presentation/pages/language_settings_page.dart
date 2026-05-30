import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = SfinityApp.localeManager.locale;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.language)),
      body: ListView(
        children: [
          RadioListTile<Locale>(
            title: Text(l10n.vietnamese),
            subtitle: Text(l10n.useAppInVietnamese),
            value: const Locale('vi'),
            groupValue: locale,
            onChanged: (value) {
              if (value != null) SfinityApp.localeManager.setLocale(value);
            },
          ),
          RadioListTile<Locale>(
            title: Text(l10n.english),
            subtitle: Text(l10n.useAppInEnglish),
            value: const Locale('en'),
            groupValue: locale,
            onChanged: (value) {
              if (value != null) SfinityApp.localeManager.setLocale(value);
            },
          ),
        ],
      ),
    );
  }
}
