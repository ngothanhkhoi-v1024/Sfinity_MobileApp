import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import type { CreateNotificationDto } from '../dto/notification.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const notificationsService = {
  async findByUser(userId: string) {
    const snapshot = await getDb()
      .collection('notifications')
      .where('userId', '==', userId)
      .get();

    const list = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));
    
    // Sort desc by createdAt in memory
    list.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    return list.map((item) => ({
      id: item.id,
      userId: item.userId,
      title: item.title,
      body: item.body,
      read: item.read ?? false,
      createdAt: toDate(item.createdAt),
    }));
  },

  async markRead(userId: string, id: string) {
    const docRef = getDb().collection('notifications').doc(id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data()?.userId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    await docRef.update({ read: true });
    const updated = await docRef.get();
    const data = updated.data() as any;

    return {
      id: updated.id,
      userId: data.userId,
      title: data.title,
      body: data.body,
      read: data.read ?? true,
      createdAt: toDate(data.createdAt),
    };
  },

  async markAllRead(userId: string) {
    const snapshot = await getDb()
      .collection('notifications')
      .where('userId', '==', userId)
      .where('read', '==', false)
      .get();

    if (!snapshot.empty) {
      const batch = getDb().batch();
      snapshot.docs.forEach((doc) => {
        batch.update(doc.ref, { read: true });
      });
      await batch.commit();
    }

    return { success: true };
  },

  async create(dto: CreateNotificationDto) {
    if (dto.userId) {
      const docRef = getDb().collection('notifications').doc();
      const notif = {
        id: docRef.id,
        userId: dto.userId,
        title: dto.title,
        body: dto.body,
        read: false,
        createdAt: new Date(),
      };
      await docRef.set(notif);
      return notif;
    }

    // Fetch all active standard users
    const usersSnap = await getDb()
      .collection('users')
      .where('role', '==', 'USER')
      .where('status', '==', 'ACTIVE')
      .get();

    if (usersSnap.empty) {
      return { sent: 0 };
    }

    // Write in batch (chunk to 400 docs per batch to stay under the Firestore 500 limit)
    const docs = usersSnap.docs;
    const chunkSize = 400;
    for (let i = 0; i < docs.length; i += chunkSize) {
      const chunk = docs.slice(i, i + chunkSize);
      const batch = getDb().batch();
      
      chunk.forEach((userDoc) => {
        const notifRef = getDb().collection('notifications').doc();
        batch.set(notifRef, {
          id: notifRef.id,
          userId: userDoc.id,
          title: dto.title,
          body: dto.body,
          read: false,
          createdAt: new Date(),
        });
      });
      
      await batch.commit();
    }

    return { sent: docs.length };
  },

  async findAllAdmin() {
    const snapshot = await getDb().collection('notifications').get();
    const list = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));
    
    // Sort desc by createdAt in memory
    list.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    const slice = list.slice(0, 100);

    const resolved = await Promise.all(
      slice.map(async (notif) => {
        let user = null;
        if (notif.userId) {
          const userDoc = await getDb().collection('users').doc(notif.userId).get();
          if (userDoc.exists) {
            const u = userDoc.data() as any;
            user = { id: userDoc.id, name: u.name, email: u.email };
          }
        }
        return {
          id: notif.id,
          userId: notif.userId,
          title: notif.title,
          body: notif.body,
          read: notif.read ?? false,
          createdAt: toDate(notif.createdAt),
          user,
        };
      }),
    );

    return resolved;
  },
};
