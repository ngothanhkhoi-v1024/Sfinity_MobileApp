import { App as AntApp, ConfigProvider } from 'antd';
import viVN from 'antd/locale/vi_VN';

import { AuthProvider } from '@/contexts/AuthContext';
import { AppRoutes } from '@/routes';

const theme = {
  token: {
    colorPrimary: '#4f46e5',
    borderRadius: 8,
    fontFamily:
      "'Segoe UI', system-ui, -apple-system, BlinkMacSystemFont, sans-serif",
  },
};

export default function App() {
  return (
    <ConfigProvider locale={viVN} theme={theme}>
      <AntApp>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </AntApp>
    </ConfigProvider>
  );
}
