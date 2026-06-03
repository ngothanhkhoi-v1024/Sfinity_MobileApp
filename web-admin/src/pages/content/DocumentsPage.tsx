import {
  DeleteOutlined,
  DownloadOutlined,
  EyeOutlined,
  EyeInvisibleOutlined,
  RetweetOutlined,
} from '@ant-design/icons';
import {
  Button,
  Descriptions,
  Input,
  Modal,
  Space,
  Table,
  Tag,
  Tooltip,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import {
  adminDeleteDocument,
  adminHideDocument,
  adminUnhideDocument,
  fetchDocuments,
  type DocumentItem,
} from '@/api/documents';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

export function DocumentsPage() {
  const [data, setData] = useState<DocumentItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [viewModal, setViewModal] = useState<DocumentItem | null>(null);
  const [hideModal, setHideModal] = useState<DocumentItem | null>(null);
  const [deleteModal, setDeleteModal] = useState<DocumentItem | null>(null);
  const [unhideModal, setUnhideModal] = useState<DocumentItem | null>(null);
  const [reason, setReason] = useState('');
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);

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
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      width: 130,
      render: (s: string) => (
        <Tag color={s === 'PUBLISHED' ? 'green' : 'default'}>
          {s === 'PUBLISHED' ? 'Đã xuất bản' : 'Nháp'}
        </Tag>
      ),
    },
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
      title: 'Thao tác',
      key: 'actions',
      width: 280,
      render: (_, record) => (
        <Space>
          <Button size="small" icon={<EyeOutlined />} onClick={() => setViewModal(record)}>
            Xem
          </Button>
          {record.status === 'PUBLISHED' ? (
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
          ) : (
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
        title="Quản lý tài liệu"
        description="Xem chi tiết, ẩn hoặc xóa tài liệu học tập. Thao tác sẽ gửi thông báo lý do cho tác giả."
      />

      <Table
        className="admin-table"
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={data}
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
        {viewModal && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Tiêu đề">{viewModal.title}</Descriptions.Item>
            <Descriptions.Item label="Trạng thái">
              <Tag color={viewModal.status === 'PUBLISHED' ? 'green' : 'default'}>
                {viewModal.status === 'PUBLISHED' ? 'Đã xuất bản' : 'Nháp'}
              </Tag>
            </Descriptions.Item>
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
