import type { ThemeConfig } from 'antd';

export const adminTheme: ThemeConfig = {
  token: {
    colorPrimary: '#6366f1',
    colorInfo: '#6366f1',
    colorSuccess: '#10b981',
    colorWarning: '#f59e0b',
    colorError: '#ef4444',
    colorBgLayout: '#f1f5f9',
    colorBgContainer: '#ffffff',
    borderRadius: 12,
    borderRadiusLG: 16,
    fontFamily: "'Plus Jakarta Sans', 'Segoe UI', system-ui, sans-serif",
    fontSize: 14,
    controlHeight: 40,
    boxShadowSecondary:
      '0 4px 6px -1px rgba(15, 23, 42, 0.06), 0 2px 4px -2px rgba(15, 23, 42, 0.04)',
  },
  components: {
    Layout: {
      headerBg: 'rgba(255, 255, 255, 0.85)',
      bodyBg: '#f1f5f9',
      siderBg: '#0f172a',
    },
    Menu: {
      darkItemBg: 'transparent',
      darkSubMenuItemBg: 'transparent',
      itemBorderRadius: 10,
      itemMarginInline: 8,
      itemHeight: 44,
    },
    Card: {
      paddingLG: 24,
    },
    Table: {
      headerBg: '#f8fafc',
      borderColor: '#e2e8f0',
      rowHoverBg: '#f8fafc',
    },
    Button: {
      primaryShadow: '0 4px 14px rgba(99, 102, 241, 0.35)',
    },
    Input: {
      activeShadow: '0 0 0 2px rgba(99, 102, 241, 0.15)',
    },
  },
};
