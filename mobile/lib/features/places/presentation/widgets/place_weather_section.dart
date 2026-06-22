import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/place_weather_model.dart';
import '../../data/services/place_api_service.dart';

class PlaceWeatherSection extends StatefulWidget {
  const PlaceWeatherSection({
    super.key,
    required this.placeId,
    required this.isDark,
  });

  final String placeId;
  final bool isDark;

  @override
  State<PlaceWeatherSection> createState() => _PlaceWeatherSectionState();
}

class _PlaceWeatherSectionState extends State<PlaceWeatherSection> {
  static const _beigeLight = Color(0xFFF8F4EE);
  static const _beigeDark = Color(0xFF2A2824);

  final _api = PlaceApiService(ApiClient.instance);

  bool _loading = true;
  PlaceWeatherModel? _weather;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final json = await _api.getPlaceWeather(widget.placeId);
      if (!mounted) return;
      setState(() {
        _weather = PlaceWeatherModel.fromJson(json);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (_loading) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_failed || _weather == null) {
      return const SizedBox.shrink();
    }

    final weather = _weather!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? _beigeDark : _beigeLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isDark ? Colors.white10 : const Color(0xFFE8E0D4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            color: Colors.orange.shade600,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.placeWeatherToday,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.placeWeatherHumidity(weather.humidity),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            l10n.placeWeatherTemperature(weather.temperatureC),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
