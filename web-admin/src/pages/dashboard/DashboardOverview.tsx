import {
  ArrowRightOutlined,
  CrownOutlined,
  EnvironmentOutlined,
  FileTextOutlined,
  LineChartOutlined,
  PieChartOutlined,
  UserOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { Button, Card, Col, Row, Typography } from 'antd';
import { useNavigate } from 'react-router-dom';

import { formatVnd } from '@/api/subscriptions';
import { StatCard } from '@/components/common/StatCard';

import { useDashboard } from './DashboardLayout';

const { Text, Title } = Typography;

const NAV_CARDS = [
  {
    title: 'Doanh thu VIP',
    description: 'Doanh thu, giao dịch và VIP đang hoạt động',
    path: '/dashboard/revenue',
    icon: <CrownOutlined />,
    color: '#f59e0b',
    bg: '#fef3c7',
  },
  {
    title: 'Hoạt động theo ngày',
    description: 'Người dùng, tài liệu, địa điểm và phản hồi',
    path: '/dashboard/activity',
    icon: <LineChartOutlined />,
    color: '#6366f1',
    bg: '#eef2ff',
  },
  {
    title: 'Phân bổ nội dung',
    description: 'Biểu đồ hệ thống, tỉ lệ xuất bản, chờ xử lý',
    path: '/dashboard/content',
    icon: <PieChartOutlined />,
    color: '#8b5cf6',
    bg: '#f3e8ff',
  },
];

export function DashboardOverview() {
  const navigate = useNavigate();
  const { stats } = useDashboard();

  if (!stats) return null;

  const pendingTotal = stats.pendingFeedback + stats.pendingReports;
  const publishRate = stats.contents > 0
    ? Math.round((stats.publishedContents / stats.contents) * 100)
    : 0;

  return (
    <>
      <section className="dashboard-section">
        <div className="dashboard-section__title">Chỉ số nhanh</div>
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} xl={6}>
            <StatCard
              variant="hero"
              label="Người dùng"
              value={stats.users}
              icon={<UserOutlined />}
              accent="#6366f1"
              iconBg="#eef2ff"
            />
          </Col>
          <Col xs={24} sm={12} xl={6}>
            <StatCard
              variant="hero"
              label="Tổng nội dung"
              value={stats.contents}
              icon={<FileTextOutlined />}
              accent="#8b5cf6"
              iconBg="#f3e8ff"
              hint={`${stats.documents} TL · ${stats.places} ĐĐ`}
            />
          </Col>
          <Col xs={24} sm={12} xl={6}>
            <StatCard
              variant="hero"
              label="Doanh thu VIP"
              value={formatVnd(stats.revenue.totalRevenue)}
              icon={<CrownOutlined />}
              accent="#f59e0b"
              iconBg="#fef3c7"
              hint={`${stats.revenue.transactionCount} GD`}
            />
          </Col>
          <Col xs={24} sm={12} xl={6}>
            <StatCard
              variant="hero"
              label="Chờ xử lý"
              value={pendingTotal}
              icon={<WarningOutlined />}
              accent="#ef4444"
              iconBg="#fee2e2"
              hint={`${stats.pendingFeedback} PH · ${stats.pendingReports} BC`}
            />
          </Col>
        </Row>
      </section>

      <section className="dashboard-section">
        <div className="dashboard-section__title">Xem chi tiết</div>
        <Row gutter={[16, 16]}>
          {NAV_CARDS.map((card) => (
            <Col xs={24} md={8} key={card.path}>
              <Card
                className="admin-page-card"
                hoverable
                onClick={() => navigate(card.path)}
                styles={{ body: { padding: '20px 22px' } }}
              >
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
                  <div style={{
                    width: 44, height: 44, borderRadius: 12,
                    background: card.bg, color: card.color,
                    display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20,
                  }}>
                    {card.icon}
                  </div>
                  <div style={{ flex: 1 }}>
                    <Title level={5} style={{ margin: '0 0 4px' }}>{card.title}</Title>
                    <Text type="secondary" style={{ fontSize: 13 }}>{card.description}</Text>
                  </div>
                  <ArrowRightOutlined style={{ color: '#94a3b8', marginTop: 4 }} />
                </div>
              </Card>
            </Col>
          ))}
        </Row>
      </section>

      <section className="dashboard-section">
        <div className="dashboard-section__title">Tóm tắt</div>
        <Row gutter={[16, 16]}>
          <Col xs={12} sm={6}>
            <StatCard label="VIP hoạt động" value={stats.vipUsers.active} icon={<CrownOutlined />} accent="#10b981" iconBg="#d1fae5" />
          </Col>
          <Col xs={12} sm={6}>
            <StatCard label="Đã xuất bản" value={stats.publishedContents} icon={<FileTextOutlined />} accent="#10b981" iconBg="#d1fae5" hint={stats.contents > 0 ? `${publishRate}%` : undefined} />
          </Col>
          <Col xs={12} sm={6}>
            <StatCard label="Tài liệu" value={stats.documents} icon={<FileTextOutlined />} accent="#8b5cf6" iconBg="#f3e8ff" />
          </Col>
          <Col xs={12} sm={6}>
            <StatCard label="Địa điểm" value={stats.places} icon={<EnvironmentOutlined />} accent="#a855f7" iconBg="#f3e8ff" />
          </Col>
        </Row>
      </section>

      <div style={{ textAlign: 'center', marginTop: 8 }}>
        <Button type="link" onClick={() => navigate('/dashboard/revenue')}>
          Xem doanh thu VIP chi tiết <ArrowRightOutlined />
        </Button>
      </div>
    </>
  );
}
