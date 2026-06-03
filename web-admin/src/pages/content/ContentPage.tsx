import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';
import { Tabs } from 'antd';
import { DocumentsPage } from './DocumentsPage';
import { PlacesPage } from './PlacesPage';

const tabItems = [
  { key: 'documents', label: 'Tài liệu', children: <DocumentsPage /> },
  { key: 'places', label: 'Địa điểm', children: <PlacesPage /> },
];

export function ContentPage() {
  return (
    <PageShell>
      <PageHeader
        title="Quản lý nội dung"
        description="Xem, ẩn, bỏ ẩn hoặc xóa tài liệu và địa điểm. Thao tác sẽ gửi thông báo lý do cho tác giả."
      />
      <Tabs items={tabItems} />
    </PageShell>
  );
}
