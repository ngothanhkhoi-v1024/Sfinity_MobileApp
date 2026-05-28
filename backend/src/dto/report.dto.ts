import { ReportStatus } from '../types/enums';
import { IsEnum, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateReportDto {
  @IsString()
  @MinLength(2)
  targetType!: string;

  @IsOptional()
  @IsString()
  targetId?: string;

  @IsString()
  @MinLength(2)
  reason!: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class ResolveReportDto {
  @IsEnum(ReportStatus)
  status!: ReportStatus;

  @IsOptional()
  @IsString()
  resolution?: string;
}
