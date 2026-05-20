import {
  FileTextOutlined,
  FolderOutlined,
  MessageOutlined,
  TeamOutlined,
  UserOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { Col, Row, Spin, message } from 'antd';
import { useEffect, useState } from 'react';

import { getDashboardStats, type DashboardStats } from '@/api/dashboard';
import { PageHeader } from '@/components/common/PageHeader';
import { StatCard } from '@/components/common/StatCard';

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
    return <Spin size="large" style={{ display: 'block', margin: '120px auto' }} />;
  }

  return (
    <div className="page-enter">
      <PageHeader
        title="Dashboard"
        description="Tổng quan hoạt động hệ thống Sfinity hôm nay"
      />

      <Row gutter={[20, 20]}>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard
            label="Người dùng"
            value={stats?.users ?? 0}
            icon={<UserOutlined />}
            accent="#6366f1"
            iconBg="#eef2ff"
          />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard
            label="Nội dung"
            value={stats?.contents ?? 0}
            icon={<FileTextOutlined />}
            accent="#8b5cf6"
            iconBg="#f3e8ff"
          />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard
            label="Đã xuất bản"
            value={stats?.publishedContents ?? 0}
            icon={<FileTextOutlined />}
            accent="#10b981"
            iconBg="#d1fae5"
          />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard
            label="Quản trị viên"
            value={stats?.admins ?? 0}
            icon={<TeamOutlined />}
            accent="#0ea5e9"
            iconBg="#e0f2fe"
          />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard
            label="Danh mục"
            value={stats?.categories ?? 0}
            icon={<FolderOutlined />}
            accent="#f59e0b"
            iconBg="#fef3c7"
          />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard
            label="Phản hồi chờ xử lý"
            value={stats?.pendingFeedback ?? 0}
            icon={<MessageOutlined />}
            accent="#ec4899"
            iconBg="#fce7f3"
          />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard
            label="Báo cáo chờ xử lý"
            value={stats?.pendingReports ?? 0}
            icon={<WarningOutlined />}
            accent="#ef4444"
            iconBg="#fee2e2"
          />
        </Col>
      </Row>
    </div>
  );
}
