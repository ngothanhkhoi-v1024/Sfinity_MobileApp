import {
  AppstoreOutlined,
  BellOutlined,
  BookOutlined,
  CrownOutlined,
  DashboardOutlined,
  EnvironmentOutlined,
  LogoutOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  MessageOutlined,
  PictureOutlined,
  SettingOutlined,
  TagsOutlined,
  TeamOutlined,
  UserOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { Avatar, Button, Dropdown, Layout, Menu, Typography } from 'antd';
import { useMemo, useState } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';

import { config } from '@/config';
import { useAuth } from '@/contexts/AuthContext';

const { Header, Sider, Content } = Layout;

const menuItems = [
  {
    type: 'group' as const,
    label: 'Tổng quan',
    children: [{ key: '/', icon: <DashboardOutlined />, label: 'Dashboard' }],
  },
  {
    type: 'group' as const,
    label: 'Quản lý',
    children: [
      { key: '/users', icon: <TeamOutlined />, label: 'Người dùng' },
      { key: '/content', icon: <AppstoreOutlined />, label: 'Nội dung' },
      { key: '/documents', icon: <BookOutlined />, label: 'Tài liệu' },
      { key: '/places', icon: <EnvironmentOutlined />, label: 'Địa điểm' },
      { key: '/categories', icon: <TagsOutlined />, label: 'Danh mục' },
    ],
  },
  {
    type: 'group' as const,
    label: 'Hỗ trợ',
    children: [
      { key: '/feedback', icon: <MessageOutlined />, label: 'Phản hồi' },
      { key: '/reports', icon: <WarningOutlined />, label: 'Báo cáo' },
      { key: '/notifications', icon: <BellOutlined />, label: 'Thông báo' },
    ],
  },
  {
    type: 'group' as const,
    label: 'Hệ thống',
    children: [
      { key: '/admins', icon: <CrownOutlined />, label: 'Admin' },
      { key: '/media', icon: <PictureOutlined />, label: 'Media' },
      { key: '/settings', icon: <SettingOutlined />, label: 'Cài đặt' },
    ],
  },
];

export function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false);
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const selectedKey = useMemo(() => {
    const flat = menuItems.flatMap((g) => g.children ?? []);
    const match = flat.find((item) => item.key !== '/' && location.pathname.startsWith(item.key));
    return match?.key ?? '/';
  }, [location.pathname]);

  const userMenu = {
    items: [
      {
        key: 'logout',
        icon: <LogoutOutlined />,
        label: 'Đăng xuất',
        danger: true,
        onClick: () => {
          logout();
          navigate('/login', { replace: true });
        },
      },
    ],
  };

  const siderWidth = collapsed ? 80 : 260;

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider
        className="admin-sider"
        collapsible
        collapsed={collapsed}
        onCollapse={setCollapsed}
        trigger={null}
        width={260}
        collapsedWidth={80}
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
        <div className="admin-logo" style={{ justifyContent: collapsed ? 'center' : 'flex-start', padding: collapsed ? 0 : '0 20px' }}>
          <div className="admin-logo-mark">S</div>
          {!collapsed && (
            <div>
              <div className="admin-logo-text">{config.appName}</div>
              <div className="admin-logo-sub">Control Panel</div>
            </div>
          )}
        </div>

        <Menu
          className="admin-menu"
          theme="dark"
          mode="inline"
          selectedKeys={[selectedKey]}
          items={menuItems}
          onClick={({ key }) => navigate(key)}
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
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
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
                  Quản trị viên
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
