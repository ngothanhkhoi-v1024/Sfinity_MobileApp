class PlaceWeatherModel {
  const PlaceWeatherModel({
    required this.temperatureC,
    required this.humidity,
    required this.description,
    required this.provider,
  });

  final double temperatureC;
  final int humidity;
  final String description;
  final String provider;

  factory PlaceWeatherModel.fromJson(Map<String, dynamic> json) {
    return PlaceWeatherModel(
      temperatureC: (json['temperatureC'] as num).toDouble(),
      humidity: (json['humidity'] as num).round(),
      description: json['description'] as String? ?? '',
      provider: json['provider'] as String? ?? 'open-meteo',
    );
  }
}
