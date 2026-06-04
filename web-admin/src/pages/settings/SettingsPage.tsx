import { PageHeader } from '@/components/common/PageHeader';
import { PageShell } from '@/components/common/PageShell';

export function SettingsPage() {
  return (
    <PageShell>
      <PageHeader
        title="Cài đặt hệ thống"
        description="Quản lý cấu hình toàn cục cho ứng dụng Sfinity"
      />
    </PageShell>
  );
}
