import { DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import { Button, Input, Popconfirm, Select, Table, Tag, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import { deleteUser, fetchUsers, updateUser, type UserRecord } from '@/api/users';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

export function UsersPage() {
  const [data, setData] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');

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
      title: 'Thao tác',
      key: 'actions',
      width: 80,
      render: (_, record) => (
        <Popconfirm title="Xóa người dùng?" onConfirm={() => handleDelete(record.id)}>
          <Button type="text" danger icon={<DeleteOutlined />} />
        </Popconfirm>
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
        <Button type="primary" onClick={load}>
          Tìm kiếm
        </Button>
      </div>
      <Table
        className="admin-table"
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={data}
        pagination={{ pageSize: 10, showSizeChanger: false }}
      />
    </PageShell>
  );
}
