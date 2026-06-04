import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import { AdminLayout } from '@/components/layout/AdminLayout';
import { DocCategoriesPage } from '@/pages/categories/DocCategoriesPage';
import { AmenitiesPage } from '@/pages/categories/AmenitiesPage';
import { ContentPage } from '@/pages/content/ContentPage';
import { DashboardPage } from '@/pages/dashboard/DashboardPage';
import { AdminsPage } from '@/pages/admins/AdminsPage';
import { FeedbackPage } from '@/pages/feedback/FeedbackPage';
import { LoginPage } from '@/pages/login/LoginPage';
import { NotificationsPage } from '@/pages/notifications/NotificationsPage';
import { PlaceholderPage } from '@/pages/placeholder/PlaceholderPage';
import { SettingsPage } from '@/pages/settings/SettingsPage';
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
            <Route path="categories" element={<DocCategoriesPage />} />
            <Route path="amenities" element={<AmenitiesPage />} />
            <Route path="feedback" element={<FeedbackPage />} />
            <Route path="reports" element={<ReportsPage />} />
            <Route path="notifications" element={<NotificationsPage />} />
            <Route path="admins" element={<AdminsPage />} />
            <Route path="media" element={<PlaceholderPage title="Media" />} />
            <Route path="settings" element={<SettingsPage />} />
          </Route>
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
