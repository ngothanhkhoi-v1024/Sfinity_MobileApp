import { getDb } from '../lib/firebase';
import { ContentStatus, UserRole, ReportStatus } from '../types/enums';

export const dashboardService = {
  async getStats() {
    const db = getDb();
    
    const [
      usersSnap,
      adminsSnap,
      documentsSnap,
      publishedSnap,
      categoriesSnap,
      feedbackSnap,
      pendingFeedbackSnap,
      pendingReportsSnap,
    ] = await Promise.all([
      db.collection('users').where('role', '==', UserRole.USER).count().get(),
      db.collection('users').where('role', '==', UserRole.ADMIN).count().get(),
      db.collection('documents').count().get(),
      db.collection('documents').where('status', '==', ContentStatus.PUBLISHED).count().get(),
      db.collection('categories').count().get(),
      db.collection('feedbacks').count().get(),
      db.collection('feedbacks').where('resolved', '==', false).count().get(),
      db.collection('reports').where('status', '==', ReportStatus.PENDING).count().get(),
    ]);

    const users = usersSnap.data().count;
    const admins = adminsSnap.data().count;
    const documents = documentsSnap.data().count;
    const published = publishedSnap.data().count;
    const categories = categoriesSnap.data().count;
    const feedback = feedbackSnap.data().count;
    const pendingFeedback = pendingFeedbackSnap.data().count;
    const pendingReports = pendingReportsSnap.data().count;

    return {
      users,
      admins,
      documents,
      publishedDocuments: published,
      draftDocuments: documents - published,
      categories,
      feedback,
      pendingFeedback,
      pendingReports,
    };
  },
};
