import { Router } from 'express';

import { PLACE_ZONES } from '../constants/place-zones';
import { CreatePlaceCheckInDto } from '../dto/place-checkin.dto';
import { CreatePlacePhotoDto } from '../dto/place-photo.dto';
import { CreatePlaceReviewDto } from '../dto/place-review.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware, optionalJwtAuthMiddleware } from '../middleware/jwt.middleware';
import { placeCheckInService } from '../services/place-checkin.service';
import { placePhotoService } from '../services/place-photo.service';
import { placeReviewService } from '../services/place-review.service';

export const placesRouter = Router();

placesRouter.get(
  '/zones',
  asyncHandler(async (_req, res) => {
    res.json({ zones: PLACE_ZONES });
  }),
);

placesRouter.get(
  '/:placeId/check-ins/status',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await placeCheckInService.getStatus(
        req.params.placeId,
        req.user?.sub,
      ),
    );
  }),
);

placesRouter.post(
  '/:placeId/check-ins',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreatePlaceCheckInDto, req.body);
    res.status(201).json(
      await placeCheckInService.checkIn(
        req.params.placeId,
        req.user!.sub,
        dto,
      ),
    );
  }),
);

placesRouter.get(
  '/:placeId/reviews',
  asyncHandler(async (req, res) => {
    res.json(await placeReviewService.list(req.params.placeId));
  }),
);

placesRouter.post(
  '/:placeId/reviews',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreatePlaceReviewDto, req.body);
    res.json(
      await placeReviewService.upsert(req.params.placeId, req.user!.sub, dto),
    );
  }),
);

placesRouter.get(
  '/:placeId/photos',
  asyncHandler(async (req, res) => {
    res.json(await placePhotoService.list(req.params.placeId));
  }),
);

placesRouter.post(
  '/:placeId/photos',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreatePlacePhotoDto, req.body);
    res.json(
      await placePhotoService.create(req.params.placeId, req.user!.sub, dto),
    );
  }),
);

placesRouter.delete(
  '/:placeId/photos/:photoId',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await placePhotoService.remove(
        req.params.photoId,
        req.user!.sub,
        req.user!.role,
      ),
    );
  }),
);
