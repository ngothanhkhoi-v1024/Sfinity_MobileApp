import { DeleteOutlined, EditOutlined, PlusOutlined, SearchOutlined } from '@ant-design/icons';
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

export function DocCategoriesPage() {
  const [data, setData] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<CategoryItem | null>(null);
  const [form] = Form.useForm();
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setData(await fetchCategories('DOCUMENT'));
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
        await updateCategory(editing.id, values);
        message.success('Đã cập nhật');
      } else {
        await createCategory({ ...values, type: 'DOCUMENT' });
        message.success('Đã tạo danh mục');
      }
      setModalOpen(false);
      load();
    } catch {
      message.error('Lưu thất bại');
    }
  };

  const filtered = data.filter(
    (item) =>
      item.name.toLowerCase().includes(search.toLowerCase()) ||
      (item.description ?? '').toLowerCase().includes(search.toLowerCase()),
  );

  const columns: ColumnsType<CategoryItem> = [
    { title: 'Tên', dataIndex: 'name' },
    { title: 'Mô tả', dataIndex: 'description', ellipsis: true },
    {
      title: 'Số mục',
      dataIndex: ['_count', 'documents'],
      width: 100,
      render: (v: number) => v ?? 0,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 160,
      render: (_, record) => (
        <Space>
          <Button size="small" icon={<EditOutlined />} onClick={() => openEdit(record)} />
          <Popconfirm
            title="Xóa danh mục này?"
            onConfirm={async () => {
              await deleteCategory(record.id);
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
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
      <Typography.Title level={4} style={{ margin: 0 }}>
        Danh mục tài liệu
      </Typography.Title>
      <Space>
        <Input
          placeholder="Tìm theo tên, mô tả..."
          prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          allowClear
          style={{ width: 260 }}
        />
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
          Thêm danh mục
        </Button>
      </Space>
    </div>

      <Table
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={filtered}
        pagination={{ pageSize: 10 }}
        scroll={{ x: 800 }}
        locale={{ emptyText: 'Chưa có danh mục tài liệu nào' }}
      />

      <Modal
        title={editing ? 'Sửa danh mục' : 'Thêm danh mục tài liệu'}
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleSubmit}
        okText="Lưu"
      >
        <Form form={form} layout="vertical">
          <Form.Item name="name" label="Tên" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="description" label="Mô tả">
            <Input.TextArea rows={3} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
