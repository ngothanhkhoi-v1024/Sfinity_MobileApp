import { UserRole } from '../types/enums';
import { Router } from 'express';

import { CreateFeedbackDto, ReplyFeedbackDto } from '../dto/feedback.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { feedbackService } from '../services/feedback.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const feedbackRouter = Router();

feedbackRouter.post(
  '/',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateFeedbackDto, req.body);
    res.json(await feedbackService.create(req.user!.sub, dto));
  }),
);

feedbackRouter.get(
  '/',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const resolved = req.query.resolved as string | undefined;
    const filter =
      resolved === 'true' ? true : resolved === 'false' ? false : undefined;
    res.json(await feedbackService.findAll(filter));
  }),
);

feedbackRouter.patch(
  '/:id/reply',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(ReplyFeedbackDto, req.body);
    res.json(await feedbackService.reply(req.params.id, dto));
  }),
);

feedbackRouter.patch(
  '/:id/resolve',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(await feedbackService.resolve(req.params.id));
  }),
);
