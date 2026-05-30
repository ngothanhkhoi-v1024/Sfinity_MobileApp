import { Router } from 'express';

import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { authService } from '../services/auth.service';
import { LoginDto, RegisterDto } from '../dto/login.dto';
import { FirebaseLoginDto } from '../dto/firebase-login.dto';
import {
  ChangePasswordDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  UpdateNotificationPreferencesDto,
  UpdateProfileDto,
} from '../dto/password.dto';

export const authRouter = Router();

authRouter.post(
  '/login',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(LoginDto, req.body);
    res.json(await authService.login(dto));
  }),
);

authRouter.post(
  '/firebase-login',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(FirebaseLoginDto, req.body);
    res.json(await authService.loginWithFirebase(dto));
  }),
);

authRouter.post(
  '/admin/login',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(LoginDto, req.body);
    res.json(await authService.login(dto, true));
  }),
);

authRouter.post(
  '/register',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(RegisterDto, req.body);
    res.json(await authService.register(dto));
  }),
);

authRouter.post(
  '/forgot-password',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(ForgotPasswordDto, req.body);
    res.json(await authService.forgotPassword(dto));
  }),
);

authRouter.post(
  '/reset-password',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(ResetPasswordDto, req.body);
    res.json(await authService.resetPassword(dto));
  }),
);

authRouter.get(
  '/me',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(await authService.getProfile(req.user!.sub));
  }),
);

authRouter.patch(
  '/profile',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateProfileDto, req.body);
    res.json(await authService.updateProfile(req.user!.sub, dto));
  }),
);

authRouter.patch(
  '/notification-preferences',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateNotificationPreferencesDto, req.body);
    res.json(await authService.updateNotificationPreferences(req.user!.sub, dto));
  }),
);

authRouter.post(
  '/change-password',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(ChangePasswordDto, req.body);
    res.json(await authService.changePassword(req.user!.sub, dto));
  }),
);