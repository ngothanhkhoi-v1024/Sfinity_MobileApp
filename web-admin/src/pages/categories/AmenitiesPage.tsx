import { DeleteOutlined, EditOutlined, PlusOutlined } from '@ant-design/icons';
import {
  Button,
  Form,
  Input,
  Modal,
  Popconfirm,
  Space,
  Table,
  Typography,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import {
  createAmenity,
  deleteAmenity,
  fetchAmenities,
  updateAmenity,
  type AmenityItem,
} from '@/api/categories';

export function AmenitiesPage() {
  const [data, setData] = useState<AmenityItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<AmenityItem | null>(null);
  const [form] = Form.useForm();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setData(await fetchAmenities());
    } catch {
      message.error('Không tải được tiện ích');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    setModalOpen(true);
  };

  const openEdit = (item: AmenityItem) => {
    setEditing(item);
    form.setFieldsValue({
      name: item.name,
      description: item.description,
    });
    setModalOpen(true);
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    try {
      if (editing) {
        await updateAmenity(editing.id, values);
        message.success('Đã cập nhật');
      } else {
        await createAmenity(values);
        message.success('Đã tạo tiện ích');
      }
      setModalOpen(false);
      load();
    } catch {
      message.error('Lưu thất bại');
    }
  };

  const columns: ColumnsType<AmenityItem> = [
    { title: 'Tên tiện ích', dataIndex: 'name' },
    { title: 'Mô tả', dataIndex: 'description', ellipsis: true },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 160,
      render: (_, record) => (
        <Space>
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(record)} />
          <Popconfirm
            title="Xóa tiện ích này?"
            onConfirm={async () => {
              await deleteAmenity(record.id);
              load();
            }}
          >
            <Button size="small" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <Space style={{ width: '100%', justifyContent: 'space-between', marginBottom: 16 }}>
        <Typography.Title level={4} style={{ margin: 0 }}>
          Tiện ích địa điểm
        </Typography.Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
          Thêm tiện ích
        </Button>
      </Space>

      <Table
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={data}
        pagination={{ pageSize: 10 }}
        scroll={{ x: 700 }}
        locale={{ emptyText: 'Chưa có tiện ích nào. Hãy thêm tiện ích mới.' }}
      />

      <Modal
        title={editing ? 'Sửa tiện ích' : 'Thêm tiện ích địa điểm'}
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText="Lưu"
      >
        <Form form={form} layout="vertical">
          <Form.Item name="name" label="Tên tiện ích" rules={[{ required: true }]}>
            <Input placeholder="VD: WiFi, Điều hòa, Ổ cắm..." />
          </Form.Item>

          <Form.Item name="description" label="Mô tả">
            <Input.TextArea rows={2} placeholder="Mô tả ngắn về tiện ích này..." />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
