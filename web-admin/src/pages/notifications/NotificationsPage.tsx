import { DeleteOutlined, PlusOutlined } from '@ant-design/icons';
import { Button, Form, Input, Modal, Popconfirm, Select, Space, Table, Tag, Typography, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import {
  adminDeleteAllNotifications,
  adminDeleteNotification,
  fetchNotificationHistory,
  sendNotification,
  type NotificationItem,
} from '@/api/notifications';
import { fetchUsers, type UserRecord } from '@/api/users';

export function NotificationsPage() {
  const [history, setHistory] = useState<NotificationItem[]>([]);
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
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
    setSending(true);
    try {
      const payload = {
        title: values.title,
        body: values.body,
        ...(values.userId ? { userId: values.userId } : {}),
      };
      const result = await sendNotification(payload);
      message.success(`Đã gửi thông báo (${JSON.stringify(result)})`);
      setModalOpen(false);
      form.resetFields();
      load();
    } catch {
      message.error('Gửi thất bại');
    } finally {
      setSending(false);
    }
  };

  const handleDeleteOne = async (id: string) => {
    try {
      await adminDeleteNotification(id);
      setHistory((prev) => prev.filter((n) => n.id !== id));
    } catch {
      message.error('Xóa thất bại');
    }
  };

  const handleDeleteAll = async () => {
    try {
      await adminDeleteAllNotifications();
      setHistory([]);
      message.success('Đã dọn tất cả thông báo');
    } catch {
      message.error('Xóa thất bại');
    }
  };

  const columns: ColumnsType<NotificationItem> = [
    { title: 'Tiêu đề', dataIndex: 'title' },
    { title: 'Nội dung', dataIndex: 'body', ellipsis: true },
    { title: 'Người nhận', dataIndex: ['user', 'name'] },
    {
      title: 'Thông báo',
      render: (_, record) => {
        const enabled = record.user?.notificationsEnabled;
        return (
          <Tag color={enabled === false ? 'red' : 'green'} style={{ borderRadius: 6 }}>
            {enabled === false ? 'Đã tắt' : 'Đang bật'}
          </Tag>
        );
      },
    },
    { title: 'Đã đọc', dataIndex: 'read', render: (v: boolean) => (v ? 'Có' : 'Chưa') },
    { title: 'Thời gian', dataIndex: 'createdAt', render: (v: string) => new Date(v).toLocaleString('vi-VN') },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 80,
      render: (_, record) => (
        <Popconfirm
          title="Xóa thông báo này?"
          onConfirm={() => handleDeleteOne(record.id)}
          okText="Xóa"
          cancelText="Hủy"
        >
          <Button size="small" danger icon={<DeleteOutlined />} />
        </Popconfirm>
      ),
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <Typography.Title level={4} style={{ margin: 0 }}>
          Thông báo
        </Typography.Title>
        <Space>
          {history.length > 0 && (
            <Popconfirm
              title="Xóa tất cả thông báo?"
              description="Hành động này không thể hoàn tác."
              onConfirm={handleDeleteAll}
              okText="Xóa tất cả"
              cancelText="Hủy"
              okButtonProps={{ danger: true }}
            >
              <Button icon={<DeleteOutlined />}>
                Dọn bớt
              </Button>
            </Popconfirm>
          )}
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setModalOpen(true)}>
            Gửi thông báo
          </Button>
        </Space>
      </div>

      <Table
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={history}
        pagination={{ pageSize: 10 }}
        locale={{ emptyText: 'Chưa có thông báo nào' }}
      />

      <Modal
        title="Gửi thông báo"
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSend}
        okText="Gửi"
        okButtonProps={{ loading: sending }}
      >
        <Form form={form} layout="vertical">
          <Form.Item name="title" label="Tiêu đề" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="body" label="Nội dung" rules={[{ required: true }]}>
            <Input.TextArea rows={4} />
          </Form.Item>
          <Form.Item name="userId" label="Gửi cho">
            <Select
              allowClear
              showSearch
              placeholder="Tất cả người dùng"
              optionFilterProp="label"
              options={[
                { value: '', label: 'Tất cả người dùng' },
                ...users.map((u) => ({
                  value: u.id,
                  label: `${u.name}${u.notificationsEnabled === false ? ' (đã tắt thông báo)' : ''}`,
                })),
              ]}
            />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
