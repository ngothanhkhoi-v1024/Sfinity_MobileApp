import { IsOptional, IsString, MinLength } from 'class-validator';

export class AdminHideDto {
  @IsString()
  @MinLength(2)
  reason!: string;
}

export class AdminDeleteDto {
  @IsString()
  @MinLength(2)
  reason!: string;
}

export class AdminUnhideDto {
  @IsOptional()
  @IsString()
  note?: string;
}
