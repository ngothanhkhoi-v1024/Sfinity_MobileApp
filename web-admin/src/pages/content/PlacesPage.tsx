import {
  DeleteOutlined,
  EnvironmentOutlined,
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
  Table,
  Tag,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import {
  adminDeletePlace,
  adminHidePlace,
  adminUnhidePlace,
  fetchPlaces,
  PLACE_ZONES,
  type PlaceItem,
} from '@/api/places';
import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

const ZONE_COLORS: Record<string, string> = {
  khu_a: 'blue',
  khu_b: 'cyan',
  library: 'purple',
  dorm: 'orange',
  cafeteria: 'gold',
  sports: 'green',
  faculty_it: 'red',
  faculty_biz: 'magenta',
  other: 'default',
};

export function PlacesPage() {
  const [data, setData] = useState<PlaceItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [viewModal, setViewModal] = useState<PlaceItem | null>(null);
  const [hideModal, setHideModal] = useState<PlaceItem | null>(null);
  const [deleteModal, setDeleteModal] = useState<PlaceItem | null>(null);
  const [unhideModal, setUnhideModal] = useState<PlaceItem | null>(null);
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

  const getZoneLabel = (zoneId: string | null) => {
    if (!zoneId) return null;
    return PLACE_ZONES.find((z) => z.id === zoneId)?.label;
  };

  const columns: ColumnsType<PlaceItem> = [
    { title: 'Tên địa điểm', dataIndex: 'title', ellipsis: true },
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
    {
      title: 'Khu vực',
      dataIndex: 'zone',
      width: 130,
      render: (zone: string | null) => {
        const label = getZoneLabel(zone);
        if (!label) return '-';
        return <Tag color={ZONE_COLORS[zone] ?? 'default'}>{label}</Tag>;
      },
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
        title="Quản lý địa điểm"
        description="Xem chi tiết, ẩn hoặc xóa địa điểm trên campus. Thao tác sẽ gửi thông báo lý do cho tác giả."
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
              <Tag color={viewModal.status === 'PUBLISHED' ? 'green' : 'default'}>
                {viewModal.status === 'PUBLISHED' ? 'Đã xuất bản' : 'Nháp'}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Khu vực">
              {(() => {
                const label = getZoneLabel(viewModal.zone);
                return label ? (
                  <Tag color={ZONE_COLORS[viewModal.zone!] ?? 'default'}>{label}</Tag>
                ) : (
                  '-'
                );
              })()}
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
