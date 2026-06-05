import { Tabs } from 'antd';

import { DocumentsPage } from './DocumentsPage';
import { PlacesPage } from './PlacesPage';

const tabItems = [
  { key: 'documents', label: 'Tài liệu', children: <DocumentsPage /> },
  { key: 'places', label: 'Địa điểm', children: <PlacesPage /> },
];

export function ContentPage() {
  return <Tabs items={tabItems} />;
}
