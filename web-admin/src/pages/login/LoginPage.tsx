import { LockOutlined, MailOutlined, SafetyCertificateOutlined } from '@ant-design/icons';
import { Alert, Button, Card, Form, Input, Steps, Typography, message } from 'antd';
import { useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';

import * as authApi from '@/api/auth';
import { config } from '@/config';
import { useAuth } from '@/contexts/AuthContext';
import type { LoginCredentials } from '@/types/auth';

type Mode = 'login' | 'forgot';
type ForgotStep = 0 | 1;

export function LoginPage() {
  const [form] = Form.useForm<LoginCredentials>();
  const [forgotForm] = Form.useForm();
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [mode, setMode] = useState<Mode>('login');
  const [forgotStep, setForgotStep] = useState<ForgotStep>(0);
  const [forgotEmail, setForgotEmail] = useState('');
  const [forgotEmailInput, setForgotEmailInput] = useState('');

  const { login, isAuthenticated, isLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const from = (location.state as { from?: { pathname: string } } | null)?.from?.pathname ?? '/';

  if (!isLoading && isAuthenticated) {
    return <Navigate to={from} replace />;
  }

  // ── Login ────────────────────────────────────────────────
  const onLogin = async (values: LoginCredentials) => {
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

  // ── Forgot step 0: gửi email ─────────────────────────────
  const onSendOtp = async (values: { email: string }) => {
    const email = typeof values === 'string' ? values : values.email;
    setError(null);
    setSubmitting(true);
    try {
      await authApi.forgotPassword(email);
      setForgotEmail(email);
      setForgotStep(1);
      message.success('Đã gửi mã OTP về email của bạn');
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })
        ?.response?.data?.message;
      setError(msg ?? 'Không tìm thấy email hoặc gửi OTP thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  // ── Forgot step 1: nhập code + mật khẩu mới ────────────
  const onResetPassword = async (values: { code: string; newPassword: string }) => {
    setError(null);
    setSubmitting(true);
    try {
      await authApi.resetPassword(forgotEmail, values.code, values.newPassword);
      message.success('Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.');
      setMode('login');
      setForgotStep(0);
      forgotForm.resetFields();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })
        ?.response?.data?.message;
      setError(msg ?? 'Mã OTP không đúng hoặc đặt lại mật khẩu thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const switchToForgot = () => {
    setMode('forgot');
    setError(null);
    setForgotStep(0);
    setForgotEmailInput('');
  };

  const switchToLogin = () => {
    setMode('login');
    setError(null);
    form.resetFields();
  };

  return (
    <div className="login-page">
      {/* Hero */}
      <div className="login-hero">
        <div className="login-hero-content">
          <div style={{
            width: 56, height: 56, borderRadius: 16,
            background: 'linear-gradient(135deg, #818cf8, #6366f1)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 26, fontWeight: 700, marginBottom: 32,
            boxShadow: '0 12px 32px rgba(99, 102, 241, 0.4)',
          }}>
            S
          </div>
          <h1>Quản trị Sfinity</h1>
          <p>Bảng điều khiển hiện đại để quản lý người dùng, nội dung và vận hành hệ thống một cách trực quan, nhanh chóng.</p>
          <div style={{ marginTop: 40, display: 'flex', alignItems: 'center', gap: 10, opacity: 0.85 }}>
            <SafetyCertificateOutlined style={{ fontSize: 18 }} />
            <span style={{ fontSize: 13 }}>Bảo mật JWT · Phân quyền admin</span>
          </div>
        </div>
      </div>

      {/* Panel */}
      <div className="login-panel">
        <Card className="login-card" bordered={false}>

          {mode === 'login' ? (
            <>
              <Typography.Title level={3} style={{ marginTop: 0, marginBottom: 8, fontWeight: 700 }}>
                Đăng nhập
              </Typography.Title>
              <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 28 }}>
                Chào mừng trở lại. Vui lòng đăng nhập để tiếp tục.
              </Typography.Text>

              {error && <Alert type="error" message={error} showIcon style={{ marginBottom: 20 }} />}

              {config.useMockAuth && (
                <Alert type="info" showIcon style={{ marginBottom: 20 }}
                  message="Tài khoản demo"
                  description="admin@sfinity.com / admin123"
                />
              )}

              <Form form={form} layout="vertical" onFinish={onLogin}
                requiredMark={false} size="large"
                initialValues={{ email: config.useMockAuth ? 'admin@sfinity.com' : '' }}
              >
                <Form.Item name="email" label="Email"
                  rules={[
                    { required: true, message: 'Vui lòng nhập email' },
                    { type: 'email', message: 'Email không hợp lệ' },
                  ]}
                >
                  <Input prefix={<MailOutlined style={{ color: '#94a3b8' }} />} placeholder="admin@sfinity.com" />
                </Form.Item>

                <Form.Item name="password" label="Mật khẩu"
                  rules={[{ required: true, message: 'Vui lòng nhập mật khẩu' }]}
                >
                  <Input.Password prefix={<LockOutlined style={{ color: '#94a3b8' }} />} placeholder="••••••••" />
                </Form.Item>

                {/* Quên mật khẩu link */}
                <div style={{ textAlign: 'right', marginTop: -12, marginBottom: 20 }}>
                  <Button type="link" size="small" style={{ padding: 0, fontSize: 13 }} onClick={switchToForgot}>
                    Quên mật khẩu?
                  </Button>
                </div>

                <Form.Item style={{ marginBottom: 0 }}>
                  <Button type="primary" htmlType="submit" block loading={submitting} style={{ height: 48 }}>
                    Đăng nhập
                  </Button>
                </Form.Item>
              </Form>
            </>
          ) : (
            <>
              <Typography.Title level={3} style={{ marginTop: 0, marginBottom: 8, fontWeight: 700 }}>
                Quên mật khẩu
              </Typography.Title>
              <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 28 }}>
                Làm theo các bước để đặt lại mật khẩu của bạn.
              </Typography.Text>

              <Steps
                size="small"
                current={forgotStep}
                style={{ marginBottom: 28 }}
                items={[
                  { title: 'Nhập email' },
                  { title: 'Đặt mật khẩu mới' },
                ]}
              />

              {error && <Alert type="error" message={error} showIcon style={{ marginBottom: 20 }} />}

              <Form key="forgot-form" form={forgotForm} layout="vertical" requiredMark={false} size="large">

                {/* Step 0: nhập email */}
                {forgotStep === 0 && (
                  <>
                    <div style={{ marginBottom: 16 }}>
                      <label style={{ fontSize: 14, fontWeight: 500, display: 'block', marginBottom: 8 }}>
                        Email đã đăng ký
                      </label>
                      <Input
                        prefix={<MailOutlined style={{ color: '#94a3b8' }} />}
                        placeholder="example@gmail.com"
                        size="large"
                        value={forgotEmailInput}
                        onChange={(e) => setForgotEmailInput(e.target.value)}
                        onPressEnter={() => onSendOtp({ email: forgotEmailInput })}
                      />
                    </div>
                    <Button
                      type="primary"
                      block
                      loading={submitting}
                      style={{ height: 48 }}
                      disabled={!forgotEmailInput.includes('@')}
                      onClick={() => onSendOtp({ email: forgotEmailInput })}
                    >
                      Gửi mã OTP
                    </Button>
                  </>
                )}

                {/* Step 1 — gộp code + mật khẩu mới vào 1 form */}
                {forgotStep === 1 && (
                  <>
                    <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 16, fontSize: 13 }}>
                      Mã OTP đã được gửi đến <strong>{forgotEmail}</strong>
                    </Typography.Text>
                    <Form.Item name="code" label="Mã OTP"
                      rules={[{ required: true, message: 'Vui lòng nhập mã OTP' }]}
                    >
                      <Input
                        prefix={<SafetyCertificateOutlined style={{ color: '#94a3b8' }} />}
                        placeholder="000000"
                        maxLength={6}
                        autoComplete="one-time-code"
                        style={{ letterSpacing: 4, fontSize: 18 }}
                      />
                    </Form.Item>
                    <Form.Item name="newPassword" label="Mật khẩu mới"
                      rules={[
                        { required: true, message: 'Vui lòng nhập mật khẩu mới' },
                        { min: 6, message: 'Tối thiểu 6 ký tự' },
                      ]}
                    >
                      <Input.Password prefix={<LockOutlined style={{ color: '#94a3b8' }} />} placeholder="Tối thiểu 6 ký tự" />
                    </Form.Item>
                    <Form.Item name="confirmPassword" label="Xác nhận mật khẩu"
                      dependencies={['newPassword']}
                      rules={[
                        { required: true, message: 'Vui lòng xác nhận mật khẩu' },
                        ({ getFieldValue }) => ({
                          validator(_, value) {
                            if (!value || getFieldValue('newPassword') === value) {
                              return Promise.resolve();
                            }
                            return Promise.reject(new Error('Mật khẩu không khớp'));
                          },
                        }),
                      ]}
                    >
                      <Input.Password prefix={<LockOutlined style={{ color: '#94a3b8' }} />} placeholder="Nhập lại mật khẩu" />
                    </Form.Item>
                    <Button type="primary" block loading={submitting} style={{ height: 48 }}
                      onClick={() => forgotForm.validateFields(['code', 'newPassword', 'confirmPassword']).then(onResetPassword)}
                    >
                      Đặt lại mật khẩu
                    </Button>
                  </>
                )}
              </Form>

              <Button type="link" block style={{ marginTop: 16, color: '#64748b' }} onClick={switchToLogin}>
                ← Quay lại đăng nhập
              </Button>
            </>
          )}
        </Card>
      </div>
    </div>
  );
}