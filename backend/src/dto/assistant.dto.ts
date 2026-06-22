import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class AssistantHistoryItemDto {
  @IsIn(['user', 'assistant'])
  role!: 'user' | 'assistant';

  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  content!: string;
}

export class AssistantLocationDto {
  @IsNumber()
  lat!: number;

  @IsNumber()
  lng!: number;
}

export class AssistantChatDto {
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  message!: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  context?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => AssistantLocationDto)
  location?: AssistantLocationDto;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => AssistantHistoryItemDto)
  history?: AssistantHistoryItemDto[];
}
