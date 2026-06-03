import { IsNotEmpty, IsString } from 'class-validator';

export class SendFriendRequestDto {
  @IsString()
  @IsNotEmpty()
  addresseeId!: string;
}

export class RespondFriendRequestDto {
  @IsString()
  @IsNotEmpty()
  action!: 'accept' | 'reject'; // 'accept' | 'reject'
}
