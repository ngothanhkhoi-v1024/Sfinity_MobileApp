import { CrownOutlined } from '@ant-design/icons';
import { Col, Row } from 'antd';
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { formatVnd } from '@/api/subscriptions';
import { StatCard } from '@/components/common/StatCard';

import { CHART_TOOLTIP, ChartCard, formatChartDay, useDashboard } from './DashboardLayout';

export function DashboardRevenue() {
  const { stats, activitySubtitle } = useDashboard();
  if (!stats) return null;

  const revenueChartData = stats.revenue.revenueByDay.map((d) => ({
    ...d,
    label: formatChartDay(d.date),
  }));

  return (
    <>
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

      <Row gutter={[16, 16]} className="dashboard-section">
        <Col xs={24} xl={16}>
          <ChartCard title="Doanh thu VIP theo ngày" subtitle={activitySubtitle}>
            {revenueChartData.length === 0 || revenueChartData.every((d) => d.revenue === 0) ? (
              <div className="dashboard-chart-empty">
                <CrownOutlined />
                <span>Chưa có doanh thu trong khoảng thời gian này</span>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
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
    </>
  );
}
