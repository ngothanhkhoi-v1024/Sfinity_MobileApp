import { Card } from 'antd';
import type { ReactNode } from 'react';

interface StatCardProps {
  label: string;
  value: number | string;
  icon: ReactNode;
  accent?: string;
  iconBg?: string;
}

export function StatCard({ label, value, icon, accent = '#6366f1', iconBg = '#eef2ff' }: StatCardProps) {
  return (
    <Card className="stat-card" bordered={false}>
      <div className="stat-card-icon" style={{ background: iconBg, color: accent }}>
        {icon}
      </div>
      <div className="stat-card-value">{value}</div>
      <div className="stat-card-label">{label}</div>
    </Card>
  );
}
