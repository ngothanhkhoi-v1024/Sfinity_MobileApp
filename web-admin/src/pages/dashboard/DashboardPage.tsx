import {
  EnvironmentOutlined,
  FileTextOutlined,
  FolderOutlined,
  MessageOutlined,
  TeamOutlined,
  UserOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { Card, Col, Row, Spin, Typography, message } from 'antd';
import { useEffect, useState } from 'react';
import {
  Bar, BarChart, CartesianGrid, Cell, Legend,
  Pie, PieChart, PolarAngleAxis, PolarGrid,
  Radar, RadarChart,
  ResponsiveContainer, Tooltip, XAxis, YAxis,
} from 'recharts';

import { getDashboardStats, type DashboardStats } from '@/api/dashboard';
import { PageHeader } from '@/components/common/PageHeader';
import { StatCard } from '@/components/common/StatCard';

const { Title } = Typography;

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

  if (!stats) {
    return (
      <div className="page-enter">
        <PageHeader
          title="Dashboard"
          description="Tổng quan hoạt động hệ thống Sfinity"
        />
        <Card className="admin-page-card" style={{ textAlign: 'center', padding: 48 }}>
          <Typography.Text type="secondary">Không tải được dữ liệu thống kê. Vui lòng thử lại sau.</Typography.Text>
        </Card>
      </div>
    );
  }

  // Dữ liệu cho Bar chart — tổng quan hệ thống
  const barData = [
    { name: 'Người dùng', value: stats.users, fill: '#6366f1' },
    { name: 'Tài liệu', value: stats.documents, fill: '#8b5cf6' },
    { name: 'Địa điểm', value: stats.places, fill: '#a855f7' },
    { name: 'Đã xuất bản', value: stats.publishedContents, fill: '#10b981' },
    { name: 'Danh mục', value: stats.categories, fill: '#f59e0b' },
    { name: 'Quản trị viên', value: stats.admins, fill: '#0ea5e9' },
  ];

  // Dữ liệu cho Pie chart — tỉ lệ nội dung
  const totalContents = stats.contents;
  const published = stats.publishedContents;
  const draft = stats.draftContents;
  const pieData = [
    { name: 'Đã xuất bản', value: published, color: '#10b981' },
    { name: 'Nháp', value: draft, color: '#e2e8f0' },
  ];

  // Dữ liệu cho Bar chart — chờ xử lý
  const pendingData = [
    { name: 'Phản hồi', value: stats.pendingFeedback, fill: '#ec4899' },
    { name: 'Báo cáo', value: stats.pendingReports, fill: '#ef4444' },
  ];

  const radarMax = Math.max(
    stats.users,
    stats.contents,
    stats.categories,
    stats.pendingFeedback,
    stats.pendingReports,
    1,
  );
  const radarData = [
    { subject: 'Người dùng', value: Math.round((stats.users / radarMax) * 100) },
    { subject: 'Nội dung', value: Math.round((stats.contents / radarMax) * 100) },
    { subject: 'Danh mục', value: Math.round((stats.categories / radarMax) * 100) },
    { subject: 'Phản hồi', value: Math.round((stats.pendingFeedback / radarMax) * 100) },
    { subject: 'Báo cáo', value: Math.round((stats.pendingReports / radarMax) * 100) },
  ];

  return (
    <div className="page-enter">
      <PageHeader
        title="Dashboard"
        description="Tổng quan hoạt động hệ thống Sfinity"
      />

      {/* Stat cards */}
      <Row gutter={[20, 20]}>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard label="Người dùng" value={stats.users} icon={<UserOutlined />} accent="#6366f1" iconBg="#eef2ff" />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard label="Tài liệu" value={stats.documents} icon={<FileTextOutlined />} accent="#8b5cf6" iconBg="#f3e8ff" />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard label="Địa điểm" value={stats.places} icon={<EnvironmentOutlined />} accent="#a855f7" iconBg="#f3e8ff" />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard label="Đã xuất bản" value={stats.publishedContents} icon={<FileTextOutlined />} accent="#10b981" iconBg="#d1fae5" />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard label="Quản trị viên" value={stats.admins} icon={<TeamOutlined />} accent="#0ea5e9" iconBg="#e0f2fe" />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard label="Danh mục" value={stats.categories} icon={<FolderOutlined />} accent="#f59e0b" iconBg="#fef3c7" />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard label="Phản hồi chờ xử lý" value={stats.pendingFeedback} icon={<MessageOutlined />} accent="#ec4899" iconBg="#fce7f3" />
        </Col>
        <Col xs={24} sm={12} lg={8} xl={6}>
          <StatCard label="Báo cáo chờ xử lý" value={stats.pendingReports} icon={<WarningOutlined />} accent="#ef4444" iconBg="#fee2e2" />
        </Col>
      </Row>

      {/* Charts row 1 */}
      <Row gutter={[20, 20]} style={{ marginTop: 28 }}>

        {/* Bar chart — tổng quan */}
        <Col xs={24} lg={16}>
          <Card className="admin-page-card" styles={{ body: { padding: '24px 20px' } }}>
            <Title level={5} style={{ margin: '0 0 20px', color: '#0f172a' }}>Tổng quan hệ thống</Title>
            <ResponsiveContainer width="100%" height={240}>
              <BarChart data={barData} barSize={40} margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} allowDecimals={false} />
                <Tooltip cursor={{ fill: 'rgba(99,102,241,0.06)' }} contentStyle={{ borderRadius: 10, border: '1px solid #e2e8f0', fontSize: 13 }} />
                <Bar dataKey="value" radius={[6, 6, 0, 0]} name="Số lượng">
                  {barData.map((entry, i) => <Cell key={i} fill={entry.fill} />)}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </Card>
        </Col>

        {/* Tóm tắt nhanh */}
        <Col xs={24} lg={8}>
          <Card className="admin-page-card" styles={{ body: { padding: '24px 20px' } }} style={{ height: '100%' }}>
            <Title level={5} style={{ margin: '0 0 16px', color: '#0f172a' }}>Tóm tắt nhanh</Title>
            {[
              {
                label: 'Tỉ lệ xuất bản',
                value: totalContents > 0 ? `${Math.round((published / totalContents) * 100)}%` : '—',
                color: '#10b981',
              },
              {
                label: 'Nội dung / người dùng',
                value: stats.users > 0 ? (stats.contents / stats.users).toFixed(1) : '—',
                color: '#6366f1',
              },
              {
                label: 'Tài liệu / địa điểm',
                value: `${stats.documents} / ${stats.places}`,
                color: '#8b5cf6',
              },
              {
                label: 'Tổng chờ xử lý',
                value: String(stats.pendingFeedback + stats.pendingReports),
                color: '#ef4444',
              },
              {
                label: 'Tổng danh mục',
                value: String(stats.categories),
                color: '#f59e0b',
              },
              {
                label: 'Tổng quản trị viên',
                value: String(stats.admins),
                color: '#0ea5e9',
              },
            ].map((item) => (
              <div
                key={item.label}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '11px 0',
                  borderBottom: '1px solid #f1f5f9',
                }}
              >
                <span style={{ fontSize: 13, color: '#64748b' }}>{item.label}</span>
                <span style={{ fontSize: 16, fontWeight: 700, color: item.color }}>{item.value}</span>
              </div>
            ))}
          </Card>
        </Col>
      </Row>

      {/* Charts row 2 */}
      <Row gutter={[20, 20]} style={{ marginTop: 20 }}>

        {/* Donut — tỉ lệ nội dung — fix empty state */}
        <Col xs={24} sm={12} lg={8}>
          <Card className="admin-page-card" styles={{ body: { padding: '24px 20px' } }}>
            <Title level={5} style={{ margin: '0 0 4px', color: '#0f172a' }}>Tỉ lệ nội dung</Title>
            {totalContents === 0 ? (
              <div style={{ height: 220, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: '#94a3b8' }}>
                <FileTextOutlined style={{ fontSize: 36, marginBottom: 10 }} />
                <span style={{ fontSize: 13 }}>Chưa có nội dung</span>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={220}>
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius={60} outerRadius={88} paddingAngle={3} dataKey="value">
                    {pieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                  </Pie>
                  <Tooltip contentStyle={{ borderRadius: 10, border: '1px solid #e2e8f0', fontSize: 13 }} />
                  <Legend iconType="circle" iconSize={9} formatter={(v) => <span style={{ fontSize: 12, color: '#475569' }}>{v}</span>} />
                </PieChart>
              </ResponsiveContainer>
            )}
          </Card>
        </Col>

        {/* Bar — chờ xử lý */}
        <Col xs={24} sm={12} lg={8}>
          <Card className="admin-page-card" styles={{ body: { padding: '24px 20px' } }}>
            <Title level={5} style={{ margin: '0 0 4px', color: '#0f172a' }}>Mục chờ xử lý</Title>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={pendingData} barSize={56} margin={{ top: 16, right: 8, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 13, fill: '#64748b' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} allowDecimals={false} />
                <Tooltip cursor={{ fill: 'rgba(239,68,68,0.06)' }} contentStyle={{ borderRadius: 10, border: '1px solid #e2e8f0', fontSize: 13 }} />
                <Bar dataKey="value" radius={[6, 6, 0, 0]} name="Số lượng">
                  {pendingData.map((entry, i) => <Cell key={i} fill={entry.fill} />)}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </Card>
        </Col>

        {/* Radar — phân bổ hệ thống */}
        <Col xs={24} lg={8}>
          <Card className="admin-page-card" styles={{ body: { padding: '24px 20px' } }}>
            <Title level={5} style={{ margin: '0 0 4px', color: '#0f172a' }}>Phân bổ hệ thống</Title>
            <ResponsiveContainer width="100%" height={220}>
              <RadarChart
                cx="50%"
                cy="50%"
                outerRadius={80}
                data={radarData}
              >
                <PolarGrid stroke="#e2e8f0" />
                <PolarAngleAxis dataKey="subject" tick={{ fontSize: 11, fill: '#64748b' }} />
                <Radar name="Tương đối (%)" dataKey="value" stroke="#6366f1" fill="#6366f1" fillOpacity={0.18} strokeWidth={2} />
                <Tooltip
                  formatter={(value) => [`${value ?? 0}%`, 'Tương đối']}
                  contentStyle={{ borderRadius: 10, border: '1px solid #e2e8f0', fontSize: 13 }}
                />
              </RadarChart>
            </ResponsiveContainer>
          </Card>
        </Col>

      </Row>
    </div>
  );
}