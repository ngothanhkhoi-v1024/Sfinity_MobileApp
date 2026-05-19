import { LockOutlined, MailOutlined, SafetyCertificateOutlined } from '@ant-design/icons';
import { Alert, Button, Card, Form, Input, Typography } from 'antd';
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
    <div className="login-page">
      <div className="login-hero">
        <div className="login-hero-content">
          <div
            style={{
              width: 56,
              height: 56,
              borderRadius: 16,
              background: 'linear-gradient(135deg, #818cf8, #6366f1)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 26,
              fontWeight: 700,
              marginBottom: 32,
              boxShadow: '0 12px 32px rgba(99, 102, 241, 0.4)',
            }}
          >
            S
          </div>
          <h1>Quản trị Sfinity</h1>
          <p>
            Bảng điều khiển hiện đại để quản lý người dùng, nội dung và vận hành hệ thống một cách
            trực quan, nhanh chóng.
          </p>
          <div style={{ marginTop: 40, display: 'flex', alignItems: 'center', gap: 10, opacity: 0.85 }}>
            <SafetyCertificateOutlined style={{ fontSize: 18 }} />
            <span style={{ fontSize: 13 }}>Bảo mật JWT · Phân quyền admin</span>
          </div>
        </div>
      </div>

      <div className="login-panel">
        <Card className="login-card" bordered={false}>
          <Typography.Title level={3} style={{ marginTop: 0, marginBottom: 8, fontWeight: 700 }}>
            Đăng nhập
          </Typography.Title>
          <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 28 }}>
            Chào mừng trở lại. Vui lòng đăng nhập để tiếp tục.
          </Typography.Text>

          {error && <Alert type="error" message={error} showIcon style={{ marginBottom: 20 }} />}

          {config.useMockAuth && (
            <Alert
              type="info"
              showIcon
              style={{ marginBottom: 20 }}
              message="Tài khoản demo"
              description="admin@sfinity.com / admin123"
            />
          )}

          <Form
            form={form}
            layout="vertical"
            onFinish={onFinish}
            requiredMark={false}
            size="large"
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
              <Input prefix={<MailOutlined style={{ color: '#94a3b8' }} />} placeholder="admin@sfinity.com" />
            </Form.Item>

            <Form.Item
              name="password"
              label="Mật khẩu"
              rules={[{ required: true, message: 'Vui lòng nhập mật khẩu' }]}
            >
              <Input.Password prefix={<LockOutlined style={{ color: '#94a3b8' }} />} placeholder="••••••••" />
            </Form.Item>

            <Form.Item style={{ marginBottom: 0, marginTop: 8 }}>
              <Button type="primary" htmlType="submit" block loading={submitting} style={{ height: 48 }}>
                Đăng nhập
              </Button>
            </Form.Item>
          </Form>
        </Card>
      </div>
    </div>
  );
}
