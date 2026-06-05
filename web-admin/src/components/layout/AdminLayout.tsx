import {
  AppstoreOutlined,
  BellOutlined,
  CrownOutlined,
  DashboardOutlined,
  LogoutOutlined,
  MenuOutlined,
  MessageOutlined,
  SettingOutlined,
  TagsOutlined,
  TeamOutlined,
  ToolOutlined,
  UserOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import type { MenuProps } from 'antd';
import { Avatar, Button, Dropdown, Layout, Menu, Typography } from 'antd';
import { useMemo, useState } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';

import { config } from '@/config';
import { useAuth } from '@/contexts/AuthContext';
import { useTranslation } from '@/i18n';

const { Header, Sider, Content } = Layout;

const COLLAPSED_WIDTH = 72;
const EXPANDED_WIDTH = 260;

export function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false);
  const { user, logout } = useAuth();
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();

  const menuItems: MenuProps['items'] = useMemo(
    () => [
      { key: '/', icon: <DashboardOutlined />, label: t('menu.dashboard') },
      { type: 'divider' },
      { key: '/users', icon: <TeamOutlined />, label: t('menu.users') },
      { key: '/content', icon: <AppstoreOutlined />, label: t('menu.content') },
      { key: '/categories', icon: <TagsOutlined />, label: t('menu.categories') },
      { key: '/amenities', icon: <ToolOutlined />, label: t('menu.amenities') },
      { type: 'divider' },
      { key: '/feedback', icon: <MessageOutlined />, label: t('menu.feedback') },
      { key: '/reports', icon: <WarningOutlined />, label: t('menu.reports') },
      { key: '/notifications', icon: <BellOutlined />, label: t('menu.notifications') },
      { type: 'divider' },
      { key: '/admins', icon: <CrownOutlined />, label: t('menu.admins') },
      { key: '/settings', icon: <SettingOutlined />, label: t('menu.settings') },
    ],
    [t],
  );

  const flatKeys = (menuItems ?? [])
    .filter((item): item is { key: string } => !!item && 'key' in item && typeof item.key === 'string')
    .map((item) => item.key);

  const selectedKey =
    flatKeys.find((key) => key !== '/' && location.pathname.startsWith(key)) ?? '/';

  const userMenu = {
    items: [
      {
        key: 'logout',
        icon: <LogoutOutlined />,
        label: t('logout'),
        danger: true,
        onClick: () => {
          logout();
          navigate('/login', { replace: true });
        },
      },
    ],
  };

  const siderWidth = collapsed ? COLLAPSED_WIDTH : EXPANDED_WIDTH;

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider
        className="admin-sider"
        collapsible
        collapsed={collapsed}
        onCollapse={setCollapsed}
        trigger={null}
        width={EXPANDED_WIDTH}
        collapsedWidth={COLLAPSED_WIDTH}
        theme="dark"
        style={{
          overflow: 'auto',
          height: '100vh',
          position: 'fixed',
          left: 0,
          top: 0,
          bottom: 0,
        }}
      >
        <div
          className="admin-logo"
          style={{
            justifyContent: collapsed ? 'center' : 'flex-start',
            padding: collapsed ? '0 12px' : '0 20px',
          }}
        >
          <div className="admin-logo-mark">S</div>
          {!collapsed && (
            <div>
              <div className="admin-logo-text">{config.appName}</div>
              <div className="admin-logo-sub">{t('control.panel')}</div>
            </div>
          )}
        </div>

        <Menu
          className="admin-menu"
          theme="dark"
          mode="inline"
          inlineCollapsed={collapsed}
          selectedKeys={[selectedKey]}
          items={menuItems}
          onClick={({ key }) => navigate(String(key))}
        />
      </Sider>

      <Layout className="admin-main" style={{ marginLeft: siderWidth, transition: 'margin-left 0.2s ease' }}>
        <Header
          className="admin-header"
          style={{
            padding: '0 28px',
            height: 64,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <Button
            type="text"
            icon={<MenuOutlined />}
            onClick={() => setCollapsed((v) => !v)}
            style={{ fontSize: 16 }}
          />

          <Dropdown menu={userMenu} placement="bottomRight">
            <Button
              type="text"
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                height: 44,
                padding: '0 12px',
                borderRadius: 10,
              }}
            >
              <Avatar
                size={36}
                style={{ background: 'linear-gradient(135deg, #818cf8, #6366f1)' }}
                icon={<UserOutlined />}
              />
              <div style={{ textAlign: 'left', lineHeight: 1.3 }}>
                <Typography.Text strong style={{ display: 'block', fontSize: 13 }}>
                  {user?.name ?? 'Admin'}
                </Typography.Text>
                <Typography.Text type="secondary" style={{ fontSize: 11 }}>
                  {t('profile.role')}
                </Typography.Text>
              </div>
            </Button>
          </Dropdown>
        </Header>

        <Content className="admin-content">
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
}
