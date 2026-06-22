import { CrownOutlined, DeleteOutlined, EditOutlined, EyeOutlined, SearchOutlined } from '@ant-design/icons';
import {
  Button,
  DatePicker,
  Descriptions,
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
import { useCallback, useEffect, useMemo, useState } from 'react';

import {
  fetchUserSubscription,
  formatVnd,
  resetUserUsage,
  updateUserSubscription,
  type UserSubscriptionDetail,
} from '@/api/subscriptions';
import { deleteUser, fetchUsers, updateUser, type UserRecord } from '@/api/users';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

const GENDER_OPTIONS = [
  { value: 'Nam', label: 'Nam' },
  { value: 'Nữ', label: 'Nữ' },
  { value: 'Khác', label: 'Khác' },
];

type VipFilter = 'all' | 'vip' | 'free' | 'expired';

function vipTag(record: UserRecord) {
  if (record.vipActive) {
    return (
      <Tag color="gold" icon={<CrownOutlined />} style={{ borderRadius: 6 }}>
        VIP
      </Tag>
    );
  }
  if (record.isVip && !record.vipActive) {
    return <Tag color="default">Hết hạn</Tag>;
  }
  return <Tag color="blue">Thường</Tag>;
}

export function UsersPage() {
  const [data, setData] = useState<UserRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [vipFilter, setVipFilter] = useState<VipFilter>('all');

  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [viewTarget, setViewTarget] = useState<UserRecord | null>(null);

  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<UserRecord | null>(null);
  const [editForm] = Form.useForm();

  const [vipModalOpen, setVipModalOpen] = useState(false);
  const [vipTarget, setVipTarget] = useState<UserRecord | null>(null);
  const [vipDetail, setVipDetail] = useState<UserSubscriptionDetail | null>(null);
  const [vipLoading, setVipLoading] = useState(false);
  const [vipForm] = Form.useForm();

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

  const filteredData = useMemo(() => {
    return data.filter((u) => {
      if (vipFilter === 'vip') return u.vipActive === true;
      if (vipFilter === 'free') return !u.isVip;
      if (vipFilter === 'expired') return u.isVip === true && !u.vipActive;
      return true;
    });
  }, [data, vipFilter]);

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

  const openVipModal = async (record: UserRecord) => {
    setVipTarget(record);
    setVipModalOpen(true);
    setVipLoading(true);
    vipForm.setFieldsValue({ action: 'grant', planId: 'pro', cycle: 'monthly', days: 30 });
    try {
      setVipDetail(await fetchUserSubscription(record.id));
    } catch {
      message.error('Không tải được thông tin VIP');
    } finally {
      setVipLoading(false);
    }
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

  const handleVipAction = async () => {
    if (!vipTarget) return;
    try {
      const values = await vipForm.validateFields();
      const payload: Parameters<typeof updateUserSubscription>[1] = {
        action: values.action,
        planId: values.planId,
        cycle: values.cycle,
        note: values.note,
      };
      if (values.expiresAt) {
        payload.expiresAt = values.expiresAt.toISOString();
      } else if (values.days) {
        payload.days = values.days;
      }
      const detail = await updateUserSubscription(vipTarget.id, payload);
      setVipDetail(detail);
      message.success('Cập nhật gói VIP thành công');
      load();
    } catch {
      message.error('Cập nhật VIP thất bại');
    }
  };

  const handleResetUsage = async () => {
    if (!vipTarget) return;
    try {
      const detail = await resetUserUsage(vipTarget.id);
      setVipDetail(detail);
      message.success('Đã reset lượt sử dụng');
    } catch {
      message.error('Reset thất bại');
    }
  };

  const columns: ColumnsType<UserRecord> = [
    { title: 'Tên', dataIndex: 'name', key: 'name', ellipsis: true },
    { title: 'Email', dataIndex: 'email', key: 'email', ellipsis: true },
    {
      title: 'Gói VIP',
      key: 'vip',
      width: 100,
      render: (_, record) => vipTag(record),
    },
    {
      title: 'Hết hạn VIP',
      key: 'vipExpires',
      width: 120,
      render: (_, r) =>
        r.vipExpiresAt ? dayjs(r.vipExpiresAt).format('DD/MM/YYYY') : '—',
    },
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
      width: 200,
      render: (_, record) => (
        <Space size={4}>
          <Button type="text" icon={<EyeOutlined />} onClick={() => openViewModal(record)} title="Xem" />
          <Button type="text" icon={<EditOutlined />} onClick={() => openEditModal(record)} title="Sửa" />
          <Button
            type="text"
            icon={<CrownOutlined />}
            onClick={() => openVipModal(record)}
            title="Quản lý VIP"
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
        description="Xem, tìm kiếm, quản lý trạng thái và gói VIP"
      />
      <div className="admin-table-toolbar" style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
        <Input
          placeholder="Tìm theo tên, email..."
          prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onPressEnter={load}
          style={{ width: 300, maxWidth: '100%' }}
          allowClear
        />
        <Select
          value={vipFilter}
          onChange={setVipFilter}
          style={{ width: 180 }}
          options={[
            { value: 'all', label: 'Tất cả gói' },
            { value: 'vip', label: 'Đang VIP' },
            { value: 'expired', label: 'VIP hết hạn' },
            { value: 'free', label: 'Tài khoản thường' },
          ]}
        />
      </div>
      <Table
        className="admin-table"
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={filteredData}
        pagination={{ pageSize: 10, showSizeChanger: false }}
        scroll={{ x: 1000 }}
      />

      <Modal
        title="Thông tin người dùng"
        open={viewModalOpen}
        onCancel={() => setViewModalOpen(false)}
        footer={<Button type="primary" onClick={() => setViewModalOpen(false)}>Đóng</Button>}
        width={480}
      >
        {viewTarget && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <DetailRow label="Tên" value={viewTarget.name} />
            <DetailRow label="Email" value={viewTarget.email} />
            <DetailRow label="Gói VIP" value={vipTag(viewTarget)} />
            <DetailRow
              label="Hết hạn VIP"
              value={viewTarget.vipExpiresAt ? dayjs(viewTarget.vipExpiresAt).format('DD/MM/YYYY') : '—'}
            />
            <DetailRow label="Giới tính" value={viewTarget.gender || '—'} />
            <DetailRow
              label="Ngày sinh"
              value={viewTarget.birthDate ? dayjs(viewTarget.birthDate).format('DD/MM/YYYY') : '—'}
            />
            <DetailRow label="Địa chỉ" value={viewTarget.address || '—'} />
            <DetailRow
              label="Vai trò"
              value={
                <Tag color={viewTarget.role === 'admin' ? 'purple' : 'geekblue'} style={{ borderRadius: 6 }}>
                  {viewTarget.role}
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

      <Modal
        title={vipTarget ? `Quản lý VIP — ${vipTarget.name}` : 'Quản lý VIP'}
        open={vipModalOpen}
        onCancel={() => setVipModalOpen(false)}
        footer={null}
        width={640}
        loading={vipLoading}
      >
        {vipDetail && (
          <>
            <Descriptions bordered size="small" column={1} style={{ marginBottom: 16 }}>
              <Descriptions.Item label="Trạng thái">
                {vipDetail.isVip ? (
                  <Tag color="gold">VIP đang hoạt động</Tag>
                ) : vipDetail.isVipFlag ? (
                  <Tag>Hết hạn</Tag>
                ) : (
                  <Tag color="blue">Tài khoản thường</Tag>
                )}
              </Descriptions.Item>
              <Descriptions.Item label="Gói">
                {(vipDetail.planId ?? '—').toUpperCase()} ·{' '}
                {vipDetail.cycle === 'yearly' ? 'Hàng năm' : vipDetail.cycle === 'monthly' ? 'Hàng tháng' : '—'}
              </Descriptions.Item>
              <Descriptions.Item label="Hết hạn">
                {vipDetail.expiresAt ? dayjs(vipDetail.expiresAt).format('DD/MM/YYYY HH:mm') : '—'}
              </Descriptions.Item>
              <Descriptions.Item label="Nguồn">{vipDetail.source ?? '—'}</Descriptions.Item>
              <Descriptions.Item label="Lượt tải tài liệu">
                {vipDetail.limits.documentDownloads.limit == null
                  ? 'Không giới hạn'
                  : `${vipDetail.limits.documentDownloads.used}/${vipDetail.limits.documentDownloads.limit}`}
              </Descriptions.Item>
              <Descriptions.Item label="Lượt đăng địa điểm">
                {vipDetail.limits.placesCreated.limit == null
                  ? 'Không giới hạn'
                  : `${vipDetail.limits.placesCreated.used}/${vipDetail.limits.placesCreated.limit}`}
              </Descriptions.Item>
              <Descriptions.Item label="Bạn bè">
                {vipDetail.limits.friends.limit == null
                  ? 'Không giới hạn'
                  : `${vipDetail.limits.friends.used}/${vipDetail.limits.friends.limit}`}
              </Descriptions.Item>
            </Descriptions>

            <Form form={vipForm} layout="vertical">
              <Form.Item label="Hành động" name="action" rules={[{ required: true }]}>
                <Select
                  options={[
                    { value: 'grant', label: 'Cấp / kích hoạt VIP' },
                    { value: 'extend', label: 'Gia hạn thêm' },
                    { value: 'revoke', label: 'Thu hồi VIP' },
                  ]}
                />
              </Form.Item>
              <Form.Item noStyle shouldUpdate={(p, c) => p.action !== c.action}>
                {({ getFieldValue }) =>
                  getFieldValue('action') !== 'revoke' ? (
                    <>
                      <Form.Item label="Gói" name="planId">
                        <Select options={[{ value: 'pro', label: 'VIP Pro' }]} />
                      </Form.Item>
                      <Form.Item label="Chu kỳ" name="cycle">
                        <Select
                          options={[
                            { value: 'monthly', label: '1 tháng (49.000đ)' },
                            { value: 'yearly', label: '1 năm (399.000đ)' },
                          ]}
                        />
                      </Form.Item>
                      <Form.Item label="Gia hạn thêm (ngày)" name="days">
                        <Input type="number" placeholder="VD: 30" />
                      </Form.Item>
                      <Form.Item label="Hoặc ngày hết hạn cố định" name="expiresAt">
                        <DatePicker showTime style={{ width: '100%' }} format="DD/MM/YYYY HH:mm" />
                      </Form.Item>
                    </>
                  ) : null
                }
              </Form.Item>
              <Form.Item label="Ghi chú" name="note">
                <Input.TextArea rows={2} placeholder="Lý do cấp/thu hồi VIP..." />
              </Form.Item>
            </Form>

            <Space style={{ marginTop: 8 }}>
              <Button type="primary" onClick={handleVipAction}>
                Áp dụng
              </Button>
              <Popconfirm title="Reset lượt tải/đăng địa điểm về 0?" onConfirm={handleResetUsage}>
                <Button>Reset lượt dùng</Button>
              </Popconfirm>
            </Space>

            {vipDetail.transactions.length > 0 && (
              <div style={{ marginTop: 20 }}>
                <strong>Giao dịch gần đây</strong>
                <Table
                  size="small"
                  rowKey="orderId"
                  style={{ marginTop: 8 }}
                  pagination={false}
                  dataSource={vipDetail.transactions}
                  columns={[
                    { title: 'Mã', dataIndex: 'orderId', ellipsis: true },
                    {
                      title: 'Số tiền',
                      dataIndex: 'amount',
                      render: (v: number) => formatVnd(v),
                    },
                    {
                      title: 'TT',
                      dataIndex: 'status',
                      render: (s: string) => <Tag>{s}</Tag>,
                    },
                  ]}
                />
              </div>
            )}
          </>
        )}
      </Modal>
    </PageShell>
  );
}

function DetailRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      <span style={{ color: '#64748b', minWidth: 90, fontWeight: 500 }}>{label}:</span>
      <span style={{ color: '#1e293b' }}>{value}</span>
    </div>
  );
}
