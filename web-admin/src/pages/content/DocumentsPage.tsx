import {
  CheckCircleOutlined,
  CloseCircleOutlined,
  DeleteOutlined,
  DownloadOutlined,
  EyeOutlined,
  EyeInvisibleOutlined,
  RetweetOutlined,
  SearchOutlined,
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
  Tooltip,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import {
  adminApproveDocument,
  adminDeleteDocument,
  adminHideDocument,
  adminRejectDocument,
  adminUnhideDocument,
  fetchDocuments,
  type DocumentItem,
  type DocumentModerationStatus,
} from '@/api/documents';
import { useSettings } from '@/contexts/SettingsContext';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

const MODERATION_LABELS: Record<DocumentModerationStatus, string> = {
  NONE: 'Nháp',
  PENDING: 'Chờ duyệt',
  APPROVED: 'Đã duyệt',
  REJECTED: 'Từ chối',
  HIDDEN: 'Ẩn',
};

const MODERATION_COLORS: Record<DocumentModerationStatus, string> = {
  NONE: 'default',
  PENDING: 'gold',
  APPROVED: 'green',
  REJECTED: 'red',
  HIDDEN: 'volcano',
};

/** Derive a working moderationStatus even when backend still returns legacy status */
function getModerationStatus(doc: DocumentItem): DocumentModerationStatus {
  if (doc.moderationStatus) return doc.moderationStatus;
  const s = (doc.status ?? '').toUpperCase();
  if (s === 'PENDING') return 'PENDING';
  if (s === 'REJECTED') return 'REJECTED';
  if (s === 'HIDDEN') return 'HIDDEN';
  if (s === 'PUBLISHED') return 'APPROVED';
  return 'NONE';
}

export function DocumentsPage() {
  const { settings, saving, toggleAutoApprove } = useSettings();
  const [data, setData] = useState<DocumentItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [viewModal, setViewModal] = useState<DocumentItem | null>(null);
  const [hideModal, setHideModal] = useState<DocumentItem | null>(null);
  const [deleteModal, setDeleteModal] = useState<DocumentItem | null>(null);
  const [unhideModal, setUnhideModal] = useState<DocumentItem | null>(null);
  const [approveModal, setApproveModal] = useState<DocumentItem | null>(null);
  const [rejectModal, setRejectModal] = useState<DocumentItem | null>(null);
  const [reason, setReason] = useState('');
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Filter list in memory based on search query
  const filteredData = data.filter((item) => {
    const term = searchQuery.toLowerCase().trim();
    if (!term) return true;
    return (
      item.title?.toLowerCase().includes(term) ||
      item.subjectCode?.toLowerCase().includes(term) ||
      item.author?.name?.toLowerCase().includes(term) ||
      item.body?.toLowerCase().includes(term) ||
      item.id?.toLowerCase().includes(term)
    );
  });

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchDocuments();
      setData(res.items);
    } catch {
      message.error('Không tải được tài liệu');
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
      await adminApproveDocument(approveModal.id, note.trim() || undefined);
      message.success('Đã duyệt tài liệu và thông báo cho tác giả');
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
      await adminRejectDocument(rejectModal.id, reason.trim());
      message.success('Đã từ chối tài liệu và thông báo cho tác giả');
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
      await adminHideDocument(hideModal.id, reason.trim());
      message.success('Đã ẩn tài liệu và thông báo cho tác giả');
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
      await adminUnhideDocument(unhideModal.id, note.trim() || undefined);
      message.success('Đã bỏ ẩn tài liệu và thông báo cho tác giả');
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
      await adminDeleteDocument(deleteModal.id, reason.trim());
      message.success('Đã xóa tài liệu và thông báo cho tác giả');
      setDeleteModal(null);
      setReason('');
      load();
    } catch {
      message.error('Thất bại');
    } finally {
      setSubmitting(false);
    }
  };

  const formatFileSize = (bytes: number | null) => {
    if (!bytes) return '-';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const columns: ColumnsType<DocumentItem> = [
    { title: 'Tiêu đề', dataIndex: 'title', ellipsis: true },
    { title: 'Môn', dataIndex: 'subjectCode', width: 100, ellipsis: true },
    {
      title: 'Loại file',
      dataIndex: 'fileType',
      width: 100,
      render: (v: string | null) => v?.toUpperCase() ?? '-',
    },
    {
      title: 'Dung lượng',
      dataIndex: 'fileSize',
      width: 100,
      render: (v: number | null) => formatFileSize(v),
    },
    {
      title: 'Tải về',
      dataIndex: 'downloadsCount',
      width: 90,
      render: (v: number) => (
        <Tooltip title={`${v} lượt tải`}>
          <span><DownloadOutlined /> {v}</span>
        </Tooltip>
      ),
    },
    { title: 'Tác giả', dataIndex: ['author', 'name'], width: 140, ellipsis: true },
    {
      title: 'Trạng thái',
      key: 'moderationStatus',
      width: 130,
      render: (_: unknown, record: DocumentItem) => {
        const ms = getModerationStatus(record);
        return (
          <Tag color={MODERATION_COLORS[ms]}>
            {MODERATION_LABELS[ms]}
          </Tag>
        );
      },
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 360,
      render: (_: unknown, record: DocumentItem) => {
        const ms = getModerationStatus(record);
        const isPublic = record.visibility === 'PUBLIC';
        return (
          <Space>
            <Button size="small" icon={<EyeOutlined />} onClick={() => setViewModal(record)}>
              Xem
            </Button>

            {ms === 'PENDING' && (
              <>
                <Button
                  size="small"
                  type="primary"
                  icon={<CheckCircleOutlined />}
                  onClick={() => { setApproveModal(record); setNote(''); }}
                >
                  Duyệt
                </Button>
                <Button
                  size="small"
                  danger
                  type="default"
                  icon={<CloseCircleOutlined />}
                  onClick={() => { setRejectModal(record); setReason(''); }}
                >
                  Từ chối
                </Button>
              </>
            )}

            {isPublic && ms === 'APPROVED' && (
              <Button
                size="small"
                icon={<EyeInvisibleOutlined />}
                style={{ width: 80, justifyContent: 'flex-start' }}
                onClick={() => { setHideModal(record); setReason(''); }}
              >
                Ẩn
              </Button>
            )}

            {(ms === 'HIDDEN' || ms === 'NONE' || ms === 'REJECTED') && (
              <Button
                size="small"
                type="default"
                icon={<RetweetOutlined />}
                style={{ width: 80, justifyContent: 'flex-start' }}
                onClick={() => { setUnhideModal(record); setNote(''); }}
              >
                Bỏ ẩn
              </Button>
            )}

            <Button
              size="small"
              danger
              icon={<DeleteOutlined />}
              onClick={() => { setDeleteModal(record); setReason(''); }}
            >
              Xóa
            </Button>
          </Space>
        );
      },
    },
  ];

  return (
    <PageShell>
      <PageHeader
        title="Quản lý tài liệu"
        extra={
          <Space size="middle">
            <Space>
              <span style={{ fontSize: 13, color: '#64748b' }}>Duyệt tự động</span>
              <Switch
                checked={settings?.autoApproveDocuments ?? false}
                onChange={(checked) => toggleAutoApprove('autoApproveDocuments', checked)}
                loading={saving}
                checkedChildren="Bật"
                unCheckedChildren="Tắt"
              />
            </Space>
            <Input
              placeholder="Tìm kiếm tiêu đề, mã môn, tác giả..."
              prefix={<SearchOutlined />}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{ width: 280 }}
              allowClear
            />
          </Space>
        }
      />

      <div style={{ marginBottom: 16 }} />

      <Table
        className="admin-table"
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={filteredData}
        pagination={{ pageSize: 10 }}
      />

      {/* View Detail Modal */}
      <Modal
        title="Chi tiết tài liệu"
        open={!!viewModal}
        onCancel={() => setViewModal(null)}
        footer={[
          <Button key="close" onClick={() => setViewModal(null)}>
            Đóng
          </Button>,
        ]}
        width={640}
      >
        {viewModal && (() => {
          const ms = getModerationStatus(viewModal);
          return (
            <Descriptions column={1} bordered size="small">
              <Descriptions.Item label="Tiêu đề">{viewModal.title}</Descriptions.Item>
              <Descriptions.Item label="Mã môn">{viewModal.subjectCode ?? '-'}</Descriptions.Item>
              <Descriptions.Item label="Loại file">{viewModal.fileType?.toUpperCase() ?? '-'}</Descriptions.Item>
              <Descriptions.Item label="Dung lượng">{formatFileSize(viewModal.fileSize)}</Descriptions.Item>
              <Descriptions.Item label="URL file">
                {viewModal.fileUrl ? (
                  <a href={viewModal.fileUrl} target="_blank" rel="noopener noreferrer">
                    {viewModal.fileUrl}
                  </a>
                ) : (
                  '-'
                )}
              </Descriptions.Item>
              <Descriptions.Item label="Tác giả">
                {viewModal.author?.name ?? viewModal.authorId ?? '-'}
              </Descriptions.Item>
              <Descriptions.Item label="Mô tả">{viewModal.body || '-'}</Descriptions.Item>
              <Descriptions.Item label="Hiển thị">
                <Tag color={viewModal.visibility === 'PUBLIC' ? 'blue' : 'default'}>
                  {viewModal.visibility === 'PUBLIC' ? 'Công khai' : 'Riêng tư'}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Trạng thái kiểm duyệt">
                <Tag color={MODERATION_COLORS[ms]}>
                  {MODERATION_LABELS[ms]}
                </Tag>
              </Descriptions.Item>
            </Descriptions>
          );
        })()}
      </Modal>

      {/* Approve Modal */}
      <Modal
        title={`Duyệt tài liệu: "${approveModal?.title}"`}
        open={!!approveModal}
        onCancel={() => { setApproveModal(null); setNote(''); }}
        onOk={handleApprove}
        okText="Duyệt và xuất bản"
        okButtonProps={{ loading: submitting }}
        width={520}
      >
        <p>Tài liệu sẽ được xuất bản ngay lập tức và tác giả sẽ được thông báo.</p>
        <Input.TextArea
          rows={3}
          placeholder="Ghi chú cho tác giả (tùy chọn)..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
      </Modal>

      {/* Reject Modal */}
      <Modal
        title={`Từ chối tài liệu: "${rejectModal?.title}"`}
        open={!!rejectModal}
        onCancel={() => { setRejectModal(null); setReason(''); }}
        onOk={handleReject}
        okText="Từ chối và thông báo"
        okButtonProps={{ danger: true, loading: submitting }}
        width={520}
      >
        <p>Tài liệu sẽ bị từ chối và tác giả sẽ nhận được thông báo kèm lý do.</p>
        <Input.TextArea
          rows={3}
          placeholder="Nhập lý do từ chối..."
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
      </Modal>

      {/* Hide Modal */}
      <Modal
        title={`Ẩn tài liệu: "${hideModal?.title}"`}
        open={!!hideModal}
        onCancel={() => { setHideModal(null); setReason(''); }}
        onOk={handleHide}
        okText="Ẩn và thông báo"
        okButtonProps={{ danger: true, loading: submitting }}
        width={520}
      >
        <p>Thao tác này sẽ ẩn tài liệu và gửi thông báo cho tác giả.</p>
        <Input.TextArea
          rows={3}
          placeholder="Nhập lý do ẩn tài liệu..."
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
      </Modal>

      {/* Unhide Modal */}
      <Modal
        title={`Bỏ ẩn tài liệu: "${unhideModal?.title}"`}
        open={!!unhideModal}
        onCancel={() => { setUnhideModal(null); setNote(''); }}
        onOk={handleUnhide}
        okText="Bỏ ẩn và thông báo"
        okButtonProps={{ loading: submitting }}
        width={520}
      >
        <p>Thao tác này sẽ khôi phục tài liệu sang trạng thái đã xuất bản và gửi thông báo cho tác giả.</p>
        <Input.TextArea
          rows={3}
          placeholder="Ghi chú (tùy chọn)..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
      </Modal>

      {/* Delete Modal */}
      <Modal
        title={`Xóa tài liệu: "${deleteModal?.title}"`}
        open={!!deleteModal}
        onCancel={() => { setDeleteModal(null); setReason(''); }}
        onOk={handleDelete}
        okText="Xóa và thông báo"
        okButtonProps={{ danger: true, loading: submitting }}
        width={520}
      >
        <p>Thao tác này sẽ xóa tài liệu vĩnh viễn và gửi thông báo cho tác giả.</p>
        <Input.TextArea
          rows={3}
          placeholder="Nhập lý do xóa tài liệu..."
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
      </Modal>
    </PageShell>
  );
}
