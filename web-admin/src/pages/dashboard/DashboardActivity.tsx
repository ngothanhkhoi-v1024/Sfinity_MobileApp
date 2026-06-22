import { CalendarOutlined } from '@ant-design/icons';
import { Col, Row } from 'antd';
import {
  Area,
  AreaChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { CHART_TOOLTIP, ChartCard, formatChartDay, useDashboard } from './DashboardLayout';

export function DashboardActivity() {
  const { stats, activitySubtitle } = useDashboard();
  if (!stats) return null;

  const activityData = stats.activityByDay.map((d) => ({
    ...d,
    label: formatChartDay(d.date),
    total: d.users + d.documents + d.places + d.feedback,
  }));

  const totalContents = stats.contents;
  const published = stats.publishedContents;
  const pendingTotal = stats.pendingFeedback + stats.pendingReports;
  const publishRate = totalContents > 0 ? Math.round((published / totalContents) * 100) : 0;

  const insights = [
    { label: 'Tỉ lệ xuất bản', value: totalContents > 0 ? `${publishRate}%` : '—', color: '#10b981' },
    { label: 'Nội dung / người dùng', value: stats.users > 0 ? (stats.contents / stats.users).toFixed(1) : '—', color: '#6366f1' },
    { label: 'Tài liệu / địa điểm', value: `${stats.documents} / ${stats.places}`, color: '#8b5cf6' },
    { label: 'Phản hồi trong kỳ', value: String(stats.feedback), color: '#ec4899' },
    { label: 'Chờ xử lý', value: String(pendingTotal), color: '#ef4444' },
    { label: 'Danh mục', value: String(stats.categories), color: '#f59e0b' },
  ];

  return (
    <Row gutter={[16, 16]} className="dashboard-section">
      <Col xs={24} xl={16}>
        <ChartCard title="Hoạt động theo ngày" subtitle={activitySubtitle}>
          {activityData.every((d) => d.total === 0) ? (
            <div className="dashboard-chart-empty">
              <CalendarOutlined />
              <span>Chưa có hoạt động trong khoảng thời gian này</span>
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={activityData} margin={{ top: 8, right: 12, left: -12, bottom: 0 }}>
                <defs>
                  <linearGradient id="gradUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#6366f1" stopOpacity={0.35} />
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="gradDocs" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="label" tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} allowDecimals={false} />
                <Tooltip contentStyle={CHART_TOOLTIP} />
                <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: 12, paddingTop: 8 }} />
                <Area type="monotone" dataKey="users" name="Người dùng" stroke="#6366f1" fill="url(#gradUsers)" strokeWidth={2} />
                <Area type="monotone" dataKey="documents" name="Tài liệu" stroke="#8b5cf6" fill="url(#gradDocs)" strokeWidth={2} />
                <Area type="monotone" dataKey="places" name="Địa điểm" stroke="#a855f7" fill="transparent" strokeWidth={2} />
                <Area type="monotone" dataKey="feedback" name="Phản hồi" stroke="#ec4899" fill="transparent" strokeWidth={2} strokeDasharray="4 4" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </ChartCard>
      </Col>

      <Col xs={24} xl={8}>
        <ChartCard title="Tóm tắt nhanh" subtitle="Tỷ lệ & chỉ số trong kỳ">
          <div className="dashboard-insights">
            {insights.map((item) => (
              <div key={item.label} className="dashboard-insight-row">
                <span>{item.label}</span>
                <strong style={{ color: item.color }}>{item.value}</strong>
              </div>
            ))}
          </div>
        </ChartCard>
      </Col>
    </Row>
  );
}
