import { ToolOutlined } from '@ant-design/icons';
import { Typography } from 'antd';

import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

interface PlaceholderPageProps {
  title: string;
}

export function PlaceholderPage({ title }: PlaceholderPageProps) {
  return (
    <PageShell>
      <PageHeader title={title} description="Tính năng đang được phát triển" />
      <div
        style={{
          textAlign: 'center',
          padding: '64px 24px',
          color: '#94a3b8',
        }}
      >
        <ToolOutlined style={{ fontSize: 48, marginBottom: 16, opacity: 0.5 }} />
        <Typography.Text type="secondary">Sẽ có sẵn trong phiên bản tiếp theo</Typography.Text>
      </div>
    </PageShell>
  );
}
