import { IsEnum, IsOptional, IsString, MinLength } from 'class-validator';

export enum CategoryType {
  DOCUMENT = 'DOCUMENT',
  PLACE = 'PLACE',
}

export class CreateCategoryDto {
  @IsString()
  @MinLength(2)
  name!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsEnum(CategoryType)
  type?: CategoryType;
}

export class UpdateCategoryDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;
}

