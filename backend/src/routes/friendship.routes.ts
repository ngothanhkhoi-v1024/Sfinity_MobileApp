import { Router } from 'express';

import { SendFriendRequestDto, RespondFriendRequestDto } from '../dto/friendship.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { friendshipService } from '../services/friendship.service';

export const friendshipRouter = Router();

// Tất cả routes đều yêu cầu auth
friendshipRouter.use(jwtAuthMiddleware);

/** Tìm kiếm người dùng để kết bạn */
friendshipRouter.get(
  '/search',
  asyncHandler(async (req, res) => {
    const q = (req.query.q as string) ?? '';
    res.json(await friendshipService.searchUsers(q, req.user!.sub));
  }),
);

/** Danh sách bạn bè */
friendshipRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json(await friendshipService.listFriends(req.user!.sub));
  }),
);

/** Lời mời đang chờ */
friendshipRouter.get(
  '/pending',
  asyncHandler(async (req, res) => {
    res.json(await friendshipService.listPendingRequests(req.user!.sub));
  }),
);

/** Lời mời đã gửi */
friendshipRouter.get(
  '/sent',
  asyncHandler(async (req, res) => {
    res.json(await friendshipService.listSentRequests(req.user!.sub));
  }),
);

/** Gửi lời mời kết bạn */
friendshipRouter.post(
  '/request',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(SendFriendRequestDto, req.body);
    res.status(201).json(await friendshipService.sendRequest(req.user!.sub, dto.addresseeId));
  }),
);

/** Chấp nhận / từ chối lời mời */
friendshipRouter.patch(
  '/:id/respond',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(RespondFriendRequestDto, req.body);
    res.json(
      await friendshipService.respondRequest(req.params.id, req.user!.sub, dto.action === 'accept'),
    );
  }),
);

/** Hủy kết bạn */
friendshipRouter.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json(await friendshipService.unfriend(req.user!.sub, req.params.id));
  }),
);
