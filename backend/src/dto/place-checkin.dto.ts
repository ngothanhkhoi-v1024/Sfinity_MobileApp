import { IsNumber, Max, Min } from 'class-validator';

export class CreatePlaceCheckInDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude!: number;

  /** GPS horizontal accuracy in meters (from device). */
  @IsNumber()
  @Min(0.1)
  @Max(25)
  accuracy!: number;
}
