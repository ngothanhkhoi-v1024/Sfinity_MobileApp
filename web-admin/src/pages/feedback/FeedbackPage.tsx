import { Button, Input, Modal, Table, Tag, Typography, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';
import { SearchOutlined } from '@ant-design/icons';

import { fetchFeedback, replyFeedback, type FeedbackItem } from '@/api/feedback';

export function FeedbackPage() {
  const [data, setData] = useState<FeedbackItem[]>([]);
  const [loading, setLoading] = useState(false);
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
      setData(await fetchFeedback());
    } catch {
      message.error('Không tải được phản hồi');
    } finally {
      setLoading(false);
    }
  }, []);

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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <Typography.Title level={4} style={{ margin: 0 }}>
          Phản hồi người dùng
        </Typography.Title>
        <div style={{ display: 'flex', gap: 16 }}>
          <Input
            placeholder="Tìm tên, email, nội dung..."
            prefix={<SearchOutlined />}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{ width: 320 }}
            allowClear
          />
        </div>
      </div>
      <Table rowKey="id" loading={loading} columns={columns} dataSource={filteredData} pagination={{ pageSize: 10 }} />

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
