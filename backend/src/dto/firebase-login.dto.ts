import { IsIn, IsString, MinLength } from 'class-validator';

export class FirebaseLoginDto {
    @IsString()
    @MinLength(20)
    idToken!: string;

    @IsString()
    @IsIn(['google.com', 'facebook.com'])
    provider!: 'google.com' | 'facebook.com';
}