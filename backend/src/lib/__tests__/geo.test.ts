import { distanceMeters } from '../geo';

describe('geo - distanceMeters', () => {
  it('should return 0 meters for the same point', () => {
    const lat = 10.762622;
    const lon = 106.660172;
    const dist = distanceMeters(lat, lon, lat, lon);
    expect(dist).toBeCloseTo(0, 1);
  });

  it('should compute distance correctly between two different points', () => {
    const dist = distanceMeters(21.028511, 105.804817, 10.762622, 106.660172);
    expect(dist).toBeGreaterThan(1130000);
    expect(dist).toBeLessThan(1150000);
  });
});
