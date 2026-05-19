import { DeleteOutlined, PlusOutlined } from '@ant-design/icons';
import { Button, Form, Input, Modal, Popconfirm, Space, Table, Typography, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useCallback, useEffect, useState } from 'react';

import {
  createCategory,
  deleteCategory,
  fetchCategories,
  updateCategory,
  type CategoryItem,
} from '@/api/categories';

export function CategoriesPage() {
  const [data, setData] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<CategoryItem | null>(null);
  const [form] = Form.useForm();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setData(await fetchCategories());
    } catch {
      message.error('Không tải được danh mục');
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

  const openEdit = (item: CategoryItem) => {
    setEditing(item);
    form.setFieldsValue(item);
    setModalOpen(true);
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    try {
      if (editing) {
        await updateCategory(editing.id, values);
        message.success('Đã cập nhật');
      } else {
        await createCategory(values);
        message.success('Đã tạo danh mục');
      }
      setModalOpen(false);
      load();
    } catch {
      message.error('Lưu thất bại');
    }
  };

  const columns: ColumnsType<CategoryItem> = [
    { title: 'Tên', dataIndex: 'name' },
    { title: 'Slug', dataIndex: 'slug' },
    { title: 'Mô tả', dataIndex: 'description', ellipsis: true },
    { title: 'Số bài', dataIndex: ['_count', 'contents'] },
    {
      title: 'Thao tác',
      key: 'actions',
      render: (_, record) => (
        <Space>
          <Button size="small" onClick={() => openEdit(record)}>
            Sửa
          </Button>
          <Popconfirm title="Xóa danh mục?" onConfirm={async () => {
            await deleteCategory(record.id);
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
          Danh mục
        </Typography.Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
          Thêm danh mục
        </Button>
      </Space>

      <Table rowKey="id" loading={loading} columns={columns} dataSource={data} />

      <Modal
        title={editing ? 'Sửa danh mục' : 'Thêm danh mục'}
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText="Lưu"
      >
        <Form form={form} layout="vertical">
          <Form.Item name="name" label="Tên" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="slug" label="Slug" rules={[{ required: true }]}>
            <Input placeholder="tin-tuc" />
          </Form.Item>
          <Form.Item name="description" label="Mô tả">
            <Input.TextArea rows={3} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
