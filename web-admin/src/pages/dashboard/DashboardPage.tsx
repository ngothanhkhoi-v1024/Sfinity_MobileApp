import { FileTextOutlined, MessageOutlined, TeamOutlined, UserOutlined, WarningOutlined } from '@ant-design/icons';
import { Card, Col, Row, Spin, Statistic, Typography, message } from 'antd';
import { useEffect, useState } from 'react';

import { getDashboardStats, type DashboardStats } from '@/api/dashboard';

export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDashboardStats()
      .then(setStats)
      .catch(() => message.error('Không tải được thống kê'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return <Spin size="large" style={{ display: 'block', margin: '80px auto' }} />;
  }

  return (
    <div>
      <Typography.Title level={4} style={{ marginTop: 0 }}>
        Dashboard
      </Typography.Title>
      <Typography.Paragraph type="secondary">
        Tổng quan hệ thống Sfinity
      </Typography.Paragraph>

      <Row gutter={[16, 16]} style={{ marginTop: 24 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Người dùng" value={stats?.users ?? 0} prefix={<UserOutlined />} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Nội dung" value={stats?.contents ?? 0} prefix={<FileTextOutlined />} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Đã xuất bản" value={stats?.publishedContents ?? 0} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Admin" value={stats?.admins ?? 0} prefix={<TeamOutlined />} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic title="Danh mục" value={stats?.categories ?? 0} />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Phản hồi chờ xử lý"
              value={stats?.pendingFeedback ?? 0}
              prefix={<MessageOutlined />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card>
            <Statistic
              title="Báo cáo chờ xử lý"
              value={stats?.pendingReports ?? 0}
              prefix={<WarningOutlined />}
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
}
