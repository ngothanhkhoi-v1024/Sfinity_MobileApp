import { Card } from 'antd';
import type { ReactNode } from 'react';

interface StatCardProps {
  label: string;
  value: number | string;
  icon: ReactNode;
  accent?: string;
  iconBg?: string;
  hint?: string;
  variant?: 'default' | 'hero';
}

export function StatCard({
  label,
  value,
  icon,
  accent = '#6366f1',
  iconBg = '#eef2ff',
  hint,
  variant = 'default',
}: StatCardProps) {
  return (
    <Card className={`stat-card stat-card--${variant}`} bordered={false}>
      <div className="stat-card-top">
        <div className="stat-card-icon" style={{ background: iconBg, color: accent }}>
          {icon}
        </div>
        {hint && <span className="stat-card-hint">{hint}</span>}
      </div>
      <div className="stat-card-value">{value}</div>
      <div className="stat-card-label">{label}</div>
    </Card>
  );
}
