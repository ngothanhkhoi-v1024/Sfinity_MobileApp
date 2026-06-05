import { Router } from 'express';

import { AssistantChatDto } from '../dto/assistant.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { assistantService } from '../services/assistant.service';

export const assistantRouter = Router();

assistantRouter.post(
  '/chat',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(AssistantChatDto, req.body);
    res.json(await assistantService.chat(req.user!.sub, dto));
  }),
);
