import { DeleteOutlined, PlusOutlined } from '@ant-design/icons';
import {
  Button,
  Form,
  Input,
  Modal,
  Popconfirm,
  Select,
  Space,
  Table,
  Tag,
  Typography,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import { fetchCategories, type CategoryItem } from '@/api/categories';
import {
  createContent,
  deleteContent,
  fetchContent,
  publishContent,
  unpublishContent,
  updateContent,
  type ContentItem,
} from '@/api/content';

export function ContentPage() {
  const [data, setData] = useState<ContentItem[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<ContentItem | null>(null);
  const [form] = Form.useForm();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchContent();
      setData(res.items);
    } catch {
      message.error('Không tải được nội dung');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    fetchCategories().then(setCategories).catch(() => {});
  }, [load]);

  const openCreate = () => {
    setEditing(null);
    form.resetFields();
    form.setFieldsValue({ status: 'DRAFT' });
    setModalOpen(true);
  };

  const openEdit = (item: ContentItem) => {
    setEditing(item);
    form.setFieldsValue({
      title: item.title,
      body: item.body,
      status: item.status,
      categoryId: item.categoryId,
    });
    setModalOpen(true);
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    try {
      if (editing) {
        await updateContent(editing.id, values);
        message.success('Đã cập nhật');
      } else {
        await createContent(values);
        message.success('Đã tạo nội dung');
      }
      setModalOpen(false);
      load();
    } catch {
      message.error('Lưu thất bại');
    }
  };

  const togglePublish = async (item: ContentItem) => {
    try {
      if (item.status === 'PUBLISHED') {
        await unpublishContent(item.id);
      } else {
        await publishContent(item.id);
      }
      message.success('Cập nhật trạng thái');
      load();
    } catch {
      message.error('Thất bại');
    }
  };

  const columns: ColumnsType<ContentItem> = [
    { title: 'Tiêu đề', dataIndex: 'title', ellipsis: true },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      render: (s: string) => (
        <Tag color={s === 'PUBLISHED' ? 'green' : 'default'}>
          {s === 'PUBLISHED' ? 'Đã xuất bản' : 'Nháp'}
        </Tag>
      ),
    },
    { title: 'Tác giả', dataIndex: ['author', 'name'] },
    { title: 'Danh mục', dataIndex: ['category', 'name'] },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 220,
      render: (_, record) => (
        <Space>
          <Button size="small" onClick={() => openEdit(record)}>
            Sửa
          </Button>
          <Button size="small" onClick={() => togglePublish(record)}>
            {record.status === 'PUBLISHED' ? 'Ẩn' : 'Xuất bản'}
          </Button>
          <Popconfirm title="Xóa?" onConfirm={async () => {
            await deleteContent(record.id);
            load();
          }}>
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
          Quản lý nội dung
        </Typography.Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
          Thêm nội dung
        </Button>
      </Space>

      <Table rowKey="id" loading={loading} columns={columns} dataSource={data} pagination={{ pageSize: 10 }} />

      <Modal
        title={editing ? 'Sửa nội dung' : 'Thêm nội dung'}
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText="Lưu"
        width={640}
      >
        <Form form={form} layout="vertical">
          <Form.Item name="title" label="Tiêu đề" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="body" label="Nội dung" rules={[{ required: true }]}>
            <Input.TextArea rows={6} />
          </Form.Item>
          <Form.Item name="status" label="Trạng thái">
            <Select
              options={[
                { value: 'DRAFT', label: 'Nháp' },
                { value: 'PUBLISHED', label: 'Xuất bản' },
              ]}
            />
          </Form.Item>
          <Form.Item name="categoryId" label="Danh mục">
            <Select allowClear options={categories.map((c) => ({ value: c.id, label: c.name }))} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
