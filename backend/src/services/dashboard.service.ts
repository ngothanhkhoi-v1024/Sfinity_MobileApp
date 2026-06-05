import { getDb } from '../lib/firebase';
import { isPubliclyVisible } from '../lib/content-state';
import { UserRole, ReportStatus } from '../types/enums';

export const dashboardService = {
  async getStats() {
    const db = getDb();

    const [
      usersSnap,
      adminsSnap,
      documentsSnap,
      placesSnap,
      categoriesSnap,
      feedbackSnap,
      pendingFeedbackSnap,
      pendingReportsSnap,
    ] = await Promise.all([
      db.collection('users').where('role', '==', UserRole.USER).count().get(),
      db.collection('users').where('role', '==', UserRole.ADMIN).count().get(),
      db.collection('documents').get(),
      db.collection('places').get(),
      db.collection('categories').count().get(),
      db.collection('feedbacks').count().get(),
      db.collection('feedbacks').where('resolved', '==', false).count().get(),
      db.collection('reports').where('status', '==', ReportStatus.PENDING).count().get(),
    ]);

    const documents = documentsSnap.docs;
    const places = placesSnap.docs;
    const publishedDocuments = documents.filter((doc) =>
      isPubliclyVisible(doc.data()),
    ).length;
    const publishedPlaces = places.filter((doc) =>
      isPubliclyVisible(doc.data()),
    ).length;

    const users = usersSnap.data().count;
    const admins = adminsSnap.data().count;
    const categories = categoriesSnap.data().count;
    const feedback = feedbackSnap.data().count;
    const pendingFeedback = pendingFeedbackSnap.data().count;
    const pendingReports = pendingReportsSnap.data().count;

    return {
      users,
      admins,
      documents: documents.length,
      publishedDocuments,
      draftDocuments: documents.length - publishedDocuments,
      places: places.length,
      publishedPlaces,
      categories,
      feedback,
      pendingFeedback,
      pendingReports,
    };
  },
};
