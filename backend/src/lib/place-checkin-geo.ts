/** Check-in geofence: distance <= max(50m, GPS accuracy), accuracy <= 50m. */
export const PLACE_CHECKIN_MAX_ACCURACY_M = 50;
export const PLACE_CHECKIN_BASE_RADIUS_M = 50;

export function checkInAllowedRadiusM(accuracyM: number): number {
  return Math.max(PLACE_CHECKIN_BASE_RADIUS_M, accuracyM);
}

export function isWithinCheckInRadius(
  distanceM: number,
  accuracyM: number,
): boolean {
  if (!Number.isFinite(accuracyM) || accuracyM <= 0) return false;
  if (accuracyM > PLACE_CHECKIN_MAX_ACCURACY_M) return false;
  return distanceM <= checkInAllowedRadiusM(accuracyM);
}
