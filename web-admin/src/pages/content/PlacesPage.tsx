import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  DeleteOutlined,
  EyeInvisibleOutlined,
  EyeOutlined,
  RetweetOutlined,
} from '@ant-design/icons';
import {
  Button,
  Descriptions,
  Input,
  Modal,
  Space,
  Switch,
  Table,
  Tag,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import {
  adminApprovePlace,
  adminDeletePlace,
  adminHidePlace,
  adminRejectPlace,
  adminUnhidePlace,
  fetchPlaces,
  type PlaceItem,
} from '@/api/places';
import { useSettings } from '@/contexts/SettingsContext';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

type ContentStatus = 'DRAFT' | 'PENDING' | 'PUBLISHED' | 'REJECTED' | 'HIDDEN';

const STATUS_LABELS: Record<ContentStatus, string> = {
  DRAFT: 'Nháp',
  PENDING: 'Chờ duyệt',
  PUBLISHED: 'Đã xuất bản',
  REJECTED: 'Từ chối',
  HIDDEN: 'Ẩn',
};

const STATUS_COLORS: Record<ContentStatus, string> = {
  DRAFT: 'default',
  PENDING: 'gold',
  PUBLISHED: 'green',
  REJECTED: 'red',
  HIDDEN: 'volcano',
};

export function PlacesPage() {
  const { settings, saving, toggleAutoApprove } = useSettings();
  const [data, setData] = useState<PlaceItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [viewModal, setViewModal] = useState<PlaceItem | null>(null);
  const [hideModal, setHideModal] = useState<PlaceItem | null>(null);
  const [deleteModal, setDeleteModal] = useState<PlaceItem | null>(null);
  const [unhideModal, setUnhideModal] = useState<PlaceItem | null>(null);
  const [approveModal, setApproveModal] = useState<PlaceItem | null>(null);
  const [rejectModal, setRejectModal] = useState<PlaceItem | null>(null);
  const [reason, setReason] = useState('');
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchPlaces();
      setData(res.items);
    } catch {
      message.error('Không tải được địa điểm');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const handleApprove = async () => {
    if (!approveModal) return;
    setSubmitting(true);
    try {
      await adminApprovePlace(approveModal.id, note.trim() || undefined);
      message.success('Đã duyệt địa điểm và thông báo cho tác giả');
      setApproveModal(null);
      setNote('');
      load();
    } catch {
      message.error('Thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const handleReject = async () => {
    if (!rejectModal || reason.trim().length < 2) {
      message.warning('Vui lòng nhập lý do từ chối (ít nhất 2 ký tự)');
      return;
    }
    setSubmitting(true);
    try {
      await adminRejectPlace(rejectModal.id, reason.trim());
      message.success('Đã từ chối địa điểm và thông báo cho tác giả');
      setRejectModal(null);
      setReason('');
      load();
    } catch {
      message.error('Thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const handleHide = async () => {
    if (!hideModal || reason.trim().length < 2) {
      message.warning('Vui lòng nhập lý do (ít nhất 2 ký tự)');
      return;
    }
    setSubmitting(true);
    try {
      await adminHidePlace(hideModal.id, reason.trim());
      message.success('Đã ẩn địa điểm và thông báo cho tác giả');
      setHideModal(null);
      setReason('');
      load();
    } catch {
      message.error('Thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const handleUnhide = async () => {
    if (!unhideModal) return;
    setSubmitting(true);
    try {
      await adminUnhidePlace(unhideModal.id, note.trim() || undefined);
      message.success('Đã bỏ ẩn địa điểm và thông báo cho tác giả');
      setUnhideModal(null);
      setNote('');
      load();
    } catch {
      message.error('Thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteModal || reason.trim().length < 2) {
      message.warning('Vui lòng nhập lý do (ít nhất 2 ký tự)');
      return;
    }
    setSubmitting(true);
    try {
      await adminDeletePlace(deleteModal.id, reason.trim());
      message.success('Đã xóa địa điểm và thông báo cho tác giả');
      setDeleteModal(null);
      setReason('');
      load();
    } catch {
      message.error('Thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const columns: ColumnsType<PlaceItem> = [
    { title: 'Tên địa điểm', dataIndex: 'title', width: 200, ellipsis: true },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      width: 130,
      render: (s: string) => (
        <Tag color={STATUS_COLORS[s as ContentStatus] ?? 'default'}>
          {STATUS_LABELS[s as ContentStatus] ?? s}
        </Tag>
      ),
    },
    { title: 'Địa chỉ', dataIndex: 'address', ellipsis: true, width: 200 },
    {
      title: 'Tọa độ',
      dataIndex: 'latitude',
      width: 160,
      render: (_: number | null, record: PlaceItem) => {
        if (record.latitude && record.longitude) {
          return `${record.latitude.toFixed(5)}, ${record.longitude.toFixed(5)}`;
        }
        return '-';
      },
    },
    { title: 'Tác giả', dataIndex: ['author', 'name'], width: 140, ellipsis: true },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 360,
      render: (_, record) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => setViewModal(record)}>
            Xem
          </Button>

          {record.status === 'PENDING' && (
            <>
              <Button
                size="small"
                type="primary"
                icon={<CheckCircleOutlined />}
                onClick={() => {
                  setApproveModal(record);
                  setNote('');
                }}
              >
                Duyệt
              </Button>
              <Button
                size="small"
                danger
                type="default"
                icon={<CloseCircleOutlined />}
                onClick={() => {
                  setRejectModal(record);
                  setReason('');
                }}
              >
                Từ chối
              </Button>
            </>
          )}

          {record.status === 'PUBLISHED' && (
            <Button
              size="small"
              icon={<EyeInvisibleOutlined />}
              onClick={() => {
                setHideModal(record);
                setReason('');
              }}
            >
              Ẩn
            </Button>
          )}

          {(record.status === 'HIDDEN' || record.status === 'DRAFT' || record.status === 'REJECTED') && (
            <Button
              size="small"
              type="default"
              icon={<RetweetOutlined />}
              onClick={() => {
                setUnhideModal(record);
                setNote('');
              }}
            >
              Bỏ ẩn
            </Button>
          )}

          <Button
            size="small"
            danger
            icon={<DeleteOutlined />}
            onClick={() => {
              setDeleteModal(record);
              setReason('');
            }}
          />
        </Space>
      ),
    },
  ];

  return (
    <PageShell>
      <PageHeader
        title="Quản lý địa điểm"
        description="Xem, duyệt, ẩn hoặc xóa địa điểm. Địa điểm chờ duyệt cần admin duyệt trước khi xuất bản."
        extra={
          <Space>
            <span style={{ fontSize: 13, color: '#64748b' }}>Duyệt tự động</span>
            <Switch
              checked={settings?.autoApprovePlaces ?? false}
              onChange={(checked) => toggleAutoApprove('autoApprovePlaces', checked)}
              loading={saving}
              checkedChildren="Bật"
              unCheckedChildren="Tắt"
            />
          </Space>
        }
      />

      <Table
        className="admin-table"
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={data}
        pagination={{ pageSize: 10 }}
        scroll={{ x: 900 }}
      />

      {/* View Detail Modal */}
      <Modal
        title="Chi tiết địa điểm"
        open={!!viewModal}
        onCancel={() => setViewModal(null)}
        footer={[
          <Button key="close" onClick={() => setViewModal(null)}>
            Đóng
          </Button>,
        ]}
        width={560}
      >
        {viewModal && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Tên địa điểm">{viewModal.title}</Descriptions.Item>
            <Descriptions.Item label="Trạng thái">
              <Tag color={STATUS_COLORS[viewModal.status as ContentStatus] ?? 'default'}>
                {STATUS_LABELS[viewModal.status as ContentStatus] ?? viewModal.status}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Địa chỉ">{viewModal.address ?? '-'}</Descriptions.Item>
            <Descriptions.Item label="Vĩ độ">{viewModal.latitude ?? '-'}</Descriptions.Item>
            <Descriptions.Item label="Kinh độ">{viewModal.longitude ?? '-'}</Descriptions.Item>
            <Descriptions.Item label="Tags">
              {(viewModal.tags ?? []).map((t) => (
                <Tag key={t}>{t}</Tag>
              ))}
              {(!viewModal.tags || viewModal.tags.length === 0) && '-'}
            </Descriptions.Item>
            <Descriptions.Item label="Tác giả">
              {viewModal.author?.name ?? viewModal.authorId ?? '-'}
            </Descriptions.Item>
            <Descriptions.Item label="Mô tả">{viewModal.body || '-'}</Descriptions.Item>
          </Descriptions>
        )}
      </Modal>

      {/* Approve Modal */}
      <Modal
        title={`Duyệt địa điểm: "${approveModal?.title}"`}
        open={!!approveModal}
        onCancel={() => { setApproveModal(null); setNote(''); }}
        onOk={handleApprove}
        okText="Duyệt và xuất bản"
        okButtonProps={{ loading: submitting }}
        width={520}
      >
        <p>Địa điểm sẽ được xuất bản ngay lập tức và tác giả sẽ được thông báo.</p>
        <Input.TextArea
          rows={3}
          placeholder="Ghi chú cho tác giả (tùy chọn)..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
      </Modal>

      {/* Reject Modal */}
      <Modal
        title={`Từ chối địa điểm: "${rejectModal?.title}"`}
        open={!!rejectModal}
        onCancel={() => { setRejectModal(null); setReason(''); }}
        onOk={handleReject}
        okText="Từ chối và thông báo"
        okButtonProps={{ danger: true, loading: submitting }}
        width={520}
      >
        <p>Địa điểm sẽ bị từ chối và tác giả sẽ nhận được thông báo kèm lý do.</p>
        <Input.TextArea
          rows={3}
          placeholder="Nhập lý do từ chối..."
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
      </Modal>

      {/* Hide Modal */}
      <Modal
        title={`Ẩn địa điểm: "${hideModal?.title}"`}
        open={!!hideModal}
        onCancel={() => { setHideModal(null); setReason(''); }}
        onOk={handleHide}
        okText="Ẩn và thông báo"
        okButtonProps={{ danger: true, loading: submitting }}
        width={520}
      >
        <p>Thao tác này sẽ ẩn địa điểm và gửi thông báo cho tác giả.</p>
        <Input.TextArea
          rows={3}
          placeholder="Nhập lý do ẩn địa điểm..."
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
      </Modal>

      {/* Unhide Modal */}
      <Modal
        title={`Bỏ ẩn địa điểm: "${unhideModal?.title}"`}
        open={!!unhideModal}
        onCancel={() => { setUnhideModal(null); setNote(''); }}
        onOk={handleUnhide}
        okText="Bỏ ẩn và thông báo"
        okButtonProps={{ loading: submitting }}
        width={520}
      >
        <p>Thao tác này sẽ khôi phục địa điểm sang trạng thái đã xuất bản và gửi thông báo cho tác giả.</p>
        <Input.TextArea
          rows={3}
          placeholder="Ghi chú (tùy chọn)..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
      </Modal>

      {/* Delete Modal */}
      <Modal
        title={`Xóa địa điểm: "${deleteModal?.title}"`}
        open={!!deleteModal}
        onCancel={() => { setDeleteModal(null); setReason(''); }}
        onOk={handleDelete}
        okText="Xóa và thông báo"
        okButtonProps={{ danger: true, loading: submitting }}
        width={520}
      >
        <p>Thao tác này sẽ xóa địa điểm vĩnh viễn và gửi thông báo cho tác giả.</p>
        <Input.TextArea
          rows={3}
          placeholder="Nhập lý do xóa địa điểm..."
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
      </Modal>
    </PageShell>
  );
}
