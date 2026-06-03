import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';

final Map<String, Uint8List> _avatarCache = {};

Future<Uint8List?> _tryFetchAvatar(String url) async {
  if (_avatarCache.containsKey(url)) {
    return _avatarCache[url];
  }
  try {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null || response.data!.isEmpty) return null;
    final bytes = Uint8List.fromList(response.data!);
    _avatarCache[url] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

class ViewProfilePage extends StatelessWidget {
  const ViewProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: SfinityApp.auth,
      builder: (context, _) {
        final user = SfinityApp.auth.user;
        final avatarUrl = user?['avatar']?.toString();
        final displayName = user?['name']?.toString() ?? '';
        final email = user?['email']?.toString() ?? '';
        final gender = user?['gender']?.toString();
        final birthDate = user?['birthDate']?.toString();
        final address = user?['address']?.toString();

        String formattedBirthDate;
        if (birthDate != null && birthDate.isNotEmpty) {
          final parts = birthDate.split('-');
          if (parts.length == 3) {
            formattedBirthDate = '${parts[2]}/${parts[1]}/${parts[0]}';
          } else {
            formattedBirthDate = birthDate;
          }
        } else {
          formattedBirthDate = '';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).viewProfile),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: _AvatarWidget(
                  avatarUrl: avatarUrl,
                  displayName: displayName,
                  size: 112,
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Center(
                child: Text(
                  displayName.isNotEmpty ? displayName : '—',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Center(
                child: Text(
                  email.isNotEmpty ? email : '—',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Info cards
              _InfoCard(isDark: isDark, children: [
                _InfoRow(
                  context: context,
                  icon: Icons.wc_outlined,
                  label: context.l10n.gender,
                  value: gender != null && gender.isNotEmpty ? gender : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  context: context,
                  icon: Icons.cake_outlined,
                  label: context.l10n.dateOfBirth,
                  value: formattedBirthDate.isNotEmpty ? formattedBirthDate : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  context: context,
                  icon: Icons.location_on_outlined,
                  label: context.l10n.address,
                  value: address != null && address.isNotEmpty ? address : '—',
                  isDark: isDark,
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarWidget extends StatefulWidget {
  const _AvatarWidget({
    required this.avatarUrl,
    required this.displayName,
    required this.size,
  });

  final String? avatarUrl;
  final String displayName;
  final double size;

  @override
  State<_AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<_AvatarWidget> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.avatarUrl == null || widget.avatarUrl!.isEmpty) {
      setState(() => _bytes = null);
      return;
    }
    setState(() {
      _loading = true;
      _bytes = _avatarCache[widget.avatarUrl];
    });
    if (_bytes != null) {
      setState(() => _loading = false);
      return;
    }
    final bytes = await _tryFetchAvatar(widget.avatarUrl!);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_loading && _bytes == null) {
      content = Center(
        child: SizedBox(
          width: widget.size * 0.4,
          height: widget.size * 0.4,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
      );
    } else {
      content = _buildPlaceholder(theme);
    }

    return ClipOval(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: content,
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          widget.displayName.isNotEmpty
              ? widget.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: widget.size * 0.36,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.context,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final BuildContext context;
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = value != '—'
        ? (isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1F2937))
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
