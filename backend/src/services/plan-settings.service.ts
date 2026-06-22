import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { FREE_USER_LIMITS } from '../constants/vip-limits';

const DOC_ID = 'subscription';

export interface PlanConfig {
  id: string;
  name: string;
  nameVi: string;
  monthlyPrice: number;
  yearlyPrice: number;
  enabled: boolean;
}

export interface FreeLimitsConfig {
  documentDownloads: number;
  placesCreated: number;
  friends: number;
  canCreateGroup: boolean;
}

export interface PlanSettings {
  plans: Record<string, PlanConfig>;
  freeLimits: FreeLimitsConfig;
  updatedAt?: Date;
}

const DEFAULT_PLANS: Record<string, PlanConfig> = {
  pro: {
    id: 'pro',
    name: 'VIP Pro',
    nameVi: 'VIP Pro',
    monthlyPrice: 49000,
    yearlyPrice: 399000,
    enabled: true,
  },
};

const DEFAULT_FREE_LIMITS: FreeLimitsConfig = {
  documentDownloads: FREE_USER_LIMITS.DOCUMENT_DOWNLOADS,
  placesCreated: FREE_USER_LIMITS.PLACES_CREATED,
  friends: FREE_USER_LIMITS.FRIENDS,
  canCreateGroup: false,
};

const defaults: PlanSettings = {
  plans: DEFAULT_PLANS,
  freeLimits: DEFAULT_FREE_LIMITS,
};

function normalizePlanSettings(data: Partial<PlanSettings> | undefined): PlanSettings {
  const plans = { ...DEFAULT_PLANS };
  if (data?.plans) {
    for (const [id, plan] of Object.entries(data.plans)) {
      plans[id] = {
        ...DEFAULT_PLANS[id],
        ...plan,
        id,
      };
    }
  }
  return {
    plans,
    freeLimits: {
      ...DEFAULT_FREE_LIMITS,
      ...(data?.freeLimits ?? {}),
    },
    updatedAt: data?.updatedAt instanceof Date ? data.updatedAt : undefined,
  };
}

export const planSettingsService = {
  async get(): Promise<PlanSettings> {
    const doc = await getDb().collection('settings').doc(DOC_ID).get();
    if (!doc.exists) return { ...defaults };
    const data = doc.data() as Partial<PlanSettings>;
    return normalizePlanSettings(data);
  },

  async getFreeLimits(): Promise<FreeLimitsConfig> {
    const settings = await this.get();
    return settings.freeLimits;
  },

  async getPlan(planId: string): Promise<PlanConfig | null> {
    const settings = await this.get();
    const plan = settings.plans[planId];
    if (!plan || !plan.enabled) return null;
    return plan;
  },

  async getPlanPrice(planId: string, cycle: 'monthly' | 'yearly'): Promise<number> {
    const plan = await this.getPlan(planId);
    if (!plan) {
      throw new HttpError(400, 'Gói không hợp lệ hoặc đã tắt', 'Bad Request');
    }
    return cycle === 'yearly' ? plan.yearlyPrice : plan.monthlyPrice;
  },

  async update(patch: {
    plans?: Record<string, Partial<PlanConfig>>;
    freeLimits?: Partial<FreeLimitsConfig>;
  }): Promise<PlanSettings> {
    const current = await this.get();
    const nextPlans: Record<string, PlanConfig> = { ...current.plans };

    if (patch.plans) {
      for (const [id, planPatch] of Object.entries(patch.plans)) {
        const base = nextPlans[id] ?? { ...DEFAULT_PLANS.pro, id };
        nextPlans[id] = { ...base, ...planPatch, id };
      }
    }

    const nextFreeLimits = patch.freeLimits
      ? { ...current.freeLimits, ...patch.freeLimits }
      : current.freeLimits;

    if (nextFreeLimits.documentDownloads < 0 || nextFreeLimits.placesCreated < 0 || nextFreeLimits.friends < 0) {
      throw new HttpError(400, 'Hạn mức phải >= 0', 'Bad Request');
    }

    for (const plan of Object.values(nextPlans)) {
      if (plan.monthlyPrice < 0 || plan.yearlyPrice < 0) {
        throw new HttpError(400, 'Giá gói phải >= 0', 'Bad Request');
      }
    }

    const payload = {
      plans: nextPlans,
      freeLimits: nextFreeLimits,
      updatedAt: new Date(),
    };

    const docRef = getDb().collection('settings').doc(DOC_ID);
    const existing = await docRef.get();
    if (!existing.exists) {
      await docRef.set({ ...defaults, ...payload, createdAt: new Date() });
    } else {
      await docRef.set(payload, { merge: true });
    }

    return this.get();
  },
};
