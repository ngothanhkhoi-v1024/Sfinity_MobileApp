import { IsOptional, IsString, IsUrl, MinLength } from 'class-validator';

export class CreatePlacePhotoDto {
  @IsString()
  @IsUrl({ require_protocol: true })
  imageUrl!: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  caption?: string;
}
