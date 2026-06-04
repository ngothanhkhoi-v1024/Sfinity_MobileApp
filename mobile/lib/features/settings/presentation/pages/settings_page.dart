import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _themeExpanded = false;
  bool _languageExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SfinityApp.themeManager,
        SfinityApp.localeManager,
        SfinityApp.notificationManager,
      ]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        final l10n = context.l10n;
        final locale = SfinityApp.localeManager.locale;
        final notificationsEnabled = SfinityApp.notificationManager.enabled;
        final appTheme = SfinityApp.themeManager.themeMode;
        final cardColor = isDark ? const Color(0xFF232323) : cs.surface;
        final borderColor = isDark
            ? const Color(0xFF2D2D2D)
            : cs.outlineVariant.withValues(alpha: 0.45);

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF111111) : theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              l10n.settings,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SettingsCard(
                backgroundColor: cardColor,
                borderColor: borderColor,
                child: _NotificationTile(
                  title: l10n.notifications,
                  subtitle: l10n.notificationsInApp,
                  value: notificationsEnabled,
                  iconBackground: isDark
                      ? const Color(0xFF34314D)
                      : const Color(0xFFF3EEFF),
                  iconColor: isDark
                      ? const Color(0xFFC6B7FF)
                      : const Color(0xFF6E59CF),
                  onChanged: (value) async {
                    await SfinityApp.notificationManager.setEnabled(value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                backgroundColor: cardColor,
                borderColor: borderColor,
                child: _ExpandableSettingsSection<ThemeMode>(
                  icon: Icons.dark_mode_rounded,
                  iconBackground: isDark
                      ? const Color(0xFF3C2A47)
                      : const Color(0xFFFFEEF7),
                  iconColor: isDark
                      ? const Color(0xFFF39AE1)
                      : const Color(0xFFC25492),
                  title: l10n.theme,
                  value: _themeLabel(context, appTheme),
                  expanded: _themeExpanded,
                  onTap: () {
                    setState(() {
                      _themeExpanded = !_themeExpanded;
                      if (_themeExpanded) _languageExpanded = false;
                    });
                  },
                  options: [
                    _InlineOption(
                      value: ThemeMode.system,
                      label: l10n.system,
                    ),
                    _InlineOption(
                      value: ThemeMode.light,
                      label: l10n.light,
                    ),
                    _InlineOption(
                      value: ThemeMode.dark,
                      label: l10n.dark,
                    ),
                  ],
                  selectedValue: appTheme,
                  onSelected: (mode) async {
                    await SfinityApp.themeManager.setThemeMode(mode);
                    if (mounted) {
                      setState(() => _themeExpanded = false);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                backgroundColor: cardColor,
                borderColor: borderColor,
                child: _ExpandableSettingsSection<String>(
                  icon: Icons.language_rounded,
                  iconBackground: isDark
                      ? const Color(0xFF213C48)
                      : const Color(0xFFEAF8FF),
                  iconColor: isDark
                      ? const Color(0xFF7DD3FC)
                      : const Color(0xFF2C89B8),
                  title: l10n.language,
                  value: _localeLabel(context, locale),
                  expanded: _languageExpanded,
                  onTap: () {
                    setState(() {
                      _languageExpanded = !_languageExpanded;
                      if (_languageExpanded) _themeExpanded = false;
                    });
                  },
                  options: [
                    _InlineOption(
                      value: 'vi',
                      label: l10n.vietnamese,
                    ),
                    _InlineOption(
                      value: 'en',
                      label: l10n.english,
                    ),
                  ],
                  selectedValue: locale.languageCode,
                  onSelected: (code) async {
                    await SfinityApp.localeManager.setLocale(Locale(code));
                    if (mounted) {
                      setState(() => _languageExpanded = false);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _themeLabel(BuildContext context, ThemeMode mode) {
    final l10n = context.l10n;
    switch (mode) {
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.system:
        return l10n.system;
    }
  }

  String _localeLabel(BuildContext context, Locale locale) {
    final l10n = context.l10n;
    switch (locale.languageCode) {
      case 'en':
        return l10n.english;
      case 'vi':
      default:
        return l10n.vietnamese;
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _ExpandableSettingsSection<T> extends StatelessWidget {
  const _ExpandableSettingsSection({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.expanded,
    required this.onTap,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String value;
  final bool expanded;
  final VoidCallback onTap;
  final List<_InlineOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _TileIcon(
                  icon: icon,
                  backgroundColor: iconBackground,
                  iconColor: iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 10),
                ...options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _InlineSelectionTile(
                      label: option.label,
                      selected: selectedValue == option.value,
                      onTap: () => onSelected(option.value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}

class _InlineOption<T> {
  const _InlineOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _InlineSelectionTile extends StatelessWidget {
  const _InlineSelectionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.12)
          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? cs.primary : cs.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.iconBackground,
    required this.iconColor,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Color iconBackground;
  final Color iconColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _TileIcon(
            icon: Icons.notifications_none_rounded,
            backgroundColor: iconBackground,
            iconColor: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.88,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 18,
      ),
    );
  }
}
