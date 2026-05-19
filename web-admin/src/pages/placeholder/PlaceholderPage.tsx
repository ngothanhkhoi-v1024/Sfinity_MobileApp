import { Typography } from 'antd';

interface PlaceholderPageProps {
  title: string;
}

export function PlaceholderPage({ title }: PlaceholderPageProps) {
  return (
    <div>
      <Typography.Title level={4} style={{ marginTop: 0 }}>
        {title}
      </Typography.Title>
      <Typography.Text type="secondary">Trang đang được phát triển.</Typography.Text>
    </div>
  );
}
