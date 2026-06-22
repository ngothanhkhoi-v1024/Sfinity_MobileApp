import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { UserRole } from '../types/enums';
import { planSettingsService } from './plan-settings.service';
import { subscriptionService } from './subscription.service';

type UsageField = 'documentDownloads' | 'placesCreated';

export interface LimitBucket {
  used: number;
  limit: number | null;
  remaining: number | null;
}

export interface UserLimitsStatus {
  isVip: boolean;
  documentDownloads: LimitBucket;
  placesCreated: LimitBucket;
  friends: LimitBucket;
  canCreateGroup: boolean;
}

async function isVipUser(userId: string, role?: UserRole): Promise<boolean> {
  if (role === UserRole.ADMIN) return true;
  const status = await subscriptionService.getUserVipStatus(userId);
  return status.isVip;
}

async function countFriends(userId: string): Promise<number> {
  const db = getDb();
  const [reqSnap, addSnap] = await Promise.all([
    db
      .collection('friendships')
      .where('status', '==', 'ACCEPTED')
      .where('requesterId', '==', userId)
      .get(),
    db
      .collection('friendships')
      .where('status', '==', 'ACCEPTED')
      .where('addresseeId', '==', userId)
      .get(),
  ]);
  return reqSnap.size + addSnap.size;
}

async function getUsageCount(userId: string, field: UsageField): Promise<number> {
  const userRef = getDb().collection('users').doc(userId);
  const snap = await userRef.get();
  const data = snap.data();
  const stored = data?.usage?.[field];
  if (typeof stored === 'number') return stored;

  let count = 0;
  if (field === 'documentDownloads') {
    const logs = await getDb()
      .collection('document_download_logs')
      .where('userId', '==', userId)
      .get();
    count = logs.size;
  } else {
    const places = await getDb()
      .collection('places')
      .where('authorId', '==', userId)
      .get();
    count = places.size;
  }

  await userRef.set(
    { usage: { ...(data?.usage ?? {}), [field]: count } },
    { merge: true },
  );
  return count;
}

function buildBucket(used: number, limit: number | null): LimitBucket {
  if (limit == null) {
    return { used, limit: null, remaining: null };
  }
  return {
    used,
    limit,
    remaining: Math.max(0, limit - used),
  };
}

export const vipLimitsService = {
  async getStatus(userId: string, role?: UserRole): Promise<UserLimitsStatus> {
    const vip = await isVipUser(userId, role);
    const freeLimits = await planSettingsService.getFreeLimits();
    const [downloads, places, friends] = await Promise.all([
      getUsageCount(userId, 'documentDownloads'),
      getUsageCount(userId, 'placesCreated'),
      countFriends(userId),
    ]);

    const downloadsLimit = vip ? null : freeLimits.documentDownloads;
    const placesLimit = vip ? null : freeLimits.placesCreated;
    const friendsLimit = vip ? null : freeLimits.friends;

    return {
      isVip: vip,
      documentDownloads: buildBucket(downloads, downloadsLimit),
      placesCreated: buildBucket(places, placesLimit),
      friends: buildBucket(friends, friendsLimit),
      canCreateGroup: vip || freeLimits.canCreateGroup,
    };
  },

  async assertCanDownload(userId: string, role?: UserRole): Promise<void> {
    if (await isVipUser(userId, role)) return;
    const freeLimits = await planSettingsService.getFreeLimits();
    const used = await getUsageCount(userId, 'documentDownloads');
    if (used >= freeLimits.documentDownloads) {
      throw new HttpError(
        403,
        `Bạn đã hết lượt tải tài liệu (${freeLimits.documentDownloads}/${freeLimits.documentDownloads}). Nâng cấp VIP để tải không giới hạn.`,
        'Forbidden',
      );
    }
  },

  async assertCanCreatePlace(userId: string, role?: UserRole): Promise<void> {
    if (role === UserRole.ADMIN || (await isVipUser(userId, role))) return;
    const freeLimits = await planSettingsService.getFreeLimits();
    const used = await getUsageCount(userId, 'placesCreated');
    if (used >= freeLimits.placesCreated) {
      throw new HttpError(
        403,
        `Bạn đã hết lượt đăng địa điểm (${freeLimits.placesCreated}/${freeLimits.placesCreated}). Nâng cấp VIP để đăng không giới hạn.`,
        'Forbidden',
      );
    }
  },

  async assertCanCreateGroup(userId: string, role?: UserRole): Promise<void> {
    if (role === UserRole.ADMIN || (await isVipUser(userId, role))) return;
    const freeLimits = await planSettingsService.getFreeLimits();
    if (!freeLimits.canCreateGroup) {
      throw new HttpError(
        403,
        'Tài khoản thường không thể tạo nhóm. Bạn có thể tham gia nhóm công khai hoặc nâng cấp VIP.',
        'Forbidden',
      );
    }
  },

  async assertCanAddFriend(userId: string, role?: UserRole): Promise<void> {
    if (role === UserRole.ADMIN || (await isVipUser(userId, role))) return;
    const freeLimits = await planSettingsService.getFreeLimits();
    const used = await countFriends(userId);
    if (used >= freeLimits.friends) {
      throw new HttpError(
        403,
        `Bạn đã đạt giới hạn ${freeLimits.friends} bạn bè. Nâng cấp VIP để kết bạn không giới hạn.`,
        'Forbidden',
      );
    }
  },

  async recordDownload(userId: string): Promise<void> {
    const userRef = getDb().collection('users').doc(userId);
    const snap = await userRef.get();
    const usage = (snap.data()?.usage ?? {}) as Record<string, number>;
    const current =
      typeof usage.documentDownloads === 'number'
        ? usage.documentDownloads
        : await getUsageCount(userId, 'documentDownloads');
    await userRef.set(
      { usage: { ...usage, documentDownloads: current + 1 } },
      { merge: true },
    );
  },

  async recordPlaceCreated(userId: string): Promise<void> {
    const userRef = getDb().collection('users').doc(userId);
    const snap = await userRef.get();
    const usage = (snap.data()?.usage ?? {}) as Record<string, number>;
    const current =
      typeof usage.placesCreated === 'number'
        ? usage.placesCreated
        : await getUsageCount(userId, 'placesCreated');
    await userRef.set(
      { usage: { ...usage, placesCreated: current + 1 } },
      { merge: true },
    );
  },
};
