import { IsInt, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class CreateFeedbackDto {
  @IsString()
  @MinLength(5)
  message!: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  rating?: number;
}

export class ReplyFeedbackDto {
  @IsString()
  @MinLength(2)
  reply!: string;
}
