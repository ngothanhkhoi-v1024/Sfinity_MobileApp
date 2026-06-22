import {
  EnvironmentOutlined,
  FileTextOutlined,
  FolderOutlined,
  MessageOutlined,
  TeamOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { Col, Row } from 'antd';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { StatCard } from '@/components/common/StatCard';

import { CHART_TOOLTIP, ChartCard, useDashboard } from './DashboardLayout';

export function DashboardContent() {
  const { stats } = useDashboard();
  if (!stats) return null;

  const totalContents = stats.contents;
  const published = stats.publishedContents;
  const draft = stats.draftContents;

  const barData = [
    { name: 'Người dùng', value: stats.users, fill: '#6366f1' },
    { name: 'Tài liệu', value: stats.documents, fill: '#8b5cf6' },
    { name: 'Địa điểm', value: stats.places, fill: '#a855f7' },
    { name: 'Đã xuất bản', value: stats.publishedContents, fill: '#10b981' },
    { name: 'Danh mục', value: stats.categories, fill: '#f59e0b' },
    { name: 'Quản trị', value: stats.admins, fill: '#0ea5e9' },
  ];

  const pieData = [
    { name: 'Đã xuất bản', value: published, color: '#10b981' },
    { name: 'Nháp', value: draft, color: '#cbd5e1' },
  ];

  const pendingData = [
    { name: 'Phản hồi', value: stats.pendingFeedback, fill: '#ec4899' },
    { name: 'Báo cáo', value: stats.pendingReports, fill: '#ef4444' },
  ];

  return (
    <>
      <section className="dashboard-section">
        <div className="dashboard-section__title">Chi tiết nội dung</div>
        <Row gutter={[16, 16]}>
          <Col xs={12} sm={8} lg={6} xl={4}>
            <StatCard label="Tài liệu" value={stats.documents} icon={<FileTextOutlined />} accent="#8b5cf6" iconBg="#f3e8ff" />
          </Col>
          <Col xs={12} sm={8} lg={6} xl={4}>
            <StatCard label="Địa điểm" value={stats.places} icon={<EnvironmentOutlined />} accent="#a855f7" iconBg="#f3e8ff" />
          </Col>
          <Col xs={12} sm={8} lg={6} xl={4}>
            <StatCard label="Danh mục" value={stats.categories} icon={<FolderOutlined />} accent="#f59e0b" iconBg="#fef3c7" />
          </Col>
          <Col xs={12} sm={8} lg={6} xl={4}>
            <StatCard label="Quản trị viên" value={stats.admins} icon={<TeamOutlined />} accent="#0ea5e9" iconBg="#e0f2fe" />
          </Col>
          <Col xs={12} sm={8} lg={6} xl={4}>
            <StatCard label="Phản hồi" value={stats.feedback} icon={<MessageOutlined />} accent="#ec4899" iconBg="#fce7f3" />
          </Col>
          <Col xs={12} sm={8} lg={6} xl={4}>
            <StatCard label="Báo cáo chờ" value={stats.pendingReports} icon={<WarningOutlined />} accent="#ef4444" iconBg="#fee2e2" />
          </Col>
        </Row>
      </section>

      <Row gutter={[16, 16]} className="dashboard-section">
        <Col xs={24} lg={14}>
          <ChartCard title="Phân bổ hệ thống" subtitle="So sánh các nhóm dữ liệu">
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={barData} barSize={36} margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} allowDecimals={false} />
                <Tooltip cursor={{ fill: 'rgba(99,102,241,0.06)' }} contentStyle={CHART_TOOLTIP} />
                <Bar dataKey="value" radius={[8, 8, 0, 0]} name="Số lượng">
                  {barData.map((entry, i) => (
                    <Cell key={i} fill={entry.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
        </Col>

        <Col xs={24} sm={12} lg={5}>
          <ChartCard title="Tỉ lệ nội dung">
            {totalContents === 0 ? (
              <div className="dashboard-chart-empty dashboard-chart-empty--sm">
                <FileTextOutlined />
                <span>Chưa có nội dung</span>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={280}>
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius={58} outerRadius={86} paddingAngle={4} dataKey="value">
                    {pieData.map((entry, i) => (
                      <Cell key={i} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip contentStyle={CHART_TOOLTIP} />
                  <Legend iconType="circle" iconSize={8} formatter={(v) => <span style={{ fontSize: 12, color: '#475569' }}>{v}</span>} />
                </PieChart>
              </ResponsiveContainer>
            )}
          </ChartCard>
        </Col>

        <Col xs={24} sm={12} lg={5}>
          <ChartCard title="Chờ xử lý">
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={pendingData} layout="vertical" barSize={22} margin={{ top: 8, right: 16, left: 4, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" horizontal={false} />
                <XAxis type="number" tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} allowDecimals={false} />
                <YAxis type="category" dataKey="name" tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} width={72} />
                <Tooltip cursor={{ fill: 'rgba(239,68,68,0.06)' }} contentStyle={CHART_TOOLTIP} />
                <Bar dataKey="value" radius={[0, 8, 8, 0]} name="Số lượng">
                  {pendingData.map((entry, i) => (
                    <Cell key={i} fill={entry.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
        </Col>
      </Row>
    </>
  );
}
