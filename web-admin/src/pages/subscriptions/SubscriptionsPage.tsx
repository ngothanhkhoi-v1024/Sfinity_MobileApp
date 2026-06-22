import {
  CrownOutlined,
  ReloadOutlined,
  SearchOutlined,
} from '@ant-design/icons';
import {
  Button,
  Card,
  Col,
  DatePicker,
  Input,
  Row,
  Select,
  Statistic,
  Table,
  Tag,
  Typography,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import dayjs, { type Dayjs } from 'dayjs';
import { useCallback, useEffect, useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import {
  fetchRevenueStats,
  fetchTransactions,
  formatVnd,
  type PaymentTransaction,
  type RevenueStats,
} from '@/api/subscriptions';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';
import { StatCard } from '@/components/common/StatCard';

const { RangePicker } = DatePicker;
const { Text } = Typography;

const STATUS_COLORS: Record<string, string> = {
  SUCCESS: 'green',
  PENDING: 'gold',
  FAILED: 'red',
  CANCELED: 'default',
};

export function SubscriptionsPage() {
  const [revenue, setRevenue] = useState<RevenueStats | null>(null);
  const [transactions, setTransactions] = useState<PaymentTransaction[]>([]);
  const [loading, setLoading] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string | undefined>();
  const [search, setSearch] = useState('');
  const [dateRange, setDateRange] = useState<[Dayjs, Dayjs] | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const params = dateRange
        ? {
            from: dateRange[0].format('YYYY-MM-DD'),
            to: dateRange[1].format('YYYY-MM-DD'),
          }
        : undefined;

      const [rev, txs] = await Promise.all([
        fetchRevenueStats(params),
        fetchTransactions({ ...params, status: statusFilter, limit: 200 }),
      ]);
      setRevenue(rev);
      setTransactions(txs);
    } catch {
      message.error('Không tải được dữ liệu gói VIP');
    } finally {
      setLoading(false);
    }
  }, [dateRange, statusFilter]);

  useEffect(() => {
    load();
  }, [load]);

  const filteredTx = transactions.filter((tx) => {
    if (!search.trim()) return true;
    const q = search.toLowerCase();
    return (
      tx.orderId?.toLowerCase().includes(q) ||
      tx.userEmail?.toLowerCase().includes(q) ||
      tx.userName?.toLowerCase().includes(q)
    );
  });

  const revenueChartData =
    revenue?.revenueByDay.map((d) => ({
      ...d,
      label: dayjs(d.date).format('DD/MM'),
    })) ?? [];

  const columns: ColumnsType<PaymentTransaction> = [
    {
      title: 'Mã đơn',
      dataIndex: 'orderId',
      ellipsis: true,
      width: 160,
    },
    {
      title: 'Người dùng',
      key: 'user',
      render: (_, r) => (
        <div>
          <div>{r.userName ?? '—'}</div>
          <Text type="secondary" style={{ fontSize: 12 }}>
            {r.userEmail}
          </Text>
        </div>
      ),
    },
    {
      title: 'Gói',
      key: 'plan',
      width: 120,
      render: (_, r) => (
        <span>
          {(r.planId ?? 'pro').toUpperCase()} · {r.cycle === 'yearly' ? 'Năm' : 'Tháng'}
        </span>
      ),
    },
    {
      title: 'Số tiền',
      dataIndex: 'amount',
      width: 130,
      render: (v: number) => <strong>{formatVnd(v ?? 0)}</strong>,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      width: 110,
      render: (s: string) => (
        <Tag color={STATUS_COLORS[s] ?? 'default'} style={{ borderRadius: 6 }}>
          {s}
        </Tag>
      ),
    },
    {
      title: 'Thanh toán',
      dataIndex: 'paidAt',
      width: 140,
      render: (v?: string) => (v ? dayjs(v).format('DD/MM/YYYY HH:mm') : '—'),
    },
  ];

  return (
    <PageShell>
      <PageHeader
        title="Gói VIP & Doanh thu"
        description="Theo dõi giao dịch thanh toán và doanh thu từ các gói đăng ký"
        extra={
          <Button icon={<ReloadOutlined />} loading={loading} onClick={load}>
            Làm mới
          </Button>
        }
      />

      <div className="admin-table-toolbar" style={{ marginBottom: 16, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
        <RangePicker
          value={dateRange}
          onChange={(v) => setDateRange(v?.[0] && v[1] ? [v[0], v[1]] : null)}
          format="DD/MM/YYYY"
          allowClear
          placeholder={['Từ ngày', 'Đến ngày']}
        />
        <Select
          allowClear
          placeholder="Trạng thái GD"
          style={{ width: 160 }}
          value={statusFilter}
          onChange={setStatusFilter}
          options={[
            { value: 'SUCCESS', label: 'Thành công' },
            { value: 'PENDING', label: 'Đang chờ' },
            { value: 'FAILED', label: 'Thất bại' },
          ]}
        />
        <Input
          placeholder="Tìm mã đơn, email..."
          prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ width: 260 }}
          allowClear
        />
      </div>

      <Row gutter={[16, 16]} style={{ marginBottom: 20 }}>
        <Col xs={24} sm={12} xl={6}>
          <StatCard
            variant="hero"
            label="Tổng doanh thu"
            value={formatVnd(revenue?.totalRevenue ?? 0)}
            icon={<CrownOutlined />}
            accent="#f59e0b"
            iconBg="#fef3c7"
            hint={`${revenue?.transactionCount ?? 0} giao dịch thành công`}
          />
        </Col>
        <Col xs={24} sm={12} xl={6}>
          <StatCard
            variant="hero"
            label="VIP đang hoạt động"
            value={revenue?.vipUsers.active ?? 0}
            icon={<CrownOutlined />}
            accent="#10b981"
            iconBg="#d1fae5"
            hint={`${revenue?.vipUsers.expired ?? 0} đã hết hạn`}
          />
        </Col>
        {revenue?.byPlan.map((p) => (
          <Col xs={24} sm={12} xl={6} key={p.planId}>
            <Card className="admin-page-card" size="small">
              <Statistic
                title={`Gói ${p.planName}`}
                value={formatVnd(p.revenue)}
                valueStyle={{ fontSize: 20, color: '#6366f1' }}
              />
              <Text type="secondary">{p.count} giao dịch</Text>
            </Card>
          </Col>
        ))}
      </Row>

      {revenueChartData.length > 0 && (
        <Card className="admin-page-card" style={{ marginBottom: 20 }} title="Doanh thu theo ngày">
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={revenueChartData} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
              <XAxis dataKey="label" tick={{ fontSize: 12, fill: '#64748b' }} />
              <YAxis
                tick={{ fontSize: 12, fill: '#64748b' }}
                tickFormatter={(v) => `${Math.round(v / 1000)}k`}
              />
              <Tooltip
                formatter={(v) => [formatVnd(Number(v ?? 0)), 'Doanh thu']}
                contentStyle={{ borderRadius: 10, border: '1px solid #e2e8f0' }}
              />
              <Bar dataKey="revenue" fill="#f59e0b" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      )}

      <Card className="admin-page-card" title="Lịch sử giao dịch">
        <Table
          className="admin-table"
          rowKey="id"
          loading={loading}
          columns={columns}
          dataSource={filteredTx}
          pagination={{ pageSize: 15, showSizeChanger: false }}
          scroll={{ x: 900 }}
        />
      </Card>
    </PageShell>
  );
}
