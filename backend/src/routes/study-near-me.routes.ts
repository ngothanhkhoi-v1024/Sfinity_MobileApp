import { Router } from 'express';

import { asyncHandler } from '../lib/async-handler';
import { HttpError } from '../lib/http-error';
import { studyNearMeService } from '../services/study-near-me.service';

export const studyNearMeRouter = Router();

studyNearMeRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const lat = req.query.lat != null ? Number(req.query.lat) : NaN;
    const lng = req.query.lng != null ? Number(req.query.lng) : NaN;
    const radiusKm =
      req.query.radiusKm != null ? Number(req.query.radiusKm) : undefined;
    const limit = req.query.limit != null ? Number(req.query.limit) : undefined;

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      throw new HttpError(400, 'Cần tham số lat và lng hợp lệ', 'Bad Request');
    }

    res.json(await studyNearMeService.findNearby({ lat, lng, radiusKm, limit }));
  }),
);
