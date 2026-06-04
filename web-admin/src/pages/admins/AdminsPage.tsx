import { DeleteOutlined, PlusOutlined, TeamOutlined } from '@ant-design/icons';
import { Button, Form, Input, Modal, Popconfirm, Table, Tag, message } from 'antd';
import { useCallback, useEffect, useState } from 'react';

import { apiClient } from '@/api/client';
import { deleteUser, fetchUsers, type UserRecord } from '@/api/users';
import { PageHeader } from '@/components/common/PageHeader';

export function AdminsPage() {
  const [admins, setAdmins] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
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
    setSubmitting(true);
    try {
      await apiClient.post('/users/admin', values);
      message.success('Đã tạo admin thành công');
      form.resetFields();
      setModalOpen(false);
      load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })
        ?.response?.data?.message;
      message.error(msg ?? 'Tạo admin thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const handleCancel = () => {
    form.resetFields();
    setModalOpen(false);
  };

  const handleDelete = async (id: string) => {
    try {
      await deleteUser(id);
      message.success('Đã xóa admin');
      load();
    } catch {
      message.error('Xóa thất bại');
    }
  };

  return (
    <div className="page-enter">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <PageHeader
          title="Quản lý Admin"
          description="Xem và thêm tài khoản quản trị viên hệ thống"
        />
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setModalOpen(true)}
          style={{ marginTop: 4, flexShrink: 0 }}
        >
          Thêm admin
        </Button>
      </div>

      <Table
        className="admin-table"
        rowKey="id"
        loading={loading}
        dataSource={admins}
        scroll={{ x: 600 }}
        pagination={{ pageSize: 10 }}
        columns={[
          {
            title: 'Tên',
            dataIndex: 'name',
            render: (name: string) => (
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={{
                  width: 34, height: 34, borderRadius: '50%',
                  background: 'linear-gradient(135deg, #818cf8, #6366f1)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: '#fff', fontWeight: 600, fontSize: 13, flexShrink: 0,
                }}>
                  {name?.[0]?.toUpperCase() ?? <TeamOutlined />}
                </div>
                <span style={{ fontWeight: 500 }}>{name}</span>
              </div>
            ),
          },
          { title: 'Email', dataIndex: 'email' },
          {
            title: 'Trạng thái',
            dataIndex: 'status',
            render: (status: string) => (
              <Tag color={status === 'ACTIVE' ? 'green' : 'default'}>
                {status === 'ACTIVE' ? 'Hoạt động' : status}
              </Tag>
            ),
          },
          {
            title: 'Thông báo',
            dataIndex: 'notificationsEnabled',
            render: (enabled?: boolean) => (
              <Tag color={enabled === false ? 'default' : 'blue'}>
                {enabled === false ? 'Đã tắt' : 'Đang bật'}
              </Tag>
            ),
          },
          // Sau cột 'Thông báo', thêm:
          {
            title: 'Thao tác',
            key: 'actions',
            width: 80,
            render: (_: unknown, record: UserRecord) => (
              <Popconfirm
                title="Xóa admin này?"
                description="Hành động này không thể hoàn tác."
                okText="Xóa"
                cancelText="Hủy"
                okButtonProps={{ danger: true }}
                onConfirm={() => handleDelete(record.id)}
              >
                <Button size="small" danger icon={<DeleteOutlined />} />
              </Popconfirm>
            ),
          },
        ]}
      />

      <Modal
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: 'linear-gradient(135deg, #818cf8, #6366f1)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <PlusOutlined style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 15 }}>Thêm quản trị viên</div>
              <div style={{ fontSize: 12, color: '#94a3b8', fontWeight: 400 }}>Tạo tài khoản admin mới</div>
            </div>
          </div>
        }
        open={modalOpen}
        onCancel={handleCancel}
        onOk={handleCreate}
        okText="Tạo admin"
        cancelText="Hủy"
        confirmLoading={submitting}
        width={460}
        okButtonProps={{ type: 'primary' }}
      >
        <Form form={form} layout="vertical" style={{ marginTop: 20 }}>
          <Form.Item
            name="name"
            label="Họ tên"
            rules={[{ required: true, message: 'Vui lòng nhập họ tên' }]}
          >
            <Input placeholder="Nguyễn Văn A" size="large" />
          </Form.Item>
          <Form.Item
            name="email"
            label="Email"
            rules={[{ required: true, type: 'email', message: 'Email không hợp lệ' }]}
          >
            <Input placeholder="admin@sfinity.com" size="large" />
          </Form.Item>
          <Form.Item
            name="password"
            label="Mật khẩu"
            rules={[{ required: true, min: 6, message: 'Mật khẩu ít nhất 6 ký tự' }]}
          >
            <Input.Password placeholder="Tối thiểu 6 ký tự" size="large" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}