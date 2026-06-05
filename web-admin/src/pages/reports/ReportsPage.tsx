import { Button, Input, Modal, Select, Space, Table, Tag, Typography, Descriptions, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';
import { SearchOutlined, EyeOutlined, EditOutlined } from '@ant-design/icons';

import { fetchReports, resolveReport, updateReportDescription, type ReportItem } from '@/api/reports';
import { apiClient } from '@/api/client';

interface ExpandedReportRowProps {
  report: ReportItem;
}

function ExpandedReportRow({ report }: ExpandedReportRowProps) {
  const [userData, setUserData] = useState<any>(null);
  const [targetData, setTargetData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchDetails() {
      setLoading(true);
      try {
        const promises: Promise<any>[] = [];

        if (report.userId) {
          promises.push(apiClient.get(`/users/${report.userId}`).then((res) => res.data));
        } else {
          promises.push(Promise.resolve(null));
        }

        if (report.targetId) {
          let endpoint = '';
          if (report.targetType === 'document') endpoint = `/document/${report.targetId}`;
          else if (report.targetType === 'place') endpoint = `/places/${report.targetId}`;
          else if (report.targetType === 'user') endpoint = `/users/${report.targetId}`;

          if (endpoint) {
            promises.push(apiClient.get(endpoint).then((res) => res.data));
          } else {
            promises.push(Promise.resolve(null));
          }
        } else {
          promises.push(Promise.resolve(null));
        }

        const [user, target] = await Promise.all(promises);
        setUserData(user);
        setTargetData(target);
      } catch (err) {
        console.error('Lỗi khi tải chi tiết dòng mở rộng:', err);
      } finally {
        setLoading(false);
      }
    }
    fetchDetails();
  }, [report]);

  if (loading) {
    return (
      <div style={{ padding: '16px', display: 'flex', justifyContent: 'center' }}>
        <Typography.Text type="secondary">Đang tải thông tin chi tiết...</Typography.Text>
      </div>
    );
  }

  return (
    <div style={{ padding: '16px', background: '#fafafa', borderRadius: 8, border: '1px solid #f0f0f0' }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
        {/* Left Side: Sender info */}
        <div>
          <Typography.Title level={5} style={{ marginTop: 0, marginBottom: 12 }}>
            Thông tin Người gửi báo cáo
          </Typography.Title>
          {userData ? (
            <Descriptions column={1} size="small" bordered>
              <Descriptions.Item label="Họ tên">{userData.name}</Descriptions.Item>
              <Descriptions.Item label="Email">{userData.email}</Descriptions.Item>
              <Descriptions.Item label="Vai trò">{userData.role === 'ADMIN' ? 'Quản trị viên' : 'Người dùng'}</Descriptions.Item>
              <Descriptions.Item label="Trạng thái">
                <Tag color={userData.status === 'ACTIVE' ? 'green' : 'red'}>
                  {userData.status === 'ACTIVE' ? 'Hoạt động' : 'Bị khóa'}
                </Tag>
              </Descriptions.Item>
              <Descriptions.Item label="Giới tính">{userData.gender || '-'}</Descriptions.Item>
              <Descriptions.Item label="Địa chỉ">{userData.address || '-'}</Descriptions.Item>
            </Descriptions>
          ) : (
            <Typography.Text type="secondary">Không có thông tin người dùng</Typography.Text>
          )}
        </div>

        {/* Right Side: Target info */}
        <div>
          <Typography.Title level={5} style={{ marginTop: 0, marginBottom: 12 }}>
            Thông tin {report.targetType === 'document' ? 'Tài liệu' : report.targetType === 'place' ? 'Địa điểm' : 'Người dùng'} bị báo cáo
          </Typography.Title>
          {targetData ? (
            <>
              {report.targetType === 'document' && (
                <Descriptions column={1} size="small" bordered style={{ background: '#fafafa' }}>
                  <Descriptions.Item label="Tiêu đề">{targetData.title}</Descriptions.Item>
                  <Descriptions.Item label="Mã môn">{targetData.subjectCode || '-'}</Descriptions.Item>
                  <Descriptions.Item label="Loại file">{targetData.fileType?.toUpperCase() || '-'}</Descriptions.Item>
                  <Descriptions.Item label="URL file">
                    {targetData.fileUrl ? (
                      <a href={targetData.fileUrl} target="_blank" rel="noopener noreferrer">
                        Tải về / Xem file
                      </a>
                    ) : (
                      '-'
                    )}
                  </Descriptions.Item>
                  <Descriptions.Item label="Trạng thái">
                    <Tag color={targetData.moderationStatus === 'APPROVED' ? 'green' : targetData.moderationStatus === 'HIDDEN' ? 'volcano' : 'red'}>
                      {targetData.moderationStatus}
                    </Tag>
                  </Descriptions.Item>
                  <Descriptions.Item label="Mô tả">{targetData.body || '-'}</Descriptions.Item>
                </Descriptions>
              )}
              {report.targetType === 'place' && (
                <Descriptions column={1} size="small" bordered style={{ background: '#fafafa' }}>
                  <Descriptions.Item label="Tên địa điểm">{targetData.title}</Descriptions.Item>
                  <Descriptions.Item label="Địa chỉ">{targetData.address || '-'}</Descriptions.Item>
                  <Descriptions.Item label="Khu vực">{targetData.zone || '-'}</Descriptions.Item>
                  <Descriptions.Item label="Trạng thái">{targetData.status}</Descriptions.Item>
                  <Descriptions.Item label="Mô tả">{targetData.body || '-'}</Descriptions.Item>
                </Descriptions>
              )}
              {report.targetType === 'user' && (
                <Descriptions column={1} size="small" bordered style={{ background: '#fafafa' }}>
                  <Descriptions.Item label="Họ tên">{targetData.name}</Descriptions.Item>
                  <Descriptions.Item label="Email">{targetData.email}</Descriptions.Item>
                  <Descriptions.Item label="Vai trò">{targetData.role}</Descriptions.Item>
                  <Descriptions.Item label="Trạng thái">{targetData.status}</Descriptions.Item>
                </Descriptions>
              )}
            </>
          ) : (
            <Typography.Text type="secondary">Đối tượng không tồn tại hoặc đã bị xóa</Typography.Text>
          )}
        </div>
      </div>
    </div>
  );
}

export function ReportsPage() {
  const [data, setData] = useState<ReportItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState<string | undefined>('ALL');
  const [resolveOpen, setResolveOpen] = useState(false);
  const [selected, setSelected] = useState<ReportItem | null>(null);
  const [status, setStatus] = useState<'RESOLVED' | 'REJECTED'>('RESOLVED');
  const [resolution, setResolution] = useState('');

  // Search and view states
  const [searchQuery, setSearchQuery] = useState('');
  const [viewReport, setViewReport] = useState<ReportItem | null>(null);
  const [editReport, setEditReport] = useState<ReportItem | null>(null);
  const [expandedRowKeys, setExpandedRowKeys] = useState<React.Key[]>([]);

  // Edit form state
  const [editDescription, setEditDescription] = useState('');
  const [submittingTarget, setSubmittingTarget] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setData(await fetchReports(filter === 'ALL' ? undefined : filter));
    } catch {
      message.error('Không tải được báo cáo');
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    load();
  }, [load]);

  const handleResolve = async () => {
    if (!selected) return;
    try {
      await resolveReport(selected.id, { status, resolution });
      message.success('Đã xử lý báo cáo');
      setResolveOpen(false);
      load();
    } catch {
      message.error('Xử lý thất bại');
    }
  };

  const handleSaveEditReport = async () => {
    if (!editReport) return;
    setSubmittingTarget(true);
    try {
      await updateReportDescription(editReport.id, editDescription);
      message.success('Đã cập nhật mô tả báo cáo thành công');
      setEditReport(null);
      load();
    } catch (err) {
      console.error(err);
      message.error('Lỗi khi cập nhật mô tả báo cáo');
    } finally {
      setSubmittingTarget(false);
    }
  };

  const toggleRowExpansion = (rowKey: React.Key) => {
    setExpandedRowKeys((prev) =>
      prev.includes(rowKey) ? prev.filter((key) => key !== rowKey) : [...prev, rowKey]
    );
  };

  // Filter list in memory based on search query
  const filteredData = data.filter((item) => {
    const term = searchQuery.toLowerCase().trim();
    if (!term) return true;
    return (
      item.reason?.toLowerCase().includes(term) ||
      item.description?.toLowerCase().includes(term) ||
      item.targetId?.toLowerCase().includes(term) ||
      item.user?.name?.toLowerCase().includes(term) ||
      item.targetInfo?.title?.toLowerCase().includes(term) ||
      item.targetInfo?.name?.toLowerCase().includes(term)
    );
  });

  const columns: ColumnsType<ReportItem> = [
    {
      title: 'Người gửi',
      dataIndex: ['user', 'name'],
      render: (name, record) => (
        <Button type="link" style={{ padding: 0 }} onClick={() => toggleRowExpansion(record.id)}>
          {name || 'Không rõ'}
        </Button>
      ),
    },
    {
      title: 'Loại',
      dataIndex: 'targetType',
      render: (t: string) => {
        const labels: Record<string, string> = {
          document: 'Tài liệu',
          place: 'Địa điểm',
          user: 'Người dùng',
        };
        return <Tag color="blue">{labels[t] || t}</Tag>;
      },
    },
    {
      title: 'Đối tượng bị báo cáo',
      key: 'targetInfo',
      width: 250,
      render: (_, record) => {
        if (!record.targetId) return <Typography.Text type="secondary">-</Typography.Text>;
        const title = record.targetInfo?.title || record.targetInfo?.name || record.targetId;
        return (
          <Button
            type="link"
            style={{ padding: 0, textAlign: 'left', height: 'auto', whiteSpace: 'normal' }}
            onClick={() => toggleRowExpansion(record.id)}
          >
            <Space direction="vertical" size={0}>
              <Typography.Text strong style={{ fontSize: 13, color: '#1677ff' }}>
                {title}
              </Typography.Text>
              <Typography.Text type="secondary" style={{ fontSize: 11, whiteSpace: 'nowrap' }}>
                ID: {record.targetId}
              </Typography.Text>
            </Space>
          </Button>
        );
      },
    },
    { title: 'Lý do', dataIndex: 'reason', ellipsis: true },
    { title: 'Mô tả', dataIndex: 'description', ellipsis: true },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      render: (s: string) => {
        const color = s === 'PENDING' ? 'orange' : s === 'RESOLVED' ? 'green' : 'red';
        return <Tag color={color}>{s === 'PENDING' ? 'Chờ xử lý' : s === 'RESOLVED' ? 'Đã duyệt' : 'Từ chối'}</Tag>;
      },
    },
    {
      title: 'Thao tác',
      key: 'actions',
      render: (_, record) => (
        <Space direction="vertical" size="small" style={{ width: '100%' }}>
          {record.status === 'PENDING' && (
            <Button
              size="small"
              type="primary"
              onClick={() => {
                setSelected(record);
                setStatus('RESOLVED');
                setResolution('');
                setResolveOpen(true);
              }}
            >
              Xử lý báo cáo
            </Button>
          )}
          <Space size="small" style={{ marginTop: 2 }}>
            <Button
              size="small"
              icon={<EyeOutlined />}
              onClick={() => setViewReport(record)}
            />
            <Button
              size="small"
              icon={<EditOutlined />}
              onClick={() => {
                setEditReport(record);
                setEditDescription(record.description || '');
              }}
            />
          </Space>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Typography.Title level={4} style={{ marginTop: 0 }}>
        Báo cáo vi phạm
      </Typography.Title>
      
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <Space>
          <Select
            value={filter}
            style={{ width: 160 }}
            onChange={setFilter}
            options={[
              { value: 'ALL', label: 'Tất cả' },
              { value: 'PENDING', label: 'Chờ xử lý' },
              { value: 'RESOLVED', label: 'Đã xử lý' },
              { value: 'REJECTED', label: 'Từ chối' },
            ]}
          />
          <Button onClick={load}>Làm mới</Button>
        </Space>
        
        <Input
          placeholder="Tìm lý do, mô tả, ID, tên đối tượng..."
          prefix={<SearchOutlined />}
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          style={{ width: 320 }}
          allowClear
        />
      </div>

      <Table
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={filteredData}
        expandable={{
          expandedRowRender: (record) => <ExpandedReportRow report={record} />,
          expandedRowKeys,
          onExpandedRowsChange: (keys) => setExpandedRowKeys([...keys]),
        }}
      />

      {/* Resolve Report Modal */}
      <Modal
        title="Xử lý báo cáo"
        open={resolveOpen}
        onCancel={() => setResolveOpen(false)}
        onOk={handleResolve}
        okText="Lưu"
      >
        <Space direction="vertical" style={{ width: '100%' }}>
          <Select
            value={status}
            onChange={setStatus}
            options={[
              { value: 'RESOLVED', label: 'Đã xử lý (Duyệt báo cáo)' },
              { value: 'REJECTED', label: 'Từ chối (Bác báo cáo)' },
            ]}
            style={{ width: '100%' }}
          />
          <Typography.Text>Ghi chú xử lý / Lý do gỡ bài:</Typography.Text>
          <Input.TextArea rows={4} value={resolution} onChange={(e) => setResolution(e.target.value)} placeholder="Nhập ghi chú xử lý..." />
        </Space>
      </Modal>

      {/* Report Detail View Modal */}
      <Modal
        title="Chi tiết báo cáo vi phạm"
        open={!!viewReport}
        onCancel={() => setViewReport(null)}
        footer={[
          <Button key="close" onClick={() => setViewReport(null)}>
            Đóng
          </Button>,
        ]}
        width={600}
      >
        {viewReport && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Người gửi báo cáo">
              {viewReport.user ? `${viewReport.user.name} (${viewReport.user.email})` : 'Không rõ'}
            </Descriptions.Item>
            <Descriptions.Item label="Loại vi phạm">
              {viewReport.targetType === 'document' ? 'Tài liệu' : viewReport.targetType === 'place' ? 'Địa điểm' : 'Người dùng'}
            </Descriptions.Item>
            <Descriptions.Item label="ID đối tượng bị báo cáo">
              {viewReport.targetId || '-'}
            </Descriptions.Item>
            <Descriptions.Item label="Tên đối tượng">
              {viewReport.targetInfo?.title || viewReport.targetInfo?.name || '-'}
            </Descriptions.Item>
            <Descriptions.Item label="Lý do báo cáo">
              <Typography.Text strong style={{ color: '#ef4444' }}>{viewReport.reason}</Typography.Text>
            </Descriptions.Item>
            <Descriptions.Item label="Mô tả chi tiết">
              {viewReport.description || 'Không có mô tả chi tiết'}
            </Descriptions.Item>
            <Descriptions.Item label="Trạng thái">
              <Tag color={viewReport.status === 'PENDING' ? 'orange' : viewReport.status === 'RESOLVED' ? 'green' : 'red'}>
                {viewReport.status === 'PENDING' ? 'Chờ xử lý' : viewReport.status === 'RESOLVED' ? 'Đã duyệt' : 'Từ chối'}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Thời gian gửi báo cáo">
              {new Date(viewReport.createdAt).toLocaleString()}
            </Descriptions.Item>
          </Descriptions>
        )}
      </Modal>

      {/* Report Description Edit Modal */}
      <Modal
        title="Chỉnh sửa mô tả báo cáo vi phạm"
        open={!!editReport}
        onCancel={() => setEditReport(null)}
        onOk={handleSaveEditReport}
        okButtonProps={{ loading: submittingTarget }}
        okText="Lưu"
        width={500}
      >
        {editReport && (
          <Space direction="vertical" style={{ width: '100%', marginTop: 12 }} size="middle">
            <div>
              <Typography.Text>Lý do báo cáo: <span style={{ fontWeight: 'bold', color: '#ef4444' }}>{editReport.reason}</span></Typography.Text>
            </div>
            <div>
              <Typography.Text>Mô tả chi tiết vi phạm:</Typography.Text>
              <Input.TextArea
                rows={6}
                value={editDescription}
                onChange={(e) => setEditDescription(e.target.value)}
                placeholder="Nhập mô tả chi tiết của báo cáo..."
              />
            </div>
          </Space>
        )}
      </Modal>
    </div>
  );
}
