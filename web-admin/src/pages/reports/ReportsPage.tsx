import { Button, Input, Modal, Select, Space, Table, Tag, Typography, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import { fetchReports, resolveReport, type ReportItem } from '@/api/reports';

export function ReportsPage() {
  const [data, setData] = useState<ReportItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState<string | undefined>('PENDING');
  const [resolveOpen, setResolveOpen] = useState(false);
  const [selected, setSelected] = useState<ReportItem | null>(null);
  const [status, setStatus] = useState<'RESOLVED' | 'REJECTED'>('RESOLVED');
  const [resolution, setResolution] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setData(await fetchReports(filter));
    } catch {
      message.error('Không tải được báo cáo');
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    load();
  }, [load]);

  const handleResolve = async () => {
    if (!selected) return;
    try {
      await resolveReport(selected.id, { status, resolution });
      message.success('Đã xử lý báo cáo');
      setResolveOpen(false);
      load();
    } catch {
      message.error('Xử lý thất bại');
    }
  };

  const columns: ColumnsType<ReportItem> = [
    { title: 'Người gửi', dataIndex: ['user', 'name'] },
    { title: 'Loại', dataIndex: 'targetType' },
    { title: 'Lý do', dataIndex: 'reason', ellipsis: true },
    { title: 'Mô tả', dataIndex: 'description', ellipsis: true },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      render: (s: string) => {
        const color = s === 'PENDING' ? 'orange' : s === 'RESOLVED' ? 'green' : 'red';
        return <Tag color={color}>{s}</Tag>;
      },
    },
    {
      title: 'Thao tác',
      key: 'actions',
      render: (_, record) =>
        record.status === 'PENDING' ? (
          <Button
            size="small"
            type="primary"
            onClick={() => {
              setSelected(record);
              setStatus('RESOLVED');
              setResolution('');
              setResolveOpen(true);
            }}
          >
            Xử lý
          </Button>
        ) : (
          <Typography.Text type="secondary">{record.resolution}</Typography.Text>
        ),
    },
  ];

  return (
    <div>
      <Typography.Title level={4} style={{ marginTop: 0 }}>
        Báo cáo vi phạm
      </Typography.Title>
      <Space style={{ marginBottom: 16 }}>
        <Select
          value={filter}
          style={{ width: 160 }}
          onChange={setFilter}
          options={[
            { value: 'PENDING', label: 'Chờ xử lý' },
            { value: 'RESOLVED', label: 'Đã xử lý' },
            { value: 'REJECTED', label: 'Từ chối' },
          ]}
        />
        <Button onClick={load}>Làm mới</Button>
      </Space>
      <Table rowKey="id" loading={loading} columns={columns} dataSource={data} />

      <Modal
        title="Xử lý báo cáo"
        open={resolveOpen}
        onCancel={() => setResolveOpen(false)}
        onOk={handleResolve}
        okText="Lưu"
      >
        <Space direction="vertical" style={{ width: '100%' }}>
          <Select
            value={status}
            onChange={setStatus}
            options={[
              { value: 'RESOLVED', label: 'Đã xử lý' },
              { value: 'REJECTED', label: 'Từ chối' },
            ]}
          />
          <Typography.Text>Ghi chú xử lý:</Typography.Text>
          <Input.TextArea rows={4} value={resolution} onChange={(e) => setResolution(e.target.value)} />
        </Space>
      </Modal>
    </div>
  );
}
