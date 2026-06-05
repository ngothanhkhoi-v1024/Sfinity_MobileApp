import { App as AntApp, ConfigProvider, theme as antTheme } from 'antd';
import enUS from 'antd/locale/en_US';
import viVN from 'antd/locale/vi_VN';

import { AppSettingsProvider, useAppSettings } from '@/contexts/AppSettingsContext';
import { AuthProvider } from '@/contexts/AuthContext';
import { AppRoutes } from '@/routes';
import { adminTheme } from '@/theme/adminTheme';

function ThemedApp() {
  const { theme, language } = useAppSettings();

  const currentTheme = {
    ...adminTheme,
    algorithm: theme === 'dark' ? antTheme.darkAlgorithm : antTheme.defaultAlgorithm,
    token: {
      ...adminTheme.token,
      ...(theme === 'dark' && {
        colorBgLayout: '#0a0a0a',
        colorBgContainer: '#1a1a1a',
        colorBgElevated: '#1f1f1f',
      }),
    },
    components: {
      ...adminTheme.components,
      ...(theme === 'dark' && {
        Layout: {
          headerBg: 'rgba(15, 23, 42, 0.85)',
          bodyBg: '#0a0a0a',
          siderBg: '#060612',
        },
        Table: {
          headerBg: '#1a1a1a',
          borderColor: '#2d2d2d',
          rowHoverBg: '#1f1f1f',
        },
        Card: {
          colorBgContainer: '#1a1a1a',
        },
      }),
    },
  };

  return (
    <ConfigProvider locale={language === 'vi' ? viVN : enUS} theme={currentTheme}>
      <AntApp>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </AntApp>
    </ConfigProvider>
  );
}

export default function App() {
  return (
    <AppSettingsProvider>
      <ThemedApp />
    </AppSettingsProvider>
  );
}