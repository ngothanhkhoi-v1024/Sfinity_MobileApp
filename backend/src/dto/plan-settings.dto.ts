import { IsBoolean, IsInt, IsObject, IsOptional, IsString, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class PlanConfigDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  nameVi?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  monthlyPrice?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  yearlyPrice?: number;

  @IsOptional()
  @IsBoolean()
  enabled?: boolean;
}

class FreeLimitsDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  documentDownloads?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  placesCreated?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  friends?: number;

  @IsOptional()
  @IsBoolean()
  canCreateGroup?: boolean;
}

export class UpdatePlanSettingsDto {
  @IsOptional()
  @IsObject()
  plans?: Record<string, PlanConfigDto>;

  @IsOptional()
  @ValidateNested()
  @Type(() => FreeLimitsDto)
  freeLimits?: FreeLimitsDto;
}
