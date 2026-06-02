class PlaceCheckInStatus {
  const PlaceCheckInStatus({
    required this.checkInCount,
    required this.hasCheckedIn,
    this.checkedInAt,
  });

  final int checkInCount;
  final bool hasCheckedIn;
  final DateTime? checkedInAt;

  factory PlaceCheckInStatus.fromJson(Map<String, dynamic> json) {
    DateTime? checkedInAt;
    final raw = json['checkedInAt'];
    if (raw != null) {
      checkedInAt = DateTime.tryParse(raw.toString());
    }
    return PlaceCheckInStatus(
      checkInCount: (json['checkInCount'] as num?)?.toInt() ?? 0,
      hasCheckedIn: json['hasCheckedIn'] == true,
      checkedInAt: checkedInAt,
    );
  }
}
