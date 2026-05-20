import { Button, Form, Input, Modal, Table, Typography, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import { fetchNotificationHistory, sendNotification, type NotificationItem } from '@/api/notifications';
import { fetchUsers, type UserRecord } from '@/api/users';

export function NotificationsPage() {
  const [history, setHistory] = useState<NotificationItem[]>([]);
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [form] = Form.useForm();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [noti, userList] = await Promise.all([
        fetchNotificationHistory(),
        fetchUsers(),
      ]);
      setHistory(noti);
      setUsers(userList.filter((u) => u.role === 'user'));
    } catch {
      message.error('Không tải được dữ liệu');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const handleSend = async () => {
    const values = await form.validateFields();
    try {
      const result = await sendNotification(values);
      message.success(`Đã gửi thông báo (${JSON.stringify(result)})`);
      setModalOpen(false);
      form.resetFields();
      load();
    } catch {
      message.error('Gửi thất bại');
    }
  };

  const columns: ColumnsType<NotificationItem> = [
    { title: 'Tiêu đề', dataIndex: 'title' },
    { title: 'Nội dung', dataIndex: 'body', ellipsis: true },
    { title: 'Người nhận', dataIndex: ['user', 'name'] },
    { title: 'Đã đọc', dataIndex: 'read', render: (v: boolean) => (v ? 'Có' : 'Chưa') },
    { title: 'Thời gian', dataIndex: 'createdAt', render: (v: string) => new Date(v).toLocaleString('vi-VN') },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <Typography.Title level={4} style={{ margin: 0 }}>
          Thông báo
        </Typography.Title>
        <Button type="primary" onClick={() => setModalOpen(true)}>
          Gửi thông báo
        </Button>
      </div>

      <Table rowKey="id" loading={loading} columns={columns} dataSource={history} pagination={{ pageSize: 10 }} />

      <Modal title="Gửi thông báo" open={modalOpen} onCancel={() => setModalOpen(false)} onOk={handleSend} okText="Gửi">
        <Form form={form} layout="vertical">
          <Form.Item name="title" label="Tiêu đề" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="body" label="Nội dung" rules={[{ required: true }]}>
            <Input.TextArea rows={4} />
          </Form.Item>
          <Form.Item name="userId" label="Gửi cho (để trống = tất cả user)">
            <Input placeholder="userId hoặc để trống" list="user-ids" />
          </Form.Item>
          <datalist id="user-ids">
            {users.map((u) => (
              <option key={u.id} value={u.id}>
                {u.name}
              </option>
            ))}
          </datalist>
        </Form>
      </Modal>
    </div>
  );
}
