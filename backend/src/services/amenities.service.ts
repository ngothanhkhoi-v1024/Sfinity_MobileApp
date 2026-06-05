import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

const DEFAULT_AMENITIES = [
  { name: 'WiFi', description: 'Có kết nối WiFi miễn phí' },
  { name: 'Điều hòa', description: 'Có điều hòa không khí' },
  { name: 'Ổ cắm', description: 'Có ổ cắm sạc thiết bị' },
  { name: 'Yên tĩnh', description: 'Khu vực yên tĩnh, phù hợp học tập' },
  { name: 'Mở muộn', description: 'Mở cửa đến giờ muộn' },
  { name: 'Giữ xe', description: 'Có khu vực giữ xe' },
];

export async function seedAmenities() {
  const snapshot = await getDb().collection('amenities').get();
  if (!snapshot.empty) {
    console.log(`[amenities] seed — already has ${snapshot.size} docs, skipping.`);
    return;
  }

  console.log('[amenities] seed — seeding defaults...');
  const batch = getDb().batch();
  for (const amenity of DEFAULT_AMENITIES) {
    const docRef = getDb().collection('amenities').doc();
    batch.set(docRef, {
      id: docRef.id,
      name: amenity.name,
      description: amenity.description,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }
  await batch.commit();
  console.log('[amenities] seed — done.');
}

export const amenitiesService = {
  async findAll() {
    const snapshot = await getDb().collection('amenities').get();
    const items = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        description: data.description ?? null,
        createdAt: toDate(data.createdAt),
        updatedAt: toDate(data.updatedAt),
      };
    });

    return items.sort((a, b) => a.name.localeCompare(b.name));
  },

  async findOne(id: string) {
    const doc = await getDb().collection('amenities').doc(id).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy tiện ích', 'Not Found');
    }
    const data = doc.data()!;
    return {
      id: doc.id,
      name: data.name,
      description: data.description ?? null,
      createdAt: toDate(data.createdAt),
      updatedAt: toDate(data.updatedAt),
    };
  },

  async create(payload: { name: string; description?: string }) {
    const snapshot = await getDb()
      .collection('amenities')
      .where('name', '==', payload.name)
      .limit(1)
      .get();

    if (!snapshot.empty) {
      throw new HttpError(409, 'Tiện ích đã tồn tại', 'Conflict');
    }

    const docRef = getDb().collection('amenities').doc();
    const newItem = {
      id: docRef.id,
      name: payload.name,
      description: payload.description ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await docRef.set(newItem);
    return newItem;
  },

  async update(id: string, payload: { name?: string; description?: string }) {
    await this.findOne(id);

    const docRef = getDb().collection('amenities').doc(id);

    const updateData: any = {
      ...payload,
      description: payload.description ?? null,
      updatedAt: new Date(),
    };

    await docRef.update(updateData);
    const doc = await docRef.get();
    const data = doc.data()!;
    return {
      id: doc.id,
      name: data.name,
      description: data.description ?? null,
      createdAt: toDate(data.createdAt),
      updatedAt: toDate(data.updatedAt),
    };
  },

  async remove(id: string) {
    await this.findOne(id);
    await getDb().collection('amenities').doc(id).delete();
    return { success: true };
  },
};
