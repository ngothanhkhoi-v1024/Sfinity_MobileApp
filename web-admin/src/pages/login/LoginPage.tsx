import { LockOutlined, MailOutlined } from '@ant-design/icons';
import { Alert, Button, Card, Form, Input, Typography, theme } from 'antd';
import { useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';

import { config } from '@/config';
import { useAuth } from '@/contexts/AuthContext';
import type { LoginCredentials } from '@/types/auth';

export function LoginPage() {
  const [form] = Form.useForm<LoginCredentials>();
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const { login, isAuthenticated, isLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const { token } = theme.useToken();

  const from = (location.state as { from?: { pathname: string } } | null)?.from?.pathname ?? '/';

  if (!isLoading && isAuthenticated) {
    return <Navigate to={from} replace />;
  }

  const onFinish = async (values: LoginCredentials) => {
    setError(null);
    setSubmitting(true);
    try {
      await login(values);
      navigate(from, { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Đăng nhập thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24,
        background: `linear-gradient(135deg, ${token.colorPrimaryBg} 0%, ${token.colorBgLayout} 50%, ${token.colorPrimaryBgHover} 100%)`,
      }}
    >
      <Card
        style={{ width: '100%', maxWidth: 420, boxShadow: token.boxShadowSecondary }}
        bordered={false}
      >
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div
            style={{
              width: 56,
              height: 56,
              borderRadius: 12,
              background: token.colorPrimary,
              color: '#fff',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 24,
              fontWeight: 700,
              marginBottom: 16,
            }}
          >
            S
          </div>
          <Typography.Title level={3} style={{ margin: 0 }}>
            {config.appName}
          </Typography.Title>
          <Typography.Text type="secondary">Đăng nhập để quản trị hệ thống</Typography.Text>
        </div>

        {error && (
          <Alert type="error" message={error} showIcon style={{ marginBottom: 16 }} />
        )}

        {config.useMockAuth && (
          <Alert
            type="info"
            showIcon
            style={{ marginBottom: 16 }}
            message="Chế độ demo"
            description="admin@sfinity.com / admin123"
          />
        )}

        <Form
          form={form}
          layout="vertical"
          onFinish={onFinish}
          requiredMark={false}
          initialValues={{ email: config.useMockAuth ? 'admin@sfinity.com' : '' }}
        >
          <Form.Item
            name="email"
            label="Email"
            rules={[
              { required: true, message: 'Vui lòng nhập email' },
              { type: 'email', message: 'Email không hợp lệ' },
            ]}
          >
            <Input prefix={<MailOutlined />} placeholder="admin@sfinity.com" size="large" />
          </Form.Item>

          <Form.Item
            name="password"
            label="Mật khẩu"
            rules={[{ required: true, message: 'Vui lòng nhập mật khẩu' }]}
          >
            <Input.Password
              prefix={<LockOutlined />}
              placeholder="••••••••"
              size="large"
            />
          </Form.Item>

          <Form.Item style={{ marginBottom: 0 }}>
            <Button type="primary" htmlType="submit" block size="large" loading={submitting}>
              Đăng nhập
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
}
