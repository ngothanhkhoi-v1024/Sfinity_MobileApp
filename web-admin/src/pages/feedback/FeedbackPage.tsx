import { Button, Input, Modal, Select, Space, Table, Tag, Typography, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';
import { SearchOutlined } from '@ant-design/icons';

import { fetchFeedback, replyFeedback, type FeedbackItem } from '@/api/feedback';

export function FeedbackPage() {
  const [data, setData] = useState<FeedbackItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState<'ALL' | 'PENDING' | 'RESOLVED'>('ALL');
  const [replyOpen, setReplyOpen] = useState(false);
  const [selected, setSelected] = useState<FeedbackItem | null>(null);
  const [replyText, setReplyText] = useState('');
  const [searchQuery, setSearchQuery] = useState('');

  // Filter list in memory based on search query
  const filteredData = data.filter((item) => {
    const term = searchQuery.toLowerCase().trim();
    if (!term) return true;
    return (
      item.user?.name?.toLowerCase().includes(term) ||
      item.user?.email?.toLowerCase().includes(term) ||
      item.message?.toLowerCase().includes(term) ||
      item.reply?.toLowerCase().includes(term)
    );
  });

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const resolvedParam = filter === 'ALL' ? undefined : filter === 'RESOLVED';
      setData(await fetchFeedback(resolvedParam));
    } catch {
      message.error('Không tải được phản hồi');
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    load();
  }, [load]);

  const handleReply = async () => {
    if (!selected || !replyText.trim()) return;
    try {
      await replyFeedback(selected.id, replyText);
      message.success('Đã phản hồi');
      setReplyOpen(false);
      setReplyText('');
      load();
    } catch {
      message.error('Gửi phản hồi thất bại');
    }
  };

  const columns: ColumnsType<FeedbackItem> = [
    { title: 'Người gửi', dataIndex: ['user', 'name'] },
    { title: 'Email', dataIndex: ['user', 'email'] },
    { title: 'Nội dung', dataIndex: 'message', ellipsis: true },
    { title: 'Đánh giá', dataIndex: 'rating' },
    {
      title: 'Trạng thái',
      dataIndex: 'resolved',
      render: (v: boolean) => (
        <Tag color={v ? 'green' : 'orange'}>{v ? 'Đã xử lý' : 'Chờ xử lý'}</Tag>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      render: (_, record) =>
        !record.resolved ? (
          <Button
            size="small"
            type="primary"
            onClick={() => {
              setSelected(record);
              setReplyOpen(true);
            }}
          >
            Phản hồi
          </Button>
        ) : (
          <Typography.Text type="secondary">{record.reply}</Typography.Text>
        ),
    },
  ];

  return (
    <div>
      <Typography.Title level={4} style={{ marginTop: 0 }}>
        Phản hồi người dùng
      </Typography.Title>
      <Space style={{ marginBottom: 16 }}>
        <Select
          value={filter}
          style={{ width: 180 }}
          onChange={setFilter}
          options={[
            { value: 'ALL', label: 'Tất cả' },
            { value: 'PENDING', label: 'Chờ xử lý' },
            { value: 'RESOLVED', label: 'Đã xử lý' },
          ]}
        />
        <Button onClick={load}>Làm mới</Button>
      </Space>
      <Table rowKey="id" loading={loading} columns={columns} dataSource={data} pagination={{ pageSize: 10 }} />

      <Modal
        title="Phản hồi"
        open={replyOpen}
        onCancel={() => setReplyOpen(false)}
        onOk={handleReply}
        okText="Gửi"
      >
        <Typography.Paragraph type="secondary">{selected?.message}</Typography.Paragraph>
        <Input.TextArea rows={4} value={replyText} onChange={(e) => setReplyText(e.target.value)} placeholder="Nội dung phản hồi..." />
      </Modal>
    </div>
  );
}
