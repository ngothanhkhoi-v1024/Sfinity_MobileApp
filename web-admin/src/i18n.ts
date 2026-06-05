import { useAppSettings } from '@/contexts/AppSettingsContext';

type Lang = 'vi' | 'en';

const translations: Record<Lang, Record<string, string>> = {
  vi: {
    'menu.overview': 'Tổng quan',
    'menu.management': 'Quản lý',
    'menu.support': 'Hỗ trợ',
    'menu.system': 'Hệ thống',
    'menu.dashboard': 'Dashboard',
    'menu.users': 'Người dùng',
    'menu.content': 'Nội dung',
    'menu.categories': 'Danh mục tài liệu',
    'menu.amenities': 'Tiện ích địa điểm',
    'menu.feedback': 'Phản hồi',
    'menu.reports': 'Báo cáo',
    'menu.notifications': 'Thông báo',
    'menu.admins': 'Admin',
    'menu.media': 'Media',
    'menu.settings': 'Cài đặt',
    'logout': 'Đăng xuất',
    'control.panel': 'Control Panel',
    'profile.role': 'Quản trị viên',
  },
  en: {
    'menu.overview': 'Overview',
    'menu.management': 'Management',
    'menu.support': 'Support',
    'menu.system': 'System',
    'menu.dashboard': 'Dashboard',
    'menu.users': 'Users',
    'menu.content': 'Content',
    'menu.categories': 'Categories',
    'menu.amenities': 'Amenities',
    'menu.feedback': 'Feedback',
    'menu.reports': 'Reports',
    'menu.notifications': 'Notifications',
    'menu.admins': 'Admins',
    'menu.media': 'Media',
    'menu.settings': 'Settings',
    'logout': 'Logout',
    'control.panel': 'Control Panel',
    'profile.role': 'Administrator',
  },
};

export function useTranslation() {
  const { language } = useAppSettings();

  function t(key: string) {
    return translations[language as Lang][key] ?? key;
  }

  return { t };
}

export default translations;
