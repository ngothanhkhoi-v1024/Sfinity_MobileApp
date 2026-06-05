import {
  CheckOutlined,
  GlobalOutlined,
  MoonOutlined,
  SunOutlined,
} from '@ant-design/icons';
import { Card, Col, Row, Switch, Typography } from 'antd';

import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';
import { useAppSettings } from '@/contexts/AppSettingsContext';

const { Title, Text } = Typography;

export function SettingsPage() {
  const { theme, language, setTheme, setLanguage } = useAppSettings();
  const isDark = theme === 'dark';

  return (
    <PageShell>
      <PageHeader
        title="Cài đặt hệ thống"
        description="Quản lý cấu hình toàn cục cho ứng dụng Sfinity"
      />

      <Row gutter={[20, 20]}>
        {/* Giao diện */}
        <Col xs={24} lg={12}>
          <Card
            className="admin-page-card"
            styles={{ body: { padding: '24px 28px' } }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
              <div style={{
                width: 40, height: 40, borderRadius: 10,
                background: 'linear-gradient(135deg, #f59e0b, #d97706)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <SunOutlined style={{ color: '#fff', fontSize: 18 }} />
              </div>
              <div>
                <Title level={5} style={{ margin: 0 }}>Giao diện</Title>
                <Text type="secondary" style={{ fontSize: 13 }}>Chọn chế độ hiển thị</Text>
              </div>
            </div>

            <Row gutter={[12, 12]}>
              {([
                { value: 'light', label: 'Sáng', icon: <SunOutlined />, bg: '#fff', border: '#e2e8f0' },
                { value: 'dark', label: 'Tối', icon: <MoonOutlined />, bg: '#0f172a', border: '#334155' },
              ] as const).map((opt) => {
                const selected = theme === opt.value;
                const cardBg = isDark ? (opt.value === 'dark' ? '#0f172a' : '#111827') : opt.bg;
                const borderColor = selected ? '#6366f1' : opt.border;
                const textColor = isDark ? '#f8fafc' : (opt.value === 'dark' ? '#f8fafc' : '#0f172a');

                return (
                  <Col span={12} key={opt.value}>
                    <div
                      onClick={() => setTheme(opt.value)}
                      style={{
                        cursor: 'pointer',
                        border: `2px solid ${borderColor}`,
                        borderRadius: 12,
                        padding: '16px 20px',
                        background: cardBg,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        transition: 'all 0.2s',
                        boxShadow: selected ? '0 0 0 3px rgba(99,102,241,0.15)' : 'none',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ color: textColor, fontSize: 16 }}>{opt.icon}</span>
                        <span style={{ color: textColor, fontWeight: 500, fontSize: 14 }}>{opt.label}</span>
                      </div>
                      {selected && (
                        <CheckOutlined style={{ color: '#6366f1', fontSize: 14 }} />
                      )}
                    </div>
                  </Col>
                );
              })}
            </Row>

            <div style={{
              marginTop: 16, padding: '12px 16px',
              background: isDark ? '#0f172a' : '#f8fafc', borderRadius: 10,
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            }}>
              <Text style={{ fontSize: 13, color: isDark ? '#94a3b8' : '#64748b' }}>
                {theme === 'dark' ? '🌙 Đang dùng chế độ tối' : '☀️ Đang dùng chế độ sáng'}
              </Text>
              <Switch
                checked={theme === 'dark'}
                onChange={(checked) => setTheme(checked ? 'dark' : 'light')}
                checkedChildren={<MoonOutlined />}
                unCheckedChildren={<SunOutlined />}
              />
            </div>
          </Card>
        </Col>

        {/* Ngôn ngữ */}
        <Col xs={24} lg={12}>
          <Card
            className="admin-page-card"
            styles={{ body: { padding: '24px 28px' } }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
              <div style={{
                width: 40, height: 40, borderRadius: 10,
                background: 'linear-gradient(135deg, #06b6d4, #0891b2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <GlobalOutlined style={{ color: '#fff', fontSize: 18 }} />
              </div>
              <div>
                <Title level={5} style={{ margin: 0 }}>Ngôn ngữ</Title>
                <Text type="secondary" style={{ fontSize: 13 }}>Chọn ngôn ngữ hiển thị</Text>
              </div>
            </div>

            <Row gutter={[12, 12]}>
              {([
                { value: 'vi', label: 'Tiếng Việt', flag: '🇻🇳', desc: 'Vietnamese' },
                { value: 'en', label: 'English', flag: '🇬🇧', desc: 'Tiếng Anh' },
              ] as const).map((opt) => {
                const selected = language === opt.value;
                const cardBg = isDark ? (selected ? '#042f33' : '#0f172a') : (selected ? '#ecfeff' : '#fff');
                const borderColor = selected ? '#06b6d4' : (isDark ? '#3d3d3d' : '#e2e8f0');
                const labelColor = isDark ? '#f8fafc' : '#0f172a';

                return (
                  <Col span={12} key={opt.value}>
                    <div
                      onClick={() => setLanguage(opt.value)}
                      style={{
                        cursor: 'pointer',
                        border: `2px solid ${borderColor}`,
                        borderRadius: 12,
                        padding: '16px 20px',
                        background: cardBg,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        transition: 'all 0.2s',
                        boxShadow: selected ? '0 0 0 3px rgba(6,182,212,0.15)' : 'none',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <span style={{ fontSize: 22 }}>{opt.flag}</span>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: 13, color: labelColor }}>{opt.label}</div>
                          <div style={{ fontSize: 11, color: isDark ? '#94a3b8' : '#94a3b8' }}>{opt.desc}</div>
                        </div>
                      </div>
                      {selected && (
                        <CheckOutlined style={{ color: '#06b6d4', fontSize: 14 }} />
                      )}
                    </div>
                  </Col>
                );
              })}
            </Row>

            <div style={{
              marginTop: 16, padding: '12px 16px',
              background: isDark ? '#042f33' : '#f0fdff', borderRadius: 10,
              border: `1px solid ${isDark ? '#064e55' : '#a5f3fc'}`,
            }}>
              <Text style={{ fontSize: 13, color: isDark ? '#06b6d4' : '#0891b2' }}>
                {language === 'vi'
                  ? '🇻🇳 Giao diện đang hiển thị bằng Tiếng Việt'
                  : '🇬🇧 Interface is displayed in English'}
              </Text>
            </div>
          </Card>
        </Col>
      </Row>
    </PageShell>
  );
}