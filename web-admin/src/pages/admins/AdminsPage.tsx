import {
  DeleteOutlined,
  EditOutlined,
  EyeOutlined,
  PlusOutlined,
  SearchOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import {
  Button,
  DatePicker,
  Form,
  Input,
  Modal,
  Popconfirm,
  Select,
  Space,
  Table,
  Tag,
  Tooltip,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import dayjs from 'dayjs';
import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react';

import { apiClient } from '@/api/client';
import { deleteUser, fetchUsers, updateUser, type UserRecord } from '@/api/users';
import { PageHeader } from '@/components/common/PageHeader';
import { useAuth } from '@/contexts/AuthContext';

const GENDER_OPTIONS = [
  { value: 'Nam', label: 'Nam' },
  { value: 'Nữ', label: 'Nữ' },
  { value: 'Khác', label: 'Khác' },
];

const STATUS_OPTIONS = [
  { value: 'ACTIVE', label: 'Hoạt động' },
  { value: 'BANNED', label: 'Đã khóa' },
];

function formatStatus(status: string) {
  return status === 'ACTIVE' ? 'Hoạt động' : 'Đã khóa';
}

function formatEmpty(value?: string) {
  return value?.trim() ? value : '—';
}

export function AdminsPage() {
  const { user } = useAuth();
  const [admins, setAdmins] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');

  const [modalOpen, setModalOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [form] = Form.useForm();

  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [viewTarget, setViewTarget] = useState<UserRecord | null>(null);

  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<UserRecord | null>(null);
  const [editSubmitting, setEditSubmitting] = useState(false);
  const [editForm] = Form.useForm();

  const currentAdminKey = useMemo(
    () => ({
      id: user?.id,
      email: user?.email?.toLowerCase(),
    }),
    [user?.email, user?.id],
  );

  const isCurrentAdmin = useCallback(
    (record: UserRecord) =>
      record.id === currentAdminKey.id ||
      (!!currentAdminKey.email && record.email.toLowerCase() === currentAdminKey.email),
    [currentAdminKey.email, currentAdminKey.id],
  );

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const users = await fetchUsers(search.trim() || undefined);
      setAdmins(users.filter((u) => u.role === 'admin'));
    } catch {
      message.error('Không tải được danh sách admin');
    } finally {
      setLoading(false);
    }
  }, [search]);

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

  const handleDelete = async (record: UserRecord) => {
    if (isCurrentAdmin(record)) {
      message.warning('Không thể xóa tài khoản đang đăng nhập');
      return;
    }

    try {
      await deleteUser(record.id);
      message.success('Đã xóa admin');
      load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })
        ?.response?.data?.message;
      message.error(msg ?? 'Xóa thất bại');
    }
  };

  const openViewModal = (record: UserRecord) => {
    setViewTarget(record);
    setViewModalOpen(true);
  };

  const openEditModal = (record: UserRecord) => {
    setEditTarget(record);
    editForm.setFieldsValue({
      name: record.name,
      status: record.status || 'ACTIVE',
      gender: record.gender || undefined,
      birthDate: record.birthDate ? dayjs(record.birthDate) : undefined,
      address: record.address || undefined,
    });
    setEditModalOpen(true);
  };

  const closeEditModal = () => {
    editForm.resetFields();
    setEditTarget(null);
    setEditModalOpen(false);
  };

  const handleEditSave = async () => {
    if (!editTarget) return;

    setEditSubmitting(true);
    try {
      const values = await editForm.validateFields();
      const editingSelf = isCurrentAdmin(editTarget);

      if (editingSelf && values.status === 'BANNED') {
        message.warning('Không thể tự chuyển tài khoản đang đăng nhập sang không hoạt động');
        return;
      }

      const payload: Parameters<typeof updateUser>[1] = {
        name: values.name,
        gender: values.gender ?? '',
        birthDate: values.birthDate ? values.birthDate.format('YYYY-MM-DD') : '',
        address: values.address ?? '',
      };

      if (!editingSelf) {
        payload.status = values.status;
      }

      await updateUser(editTarget.id, payload);
      message.success('Cập nhật admin thành công');
      closeEditModal();
      load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })
        ?.response?.data?.message;
      message.error(msg ?? 'Cập nhật thất bại');
    } finally {
      setEditSubmitting(false);
    }
  };

  const columns: ColumnsType<UserRecord> = [
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
    { title: 'Email', dataIndex: 'email', ellipsis: true },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      render: (status: string) => (
        <Tag color={status === 'ACTIVE' ? 'green' : 'red'}>
          {formatStatus(status)}
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
    {
      title: 'Thao tác',
      key: 'actions',
      width: 150,
      render: (_: unknown, record: UserRecord) => {
        const selfAccount = isCurrentAdmin(record);

        return (
          <Space size={4}>
            <Button
              type="text"
              icon={<EyeOutlined />}
              onClick={() => openViewModal(record)}
              title="Xem"
            />
            <Button
              type="text"
              icon={<EditOutlined />}
              onClick={() => openEditModal(record)}
              title="Sửa"
            />
            {selfAccount ? (
              <Tooltip title="Không thể xóa tài khoản đang đăng nhập">
                <span>
                  <Button type="text" danger disabled icon={<DeleteOutlined />} />
                </span>
              </Tooltip>
            ) : (
              <Popconfirm
                title="Xóa admin này?"
                description="Hành động này không thể hoàn tác."
                okText="Xóa"
                cancelText="Hủy"
                okButtonProps={{ danger: true }}
                onConfirm={() => handleDelete(record)}
              >
                <Button type="text" danger icon={<DeleteOutlined />} title="Xóa" />
              </Popconfirm>
            )}
          </Space>
        );
      },
    },
  ];

  return (
    <div className="page-enter">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 16, marginBottom: 24 }}>
        <PageHeader
          title="Quản lý Admin"
          description="Xem, tìm kiếm và quản lý tài khoản quản trị viên hệ thống"
        />
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-end',
            gap: 12,
            flexWrap: 'wrap',
          }}
        >
          <Input
            placeholder="Tìm theo tên, email..."
            prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onPressEnter={load}
            style={{ width: 320, maxWidth: '100%' }}
            allowClear
          />
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => setModalOpen(true)}
            style={{ flexShrink: 0 }}
          >
            Thêm admin
          </Button>
        </div>
      </div>

      <Table
        className="admin-table"
        rowKey="id"
        loading={loading}
        dataSource={admins}
        scroll={{ x: 760 }}
        pagination={{ pageSize: 10, showSizeChanger: false }}
        columns={columns}
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

      <Modal
        title="Thông tin quản trị viên"
        open={viewModalOpen}
        onCancel={() => setViewModalOpen(false)}
        footer={
          <Button type="primary" onClick={() => setViewModalOpen(false)}>
            Đóng
          </Button>
        }
        width={500}
      >
        {viewTarget && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <DetailRow label="Tên" value={viewTarget.name} />
            <DetailRow label="Email" value={viewTarget.email} />
            <DetailRow label="Giới tính" value={formatEmpty(viewTarget.gender)} />
            <DetailRow
              label="Ngày sinh"
              value={viewTarget.birthDate ? dayjs(viewTarget.birthDate).format('DD/MM/YYYY') : '—'}
            />
            <DetailRow label="Địa chỉ" value={formatEmpty(viewTarget.address)} />
            <DetailRow
              label="Trạng thái"
              value={
                <Tag color={viewTarget.status === 'ACTIVE' ? 'green' : 'red'}>
                  {formatStatus(viewTarget.status)}
                </Tag>
              }
            />
            <DetailRow
              label="Thông báo"
              value={
                <Tag color={viewTarget.notificationsEnabled === false ? 'default' : 'blue'}>
                  {viewTarget.notificationsEnabled === false ? 'Đã tắt' : 'Đang bật'}
                </Tag>
              }
            />
          </div>
        )}
      </Modal>

      <Modal
        title="Chỉnh sửa quản trị viên"
        open={editModalOpen}
        onCancel={closeEditModal}
        onOk={handleEditSave}
        okText="Lưu"
        cancelText="Hủy"
        confirmLoading={editSubmitting}
        width={500}
      >
        {editTarget && (
          <Form form={editForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item
              label="Tên"
              name="name"
              rules={[{ required: true, message: 'Vui lòng nhập tên' }]}
            >
              <Input placeholder="Nhập tên" />
            </Form.Item>
            <Form.Item
              label="Trạng thái"
              name="status"
              rules={[{ required: true, message: 'Vui lòng chọn trạng thái' }]}
            >
              <Select
                disabled={isCurrentAdmin(editTarget)}
                options={STATUS_OPTIONS}
              />
            </Form.Item>
            <Form.Item label="Giới tính" name="gender">
              <Select placeholder="Chọn giới tính" options={GENDER_OPTIONS} allowClear />
            </Form.Item>
            <Form.Item label="Ngày sinh" name="birthDate">
              <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" />
            </Form.Item>
            <Form.Item label="Địa chỉ" name="address">
              <Input.TextArea placeholder="Nhập địa chỉ" rows={3} />
            </Form.Item>
          </Form>
        )}
      </Modal>
    </div>
  );
}

function DetailRow({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      <span
        style={{
          color: '#64748b',
          minWidth: 92,
          fontWeight: 500,
        }}
      >
        {label}:
      </span>
      <span style={{ color: '#1e293b' }}>{value}</span>
    </div>
  );
}
