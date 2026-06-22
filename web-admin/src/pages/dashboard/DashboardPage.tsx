import {
  CalendarOutlined,
  CrownOutlined,
  EnvironmentOutlined,
  FileTextOutlined,
  FolderOutlined,
  MessageOutlined,
  ReloadOutlined,
  TeamOutlined,
  UserOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { Button, Card, Col, DatePicker, Row, Segmented, Spin, Typography, message } from 'antd';
import dayjs, { type Dayjs } from 'dayjs';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Area,
  AreaChart,
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

import { getDashboardStats, type DashboardStats } from '@/api/dashboard';
import { formatVnd } from '@/api/subscriptions';
import { PageHeader } from '@/components/common/PageHeader';
import { StatCard } from '@/components/common/StatCard';

const { RangePicker } = DatePicker;
const { Title, Text } = Typography;

type DatePreset = '7d' | '30d' | 'month' | 'all';

const CHART_TOOLTIP = {
  borderRadius: 10,
  border: '1px solid #e2e8f0',
  fontSize: 13,
  boxShadow: '0 8px 24px rgba(15, 23, 42, 0.08)',
};

function formatChartDay(iso: string): string {
  const parts = iso.split('-');
  return `${parts[2]}/${parts[1]}`;
}

function presetToRange(preset: DatePreset): [Dayjs, Dayjs] | null {
  const today = dayjs().endOf('day');
  switch (preset) {
    case '7d':
      return [dayjs().subtract(6, 'day').startOf('day'), today];
    case '30d':
      return [dayjs().subtract(29, 'day').startOf('day'), today];
    case 'month':
      return [dayjs().startOf('month'), today];
    default:
      return null;
  }
}

function ChartCard({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <Card className="admin-page-card dashboard-chart-card" styles={{ body: { padding: '22px 20px 18px' } }}>
      <div className="dashboard-chart-card__header">
        <div>
          <Title level={5} className="dashboard-chart-card__title">
            {title}
          </Title>
          {subtitle && <Text type="secondary" className="dashboard-chart-card__subtitle">{subtitle}</Text>}
        </div>
      </div>
      {children}
    </Card>
  );
}

export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [preset, setPreset] = useState<DatePreset | null>('all');
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  const loadStats = useCallback(async (range: [Dayjs, Dayjs] | null) => {
    setLoading(true);
    try {
      const params = range
        ? { from: range[0].format('YYYY-MM-DD'), to: range[1].format('YYYY-MM-DD') }
        : undefined;
      setStats(await getDashboardStats(params));
    } catch {
      message.error('Không tải được thống kê');
      setStats(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadStats(dateRange);
  }, [dateRange, loadStats]);

  const handlePresetChange = (value: DatePreset) => {
    setPreset(value);
    setDateRange(presetToRange(value));
  };

  const handleRangeChange = (values: [Dayjs | null, Dayjs | null] | null) => {
    if (!values || !values[0] || !values[1]) {
      setPreset('all');
      setDateRange(null);
      return;
    }
    setPreset(null);
    setDateRange([values[0].startOf('day'), values[1].endOf('day')]);
  };

  const filterLabel = useMemo(() => {
    if (stats?.dateRange) {
      return `${dayjs(stats.dateRange.from).format('DD/MM/YYYY')} – ${dayjs(stats.dateRange.to).format('DD/MM/YYYY')}`;
    }
    return 'Toàn thời gian';
  }, [stats?.dateRange]);

  const activitySubtitle = stats
    ? `${dayjs(stats.activityFrom).format('DD/MM')} – ${dayjs(stats.activityTo).format('DD/MM/YYYY')}`
    : '';

  if (loading && !stats) {
    return (
      <div className="dashboard-loading">
        <Spin size="large" />
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="page-enter">
        <PageHeader title="Dashboard" description="Tổng quan hoạt động hệ thống Sfinity" />
        <Card className="admin-page-card dashboard-empty">
          <Text type="secondary">Không tải được dữ liệu thống kê. Vui lòng thử lại sau.</Text>
          <Button type="primary" icon={<ReloadOutlined />} onClick={() => loadStats(dateRange)} style={{ marginTop: 16 }}>
            Thử lại
          </Button>
        </Card>
      </div>
    );
  }

  const totalContents = stats.contents;
  const published = stats.publishedContents;
  const draft = stats.draftContents;
  const pendingTotal = stats.pendingFeedback + stats.pendingReports;
  const publishRate = totalContents > 0 ? Math.round((published / totalContents) * 100) : 0;

  const revenueChartData = stats.revenue.revenueByDay.map((d) => ({
    ...d,
    label: formatChartDay(d.date),
  }));

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

  const activityData = stats.activityByDay.map((d) => ({
    ...d,
    label: formatChartDay(d.date),
    total: d.users + d.documents + d.places + d.feedback,
  }));

  const insights = [
    { label: 'Tỉ lệ xuất bản', value: totalContents > 0 ? `${publishRate}%` : '—', color: '#10b981' },
    { label: 'Nội dung / người dùng', value: stats.users > 0 ? (stats.contents / stats.users).toFixed(1) : '—', color: '#6366f1' },
    { label: 'Tài liệu / địa điểm', value: `${stats.documents} / ${stats.places}`, color: '#8b5cf6' },
    { label: 'Phản hồi trong kỳ', value: String(stats.feedback), color: '#ec4899' },
    { label: 'Chờ xử lý', value: String(pendingTotal), color: '#ef4444' },
    { label: 'Danh mục', value: String(stats.categories), color: '#f59e0b' },
  ];

  return (
    <div className="page-enter dashboard-page">
      <PageHeader
        title="Dashboard"
        description="Tổng quan hoạt động hệ thống Sfinity"
        extra={
          <div className="dashboard-toolbar">
            <Segmented<DatePreset>
              value={preset ?? undefined}
              onChange={handlePresetChange}
              options={[
                { label: '7 ngày', value: '7d' },
                { label: '30 ngày', value: '30d' },
                { label: 'Tháng này', value: 'month' },
                { label: 'Tất cả', value: 'all' },
              ]}
            />
            <RangePicker
              value={dateRange}
              onChange={handleRangeChange}
              allowClear
              format="DD/MM/YYYY"
              placeholder={['Từ ngày', 'Đến ngày']}
              suffixIcon={<CalendarOutlined />}
              className="dashboard-range-picker"
            />
            <Button
              icon={<ReloadOutlined />}
              loading={loading}
              onClick={() => loadStats(dateRange)}
            >
              Làm mới
            </Button>
          </div>
        }
      />

      <Card className="dashboard-filter-banner" bordered={false}>
        <div className="dashboard-filter-banner__inner">
          <div>
            <Text className="dashboard-filter-banner__label">Khoảng thời gian thống kê</Text>
            <div className="dashboard-filter-banner__value">{filterLabel}</div>
          </div>
          <div className="dashboard-filter-banner__chips">
            <span className="dashboard-chip">Người dùng: <strong>{stats.users}</strong></span>
            <span className="dashboard-chip">Nội dung: <strong>{stats.contents}</strong></span>
            <span className="dashboard-chip">Chờ xử lý: <strong>{pendingTotal}</strong></span>
          </div>
        </div>
      </Card>

      <section className="dashboard-section">
        <div className="dashboard-section__title">Doanh thu VIP</div>
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} xl={6}>
            <StatCard
              variant="hero"
              label="Tổng doanh thu"
              value={formatVnd(stats.revenue.totalRevenue)}
              icon={<CrownOutlined />}
              accent="#f59e0b"
              iconBg="#fef3c7"
              hint={`${stats.revenue.transactionCount} giao dịch`}
            />
          </Col>
          <Col xs={24} sm={12} xl={6}>
            <StatCard
              variant="hero"
              label="VIP đang hoạt động"
              value={stats.vipUsers.active}
              icon={<CrownOutlined />}
              accent="#10b981"
              iconBg="#d1fae5"
              hint={`${stats.vipUsers.expired} hết hạn`}
            />
          </Col>
          {stats.revenue.byCycle.map((c) => (
            <Col xs={24} sm={12} xl={6} key={c.cycle}>
              <StatCard
                label={c.cycle === 'yearly' ? 'Gói năm' : 'Gói tháng'}
                value={formatVnd(c.revenue)}
                icon={<CrownOutlined />}
                accent="#8b5cf6"
                iconBg="#f3e8ff"
                hint={`${c.count} GD`}
              />
            </Col>
          ))}
        </Row>
      </section>

      <section className="dashboard-section">
        <div className="dashboard-section__title">Chỉ số chính</div>
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} xl={6}>
            <StatCard variant="hero" label="Người dùng" value={stats.users} icon={<UserOutlined />} accent="#6366f1" iconBg="#eef2ff" hint="Tài khoản USER" />
          </Col>
          <Col xs={24} sm={12} xl={6}>
            <StatCard variant="hero" label="Tổng nội dung" value={stats.contents} icon={<FileTextOutlined />} accent="#8b5cf6" iconBg="#f3e8ff" hint={`${stats.documents} TL · ${stats.places} ĐĐ`} />
          </Col>
          <Col xs={24} sm={12} xl={6}>
            <StatCard variant="hero" label="Đã xuất bản" value={stats.publishedContents} icon={<FileTextOutlined />} accent="#10b981" iconBg="#d1fae5" hint={totalContents > 0 ? `${publishRate}% tổng` : undefined} />
          </Col>
          <Col xs={24} sm={12} xl={6}>
            <StatCard variant="hero" label="Chờ xử lý" value={pendingTotal} icon={<WarningOutlined />} accent="#ef4444" iconBg="#fee2e2" hint={`${stats.pendingFeedback} PH · ${stats.pendingReports} BC`} />
          </Col>
        </Row>
      </section>

      <section className="dashboard-section">
        <div className="dashboard-section__title">Chi tiết</div>
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
        <Col xs={24} xl={16}>
          <ChartCard title="Doanh thu VIP theo ngày" subtitle={activitySubtitle}>
            {revenueChartData.length === 0 || revenueChartData.every((d) => d.revenue === 0) ? (
              <div className="dashboard-chart-empty">
                <CrownOutlined />
                <span>Chưa có doanh thu trong khoảng thời gian này</span>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={280}>
                <BarChart data={revenueChartData} margin={{ top: 8, right: 12, left: -12, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                  <XAxis dataKey="label" tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} />
                  <YAxis
                    tick={{ fontSize: 12, fill: '#64748b' }}
                    axisLine={false}
                    tickLine={false}
                    tickFormatter={(v) => `${Math.round(Number(v) / 1000)}k`}
                  />
                  <Tooltip
                    formatter={(v) => [formatVnd(Number(v ?? 0)), 'Doanh thu']}
                    contentStyle={CHART_TOOLTIP}
                  />
                  <Bar dataKey="revenue" fill="#f59e0b" radius={[8, 8, 0, 0]} name="Doanh thu" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </ChartCard>
        </Col>
        <Col xs={24} xl={8}>
          <ChartCard title="Doanh thu theo gói" subtitle="Phân bổ theo planId">
            {stats.revenue.byPlan.length === 0 ? (
              <div className="dashboard-chart-empty dashboard-chart-empty--sm">
                <CrownOutlined />
                <span>Chưa có dữ liệu</span>
              </div>
            ) : (
              <div className="dashboard-insights">
                {stats.revenue.byPlan.map((p) => (
                  <div key={p.planId} className="dashboard-insight-row">
                    <span>{p.planName}</span>
                    <strong style={{ color: '#f59e0b' }}>{formatVnd(p.revenue)}</strong>
                  </div>
                ))}
              </div>
            )}
          </ChartCard>
        </Col>
      </Row>

      <Row gutter={[16, 16]} className="dashboard-section">
        <Col xs={24} xl={16}>
          <ChartCard title="Hoạt động theo ngày" subtitle={activitySubtitle}>
            {activityData.every((d) => d.total === 0) ? (
              <div className="dashboard-chart-empty">
                <CalendarOutlined />
                <span>Chưa có hoạt động trong khoảng thời gian này</span>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={280}>
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

      <Row gutter={[16, 16]} className="dashboard-section">
        <Col xs={24} lg={14}>
          <ChartCard title="Phân bổ hệ thống" subtitle="So sánh các nhóm dữ liệu">
            <ResponsiveContainer width="100%" height={260}>
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
              <ResponsiveContainer width="100%" height={260}>
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
            <ResponsiveContainer width="100%" height={260}>
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
    </div>
  );
}
