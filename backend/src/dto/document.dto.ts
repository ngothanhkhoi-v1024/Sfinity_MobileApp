import { ContentModerationStatus, ContentVisibility } from '../types/enums';
import { IsEnum, IsOptional, IsString, MinLength, IsNumber, IsArray } from 'class-validator';

export class CreateDocumentDto {
  @IsString()
  @MinLength(2)
  title!: string;

  @IsOptional()
  @IsString()
  body?: string;



  @IsOptional()
  @IsEnum(ContentVisibility)
  visibility?: ContentVisibility;

  @IsOptional()
  @IsEnum(ContentModerationStatus)
  moderationStatus?: ContentModerationStatus;

  @IsOptional()
  @IsString()
  categoryId?: string;



  // Document fields
  @IsOptional()
  @IsString()
  fileUrl?: string;

  @IsOptional()
  @IsString()
  fileType?: string;

  @IsOptional()
  @IsNumber()
  fileSize?: number;

  @IsOptional()
  @IsString()
  subjectCode?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })


  @IsOptional()
  @IsNumber()
  downloadsCount?: number;

  @IsOptional()
  @IsNumber()
  likesCount?: number;

  /** Liên kết tài liệu với địa điểm (id place). */
  @IsOptional()
  @IsString()
  placeId?: string;
}

export class UpdateDocumentDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  title?: string;

  @IsOptional()
  @IsString()
  body?: string | null;



  @IsOptional()
  @IsEnum(ContentVisibility)
  visibility?: ContentVisibility;

  @IsOptional()
  @IsEnum(ContentModerationStatus)
  moderationStatus?: ContentModerationStatus;

  @IsOptional()
  @IsString()
  categoryId?: string | null;



  // Document fields
  @IsOptional()
  @IsString()
  fileUrl?: string | null;

  @IsOptional()
  @IsString()
  fileType?: string | null;

  @IsOptional()
  @IsNumber()
  fileSize?: number | null;

  @IsOptional()
  @IsString()
  subjectCode?: string | null;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })


  @IsOptional()
  @IsNumber()
  downloadsCount?: number;

  @IsOptional()
  @IsNumber()
  likesCount?: number;

  /** Liên kết tài liệu với địa điểm. */
  @IsOptional()
  @IsString()
  placeId?: string | null;
}
