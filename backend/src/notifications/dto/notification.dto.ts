import { IsOptional, IsString, MinLength } from 'class-validator';

export class CreateNotificationDto {
  @IsString()
  @MinLength(2)
  title!: string;

  @IsString()
  @MinLength(2)
  body!: string;

  @IsOptional()
  @IsString()
  userId?: string;
}
