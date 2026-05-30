import { Button, Form, Input, Table, Typography, message } from 'antd';
import { useCallback, useEffect, useState } from 'react';

import { apiClient } from '@/api/client';
import { fetchUsers, type UserRecord } from '@/api/users';

export function AdminsPage() {
  const [admins, setAdmins] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [form] = Form.useForm();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const users = await fetchUsers();
      setAdmins(users.filter((u) => u.role === 'admin'));
    } catch {
      message.error('Không tải được danh sách admin');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const handleCreate = async () => {
    const values = await form.validateFields();
    try {
      await apiClient.post('/users/admin', values);
      message.success('Đã tạo admin');
      form.resetFields();
      load();
    } catch {
      message.error('Tạo admin thất bại');
    }
  };

  return (
    <div>
      <Typography.Title level={4} style={{ marginTop: 0 }}>
        Quản lý Admin
      </Typography.Title>

      <Form form={form} layout="inline" style={{ marginBottom: 24, gap: 8 }} onFinish={handleCreate}>
        <Form.Item name="name" rules={[{ required: true }]}>
          <Input placeholder="Họ tên" />
        </Form.Item>
        <Form.Item name="email" rules={[{ required: true, type: 'email' }]}>
          <Input placeholder="Email" />
        </Form.Item>
        <Form.Item name="password" rules={[{ required: true, min: 6 }]}>
          <Input.Password placeholder="Mật khẩu" />
        </Form.Item>
        <Form.Item>
          <Button type="primary" htmlType="submit">
            Thêm admin
          </Button>
        </Form.Item>
      </Form>

      <Table
        rowKey="id"
        loading={loading}
        dataSource={admins}
        columns={[
          { title: 'Tên', dataIndex: 'name' },
          { title: 'Email', dataIndex: 'email' },
          { title: 'Trạng thái', dataIndex: 'status' },
          {
            title: 'Thông báo',
            dataIndex: 'notificationsEnabled',
            render: (enabled?: boolean) => (enabled === false ? 'Đã tắt' : 'Đang bật'),
          },
        ]}
      />
    </div>
  );
}
