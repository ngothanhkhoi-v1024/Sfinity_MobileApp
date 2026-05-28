import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { ReportStatus } from '../types/enums';
import type { CreateReportDto, ResolveReportDto } from '../dto/report.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const reportsService = {
  async findAll(status?: ReportStatus) {
    let query: any = getDb().collection('reports');
    if (status) {
      query = query.where('status', '==', status);
    }

    const snapshot = await query.get();
    const list = snapshot.docs.map((doc: any) => ({ id: doc.id, ...doc.data() } as any));

    // Sort by createdAt desc in memory
    list.sort((a: any, b: any) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    const resolved = await Promise.all(
      list.map(async (report: any) => {
        let user = null;
        if (report.userId) {
          const userDoc = await getDb().collection('users').doc(report.userId).get();
          if (userDoc.exists) {
            const u = userDoc.data() as any;
            user = { id: userDoc.id, name: u.name, email: u.email };
          }
        }
        return {
          id: report.id,
          userId: report.userId,
          targetType: report.targetType,
          targetId: report.targetId ?? null,
          reason: report.reason,
          description: report.description ?? null,
          status: report.status,
          resolution: report.resolution ?? null,
          createdAt: toDate(report.createdAt),
          updatedAt: toDate(report.updatedAt),
          user,
        };
      }),
    );

    return resolved;
  },

  async create(userId: string, dto: CreateReportDto) {
    const docRef = getDb().collection('reports').doc();
    const report = {
      id: docRef.id,
      userId,
      targetType: dto.targetType,
      targetId: dto.targetId ?? null,
      reason: dto.reason,
      description: dto.description ?? null,
      status: ReportStatus.PENDING,
      resolution: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await docRef.set(report);
    return reportsService.findOne(docRef.id);
  },

  async resolve(id: string, dto: ResolveReportDto) {
    await reportsService.findOne(id); // Throws if not found
    const reportRef = getDb().collection('reports').doc(id);
    
    await reportRef.update({
      status: dto.status,
      resolution: dto.resolution ?? null,
      updatedAt: new Date(),
    });

    return reportsService.findOne(id);
  },

  async findOne(id: string) {
    const doc = await getDb().collection('reports').doc(id).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy báo cáo', 'Not Found');
    }
    const report = { id: doc.id, ...doc.data() } as any;

    let user = null;
    if (report.userId) {
      const userDoc = await getDb().collection('users').doc(report.userId).get();
      if (userDoc.exists) {
        const u = userDoc.data() as any;
        user = { id: userDoc.id, name: u.name, email: u.email };
      }
    }

    return {
      id: report.id,
      userId: report.userId,
      targetType: report.targetType,
      targetId: report.targetId ?? null,
      reason: report.reason,
      description: report.description ?? null,
      status: report.status,
      resolution: report.resolution ?? null,
      createdAt: toDate(report.createdAt),
      updatedAt: toDate(report.updatedAt),
      user,
    };
  },
};
