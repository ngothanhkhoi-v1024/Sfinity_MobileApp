import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import type { CreateFeedbackDto, ReplyFeedbackDto } from '../dto/feedback.dto';
import { notificationsService } from './notifications.service';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const feedbackService = {
  async findAll(resolved?: boolean) {
    let query: any = getDb().collection('feedbacks');
    if (resolved !== undefined) {
      query = query.where('resolved', '==', resolved);
    }

    const snapshot = await query.get();
    const list = snapshot.docs.map((doc: any) => ({ id: doc.id, ...doc.data() } as any));

    // Sort desc by createdAt in memory
    list.sort((a: any, b: any) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    const resolvedList = await Promise.all(
      list.map(async (item: any) => {
        let user = null;
        if (item.userId) {
          const userDoc = await getDb().collection('users').doc(item.userId).get();
          if (userDoc.exists) {
            const u = userDoc.data() as any;
            user = { id: userDoc.id, name: u.name, email: u.email };
          }
        }
        return {
          id: item.id,
          userId: item.userId,
          message: item.message,
          rating: item.rating ?? null,
          resolved: item.resolved ?? false,
          reply: item.reply ?? null,
          createdAt: toDate(item.createdAt),
          updatedAt: toDate(item.updatedAt),
          user,
        };
      }),
    );

    return resolvedList;
  },

  async create(userId: string, dto: CreateFeedbackDto) {
    const docRef = getDb().collection('feedbacks').doc();
    const feedback = {
      id: docRef.id,
      userId,
      message: dto.message,
      rating: dto.rating ?? null,
      resolved: false,
      reply: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await docRef.set(feedback);
    
    return {
      ...feedback,
      createdAt: toDate(feedback.createdAt),
      updatedAt: toDate(feedback.updatedAt),
    };
  },

  async reply(id: string, dto: ReplyFeedbackDto) {
    const feedback = await feedbackService.findOne(id); // Throws if not found
    const ref = getDb().collection('feedbacks').doc(id);

    await ref.update({
      reply: dto.reply,
      resolved: true,
      updatedAt: new Date(),
    });

    if (feedback.userId) {
      await notificationsService.create({
        userId: feedback.userId,
        title: 'Phản hồi của quản trị viên',
        body: `Quản trị viên đã trả lời phản hồi của bạn: ${dto.reply}`,
      });
    }

    return feedbackService.findOne(id);
  },

  async resolve(id: string) {
    await feedbackService.findOne(id); // Throws if not found
    const ref = getDb().collection('feedbacks').doc(id);

    await ref.update({
      resolved: true,
      updatedAt: new Date(),
    });

    return feedbackService.findOne(id);
  },

  async findOne(id: string) {
    const doc = await getDb().collection('feedbacks').doc(id).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }
    const item = { id: doc.id, ...doc.data() } as any;

    let user = null;
    if (item.userId) {
      const userDoc = await getDb().collection('users').doc(item.userId).get();
      if (userDoc.exists) {
        const u = userDoc.data() as any;
        user = { id: userDoc.id, name: u.name, email: u.email };
      }
    }

    return {
      id: item.id,
      userId: item.userId,
      message: item.message,
      rating: item.rating ?? null,
      resolved: item.resolved ?? false,
      reply: item.reply ?? null,
      createdAt: toDate(item.createdAt),
      updatedAt: toDate(item.updatedAt),
      user,
    };
  },
};
