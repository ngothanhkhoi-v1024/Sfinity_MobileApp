import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';

const SETTINGS_ID = 'global';

export interface SystemSettings {
  autoApproveDocuments: boolean;
  autoApprovePlaces: boolean;
}

const defaults: SystemSettings = {
  autoApproveDocuments: false,
  autoApprovePlaces: false,
};

export const settingsService = {
  async get(): Promise<SystemSettings> {
    const doc = await getDb().collection('settings').doc(SETTINGS_ID).get();
    if (!doc.exists) {
      return { ...defaults };
    }
    const data = doc.data() as Partial<SystemSettings>;
    return {
      autoApproveDocuments: data.autoApproveDocuments ?? defaults.autoApproveDocuments,
      autoApprovePlaces: data.autoApprovePlaces ?? defaults.autoApprovePlaces,
    };
  },

  async update(patch: Partial<SystemSettings>): Promise<SystemSettings> {
    const updateData: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(patch)) {
      if (value !== undefined) {
        updateData[key] = value;
      }
    }

    if (Object.keys(updateData).length === 0) {
      throw new HttpError(400, 'Không có trường nào được cung cấp', 'Bad Request');
    }

    updateData.updatedAt = new Date();

    const docRef = getDb().collection('settings').doc(SETTINGS_ID);
    const existing = await docRef.get();
    if (!existing.exists) {
      await docRef.set({ ...defaults, ...updateData, createdAt: new Date() });
    } else {
      await docRef.update(updateData);
    }

    return this.get();
  },
};
