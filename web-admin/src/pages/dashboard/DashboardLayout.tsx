import { CalendarOutlined, ReloadOutlined } from '@ant-design/icons';
import { Button, Card, DatePicker, Segmented, Spin, Typography, message } from 'antd';
import dayjs, { type Dayjs } from 'dayjs';
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';

import { getDashboardStats, type DashboardStats } from '@/api/dashboard';
import { PageHeader } from '@/components/common/PageHeader';

const { RangePicker } = DatePicker;
const { Text } = Typography;

export type DatePreset = '7d' | '30d' | 'month' | 'all';

export const CHART_TOOLTIP = {
  borderRadius: 10,
  border: '1px solid #e2e8f0',
  fontSize: 13,
  boxShadow: '0 8px 24px rgba(15, 23, 42, 0.08)',
};

export function formatChartDay(iso: string): string {
  const parts = iso.split('-');
  return `${parts[2]}/${parts[1]}`;
}

export function presetToRange(preset: DatePreset): [Dayjs, Dayjs] | null {
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

export function ChartCard({
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
          <Typography.Title level={5} className="dashboard-chart-card__title">
            {title}
          </Typography.Title>
          {subtitle && <Text type="secondary" className="dashboard-chart-card__subtitle">{subtitle}</Text>}
        </div>
      </div>
      {children}
    </Card>
  );
}

interface DashboardContextValue {
  stats: DashboardStats | null;
  loading: boolean;
  dateRange: [Dayjs, Dayjs] | null;
  reload: () => void;
  filterLabel: string;
  activitySubtitle: string;
}

const DashboardContext = createContext<DashboardContextValue | null>(null);

export function useDashboard() {
  const ctx = useContext(DashboardContext);
  if (!ctx) throw new Error('useDashboard must be used within DashboardLayout');
  return ctx;
}

const TABS = [
  { key: '/', label: 'Tổng quan' },
  { key: '/dashboard/revenue', label: 'Doanh thu VIP' },
  { key: '/dashboard/activity', label: 'Hoạt động' },
  { key: '/dashboard/content', label: 'Nội dung' },
] as const;

export function DashboardLayout() {
  const navigate = useNavigate();
  const location = useLocation();
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

  const activeTab = TABS.find((t) => t.key === location.pathname)?.key ?? '/';

  const ctx: DashboardContextValue = {
    stats,
    loading,
    dateRange,
    reload: () => loadStats(dateRange),
    filterLabel,
    activitySubtitle,
  };

  if (loading && !stats) {
    return (
      <div className="dashboard-loading">
        <Spin size="large" />
      </div>
    );
  }

  return (
    <DashboardContext.Provider value={ctx}>
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
              <Button icon={<ReloadOutlined />} loading={loading} onClick={() => loadStats(dateRange)}>
                Làm mới
              </Button>
            </div>
          }
        />

        <div style={{ marginBottom: 20 }}>
          <Segmented
            value={activeTab}
            onChange={(key) => navigate(String(key))}
            options={TABS.map((t) => ({ label: t.label, value: t.key }))}
            block
          />
        </div>

        {stats ? (
          <>
            <Card className="dashboard-filter-banner" bordered={false} style={{ marginBottom: 20 }}>
              <div className="dashboard-filter-banner__inner">
                <div>
                  <Text className="dashboard-filter-banner__label">Khoảng thời gian thống kê</Text>
                  <div className="dashboard-filter-banner__value">{filterLabel}</div>
                </div>
                <div className="dashboard-filter-banner__chips">
                  <span className="dashboard-chip">Người dùng: <strong>{stats.users}</strong></span>
                  <span className="dashboard-chip">Nội dung: <strong>{stats.contents}</strong></span>
                  <span className="dashboard-chip">
                    Chờ xử lý: <strong>{stats.pendingFeedback + stats.pendingReports}</strong>
                  </span>
                </div>
              </div>
            </Card>
            <Outlet />
          </>
        ) : (
          <Card className="admin-page-card dashboard-empty">
            <Text type="secondary">Không tải được dữ liệu thống kê. Vui lòng thử lại sau.</Text>
            <Button type="primary" icon={<ReloadOutlined />} onClick={() => loadStats(dateRange)} style={{ marginTop: 16 }}>
              Thử lại
            </Button>
          </Card>
        )}
      </div>
    </DashboardContext.Provider>
  );
}
