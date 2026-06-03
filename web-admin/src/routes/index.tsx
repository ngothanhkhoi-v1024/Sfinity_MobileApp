import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import { AdminLayout } from '@/components/layout/AdminLayout';
import { CategoriesPage } from '@/pages/categories/CategoriesPage';
import { ContentPage } from '@/pages/content/ContentPage';
import { DocumentsPage } from '@/pages/content/DocumentsPage';
import { PlacesPage } from '@/pages/content/PlacesPage';
import { DashboardPage } from '@/pages/dashboard/DashboardPage';
import { AdminsPage } from '@/pages/admins/AdminsPage';
import { FeedbackPage } from '@/pages/feedback/FeedbackPage';
import { LoginPage } from '@/pages/login/LoginPage';
import { NotificationsPage } from '@/pages/notifications/NotificationsPage';
import { PlaceholderPage } from '@/pages/placeholder/PlaceholderPage';
import { ReportsPage } from '@/pages/reports/ReportsPage';
import { UsersPage } from '@/pages/users/UsersPage';

import { ProtectedRoute } from './ProtectedRoute';

export function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route element={<ProtectedRoute />}>
          <Route element={<AdminLayout />}>
            <Route index element={<DashboardPage />} />
            <Route path="users" element={<UsersPage />} />
            <Route path="content" element={<ContentPage />} />
            <Route path="documents" element={<DocumentsPage />} />
            <Route path="places" element={<PlacesPage />} />
            <Route path="categories" element={<CategoriesPage />} />
            <Route path="feedback" element={<FeedbackPage />} />
            <Route path="reports" element={<ReportsPage />} />
            <Route path="notifications" element={<NotificationsPage />} />
            <Route path="admins" element={<AdminsPage />} />
            <Route path="media" element={<PlaceholderPage title="Media" />} />
            <Route path="settings" element={<PlaceholderPage title="Cài đặt" />} />
          </Route>
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
