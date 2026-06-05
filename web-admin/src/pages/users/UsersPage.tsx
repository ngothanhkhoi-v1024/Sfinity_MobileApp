import { DeleteOutlined, EditOutlined, EyeOutlined, SearchOutlined } from '@ant-design/icons';
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
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import dayjs from 'dayjs';
import { useCallback, useEffect, useState } from 'react';

import { deleteUser, fetchUsers, updateUser, type UserRecord } from '@/api/users';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

const GENDER_OPTIONS = [
  { value: 'Nam', label: 'Nam' },
  { value: 'Nữ', label: 'Nữ' },
  { value: 'Khác', label: 'Khác' },
];

export function UsersPage() {
  const [data, setData] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');

  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [viewTarget, setViewTarget] = useState<UserRecord | null>(null);

  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<UserRecord | null>(null);
  const [editForm] = Form.useForm();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setData(await fetchUsers(search || undefined));
    } catch {
      message.error('Không tải được danh sách người dùng');
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => {
    load();
  }, [load]);

  const handleStatus = async (id: string, status: string) => {
    try {
      await updateUser(id, { status });
      message.success('Cập nhật thành công');
      load();
    } catch {
      message.error('Cập nhật thất bại');
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deleteUser(id);
      message.success('Đã xóa');
      load();
    } catch {
      message.error('Xóa thất bại');
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
      gender: record.gender || undefined,
      birthDate: record.birthDate ? dayjs(record.birthDate) : undefined,
      address: record.address || undefined,
    });
    setEditModalOpen(true);
  };

  const handleEditSave = async () => {
    if (!editTarget) return;
    try {
      const values = await editForm.validateFields();
      await updateUser(editTarget.id, {
        name: values.name,
        gender: values.gender,
        birthDate: values.birthDate ? values.birthDate.format('YYYY-MM-DD') : '',
        address: values.address,
      });
      message.success('Cập nhật thành công');
      setEditModalOpen(false);
      load();
    } catch {
      message.error('Cập nhật thất bại');
    }
  };

  const columns: ColumnsType<UserRecord> = [
    { title: 'Tên', dataIndex: 'name', key: 'name', ellipsis: true },
    { title: 'Email', dataIndex: 'email', key: 'email', ellipsis: true },
    {
      title: 'Vai trò',
      dataIndex: 'role',
      render: (role: string) => (
        <Tag color={role === 'admin' ? 'purple' : 'geekblue'} style={{ borderRadius: 6 }}>
          {role}
        </Tag>
      ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      render: (status: string, record) => (
        <Select
          size="small"
          value={status}
          style={{ width: 128 }}
          onChange={(v) => handleStatus(record.id, v)}
          options={[
            { value: 'ACTIVE', label: 'Hoạt động' },
            { value: 'BANNED', label: 'Đã khóa' },
          ]}
        />
      ),
    },
    {
      title: 'Thông báo',
      dataIndex: 'notificationsEnabled',
      render: (enabled?: boolean) => (
        <Tag color={enabled === false ? 'red' : 'green'} style={{ borderRadius: 6 }}>
          {enabled === false ? 'Đã tắt' : 'Đang bật'}
        </Tag>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 160,
      render: (_, record) => (
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
          <Popconfirm title="Xóa người dùng?" onConfirm={() => handleDelete(record.id)}>
            <Button type="text" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <PageShell>
      <PageHeader
        title="Quản lý người dùng"
        description="Xem, tìm kiếm và quản lý trạng thái tài khoản"
      />
      <div className="admin-table-toolbar">
        <Input
          placeholder="Tìm theo tên, email..."
          prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onPressEnter={load}
          style={{ width: 300, maxWidth: '100%' }}
          allowClear
        />
      </div>
      <Table
        className="admin-table"
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={data}
        pagination={{ pageSize: 10, showSizeChanger: false }}
      />

      <Modal
        title="Thông tin người dùng"
        open={viewModalOpen}
        onCancel={() => setViewModalOpen(false)}
        footer={
          <Button type="primary" onClick={() => setViewModalOpen(false)}>
            Đóng
          </Button>
        }
        width={480}
      >
        {viewTarget && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <DetailRow label="Tên" value={viewTarget.name} />
            <DetailRow label="Email" value={viewTarget.email} />
            <DetailRow label="Giới tính" value={viewTarget.gender || '—'} />
            <DetailRow
              label="Ngày sinh"
              value={viewTarget.birthDate ? dayjs(viewTarget.birthDate).format('DD/MM/YYYY') : '—'}
            />
            <DetailRow label="Địa chỉ" value={viewTarget.address || '—'} />
            <DetailRow
              label="Vai trò"
              value={
                <Tag
                  color={viewTarget.role === 'admin' ? 'purple' : 'geekblue'}
                  style={{ borderRadius: 6 }}
                >
                  {viewTarget.role}
                </Tag>
              }
            />
            <DetailRow
              label="Trạng thái"
              value={
                <Tag color={viewTarget.status === 'ACTIVE' ? 'green' : 'red'} style={{ borderRadius: 6 }}>
                  {viewTarget.status === 'ACTIVE' ? 'Hoạt động' : 'Đã khóa'}
                </Tag>
              }
            />
          </div>
        )}
      </Modal>

      <Modal
        title="Chỉnh sửa người dùng"
        open={editModalOpen}
        onCancel={() => setEditModalOpen(false)}
        onOk={handleEditSave}
        okText="Lưu"
        cancelText="Hủy"
        width={480}
      >
        {editTarget && (
          <Form form={editForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item label="Tên" name="name" rules={[{ required: true, message: 'Vui lòng nhập tên' }]}>
              <Input placeholder="Nhập tên" />
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
    </PageShell>
  );
}

function DetailRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      <span
        style={{
          color: '#64748b',
          minWidth: 90,
          fontWeight: 500,
        }}
      >
        {label}:
      </span>
      <span style={{ color: '#1e293b' }}>{value}</span>
    </div>
  );
}
