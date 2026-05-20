import { App as AntApp, ConfigProvider } from 'antd';
import viVN from 'antd/locale/vi_VN';

import { AuthProvider } from '@/contexts/AuthContext';
import { AppRoutes } from '@/routes';
import { adminTheme } from '@/theme/adminTheme';

export default function App() {
  return (
    <ConfigProvider locale={viVN} theme={adminTheme}>
      <AntApp>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </AntApp>
    </ConfigProvider>
  );
}
