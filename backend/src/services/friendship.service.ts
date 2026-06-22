import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { UserRole } from '../types/enums';
import { usersService } from './users.service';
import { vipLimitsService } from './vip-limits.service';

export const friendshipService = {
  /** Gửi lời mời kết bạn */
  async sendRequest(requesterId: string, addresseeId: string, role: UserRole = UserRole.USER) {
    if (requesterId === addresseeId) {
      throw new HttpError(400, 'Không thể gửi lời mời kết bạn cho chính mình.', 'Bad Request');
    }

    await vipLimitsService.assertCanAddFriend(requesterId, role);

    const db = getDb();
    const key1 = `${requesterId}_${addresseeId}`;
    const key2 = `${addresseeId}_${requesterId}`;

    // Kiểm tra xem đã có friendship chưa (cả hai chiều)
    const [doc1, doc2] = await Promise.all([
      db.collection('friendships').doc(key1).get(),
      db.collection('friendships').doc(key2).get(),
    ]);

    const existing = (doc1.exists ? doc1.data() : null) || (doc2.exists ? doc2.data() : null);

    if (existing) {
      if (existing.status === 'ACCEPTED') throw new HttpError(409, 'Hai người đã là bạn bè.', 'Conflict');
      if (existing.status === 'PENDING') throw new HttpError(409, 'Lời mời kết bạn đã được gửi trước đó.', 'Conflict');
      if (existing.status === 'BLOCKED') throw new HttpError(403, 'Không thể gửi lời mời kết bạn.', 'Forbidden');
    }

    // Kiểm tra người được mời tồn tại
    const addresseeDoc = await db.collection('users').doc(addresseeId).get();
    if (!addresseeDoc.exists) throw new HttpError(404, 'Người dùng không tồn tại.', 'Not Found');
    const addresseeData = addresseeDoc.data()!;

    const friendshipId = key1; // Default key requester_addressee
    const now = new Date();
    const newFriendship = {
      id: friendshipId,
      requesterId,
      addresseeId,
      status: 'PENDING',
      createdAt: now,
      updatedAt: now,
    };

    await db.collection('friendships').doc(friendshipId).set(newFriendship);

    return {
      ...newFriendship,
      addressee: {
        id: addresseeDoc.id,
        name: addresseeData.name,
        avatar: addresseeData.avatar,
        email: addresseeData.email,
      },
    };
  },

  /** Chấp nhận hoặc từ chối lời mời */
  async respondRequest(
    friendshipId: string,
    userId: string,
    accept: boolean,
    role: UserRole = UserRole.USER,
  ) {
    const db = getDb();
    const ref = db.collection('friendships').doc(friendshipId);
    const doc = await ref.get();
    if (!doc.exists) throw new HttpError(404, 'Lời mời kết bạn không tồn tại.', 'Not Found');
    
    const friendship = doc.data()!;
    if (friendship.addresseeId !== userId) throw new HttpError(403, 'Không có quyền phản hồi lời mời này.', 'Forbidden');
    if (friendship.status !== 'PENDING') throw new HttpError(409, 'Lời mời đã được xử lý.', 'Conflict');

    if (accept) {
      await vipLimitsService.assertCanAddFriend(userId, role);
      await vipLimitsService.assertCanAddFriend(friendship.requesterId as string);
      const updated = { status: 'ACCEPTED', updatedAt: new Date() };
      await ref.update(updated);
      return { ...friendship, ...updated };
    } else {
      await ref.delete();
      return { success: true };
    }
  },

  /** Danh sách bạn bè đã chấp nhận */
  async listFriends(userId: string) {
    const db = getDb();
    const [reqSnap, addSnap] = await Promise.all([
      db.collection('friendships')
        .where('status', '==', 'ACCEPTED')
        .where('requesterId', '==', userId)
        .get(),
      db.collection('friendships')
        .where('status', '==', 'ACCEPTED')
        .where('addresseeId', '==', userId)
        .get(),
    ]);

    const list = [...reqSnap.docs, ...addSnap.docs].map((d) => d.data()!);

    const friends = await Promise.all(
      list.map(async (f) => {
        const friendId = f.requesterId === userId ? f.addresseeId : f.requesterId;
        const fDoc = await db.collection('users').doc(friendId).get();
        const fData = fDoc.exists ? fDoc.data() : null;
        return {
          friendshipId: f.id,
          user: {
            id: friendId,
            name: fData?.name ?? 'Unknown',
            avatar: fData?.avatar ?? null,
            email: fData?.email ?? '',
            gender: fData?.gender ?? '',
            birthDate: fData?.birthDate ?? '',
            address: fData?.address ?? '',
            friendshipStatus: 'ACCEPTED',
            friendshipId: f.id,
          },
          since: f.updatedAt ? (f.updatedAt.toDate ? f.updatedAt.toDate() : new Date(f.updatedAt)) : new Date(),
        };
      })
    );

    return friends;
  },

  /** Lời mời đang chờ gửi đến tôi */
  async listPendingRequests(userId: string) {
    const db = getDb();
    const snap = await db.collection('friendships')
      .where('addresseeId', '==', userId)
      .where('status', '==', 'PENDING')
      .get();

    const list = snap.docs.map((d) => d.data()!);

    const requests = await Promise.all(
      list.map(async (f) => {
        const rDoc = await db.collection('users').doc(f.requesterId).get();
        const rData = rDoc.exists ? rDoc.data() : null;
        return {
          id: f.id,
          requesterId: f.requesterId,
          addresseeId: f.addresseeId,
          status: f.status,
          createdAt: f.createdAt ? (f.createdAt.toDate ? f.createdAt.toDate() : new Date(f.createdAt)) : new Date(),
          updatedAt: f.updatedAt ? (f.updatedAt.toDate ? f.updatedAt.toDate() : new Date(f.updatedAt)) : new Date(),
          requester: {
            id: f.requesterId,
            name: rData?.name ?? 'Unknown',
            avatar: rData?.avatar ?? null,
            email: rData?.email ?? '',
            gender: rData?.gender ?? '',
            birthDate: rData?.birthDate ?? '',
            address: rData?.address ?? '',
            friendshipStatus: 'PENDING',
            friendshipId: f.id,
          },
        };
      })
    );

    return requests;
  },

  /** Lời mời kết bạn do tôi gửi đi đang chờ phản hồi */
  async listSentRequests(userId: string) {
    const db = getDb();
    const snap = await db.collection('friendships')
      .where('requesterId', '==', userId)
      .where('status', '==', 'PENDING')
      .get();

    const list = snap.docs.map((d) => d.data()!);

    const requests = await Promise.all(
      list.map(async (f) => {
        const aDoc = await db.collection('users').doc(f.addresseeId).get();
        const aData = aDoc.exists ? aDoc.data() : null;
        return {
          id: f.id,
          requesterId: f.requesterId,
          addresseeId: f.addresseeId,
          status: f.status,
          createdAt: f.createdAt ? (f.createdAt.toDate ? f.createdAt.toDate() : new Date(f.createdAt)) : new Date(),
          updatedAt: f.updatedAt ? (f.updatedAt.toDate ? f.updatedAt.toDate() : new Date(f.updatedAt)) : new Date(),
          addressee: {
            id: f.addresseeId,
            name: aData?.name ?? 'Unknown',
            avatar: aData?.avatar ?? null,
            email: aData?.email ?? '',
            gender: aData?.gender ?? '',
            birthDate: aData?.birthDate ?? '',
            address: aData?.address ?? '',
            friendshipStatus: 'PENDING',
            friendshipId: f.id,
          },
        };
      })
    );

    return requests;
  },

  /** Hủy kết bạn (hoặc thu hồi lời mời) */
  async unfriend(userId: string, targetId: string) {
    const db = getDb();
    
    // Thử tìm kiếm theo targetId là friendshipId trước
    let fDoc = await db.collection('friendships').doc(targetId).get();
    
    // Nếu không tìm thấy, thử tìm kiếm theo userId và targetId là userId của bạn bè
    if (!fDoc.exists) {
      const key1 = `${userId}_${targetId}`;
      const key2 = `${targetId}_${userId}`;
      const [doc1, doc2] = await Promise.all([
        db.collection('friendships').doc(key1).get(),
        db.collection('friendships').doc(key2).get(),
      ]);
      fDoc = doc1.exists ? doc1 : (doc2.exists ? doc2 : fDoc);
    }

    if (!fDoc.exists) {
      throw new HttpError(404, 'Không có quan hệ bạn bè.', 'Not Found');
    }

    const data = fDoc.data()!;
    if (data.requesterId !== userId && data.addresseeId !== userId) {
      throw new HttpError(403, 'Không có quyền thực hiện thao tác này.', 'Forbidden');
    }

    await fDoc.ref.delete();
    return { success: true };
  },

  /** Tìm kiếm người dùng để kết bạn */
  async searchUsers(query: string, currentUserId: string) {
    if (!query || query.trim().length < 2) return [];

    const db = getDb();
    const users = await usersService.findAll(query);
    const filteredUsers = users.filter((u) => u.id !== currentUserId).slice(0, 20);

    // Annotate với friendship status
    const [reqSnap, addSnap] = await Promise.all([
      db.collection('friendships').where('requesterId', '==', currentUserId).get(),
      db.collection('friendships').where('addresseeId', '==', currentUserId).get(),
    ]);

    const friendships = [...reqSnap.docs, ...addSnap.docs].map((d) => d.data()!);

    return filteredUsers.map((u) => {
      const rel = friendships.find(
        (f) => f.requesterId === u.id || f.addresseeId === u.id,
      );
      return {
        id: u.id,
        name: u.name,
        avatar: u.avatar,
        email: u.email,
        gender: (u as any).gender ?? '',
        birthDate: (u as any).birthDate ?? '',
        address: (u as any).address ?? '',
        friendshipStatus: rel?.status ?? null,
        friendshipId: rel?.id ?? null,
      };
    });
  },
};
