import type { ReactNode } from 'react';

interface PageShellProps {
  children: ReactNode;
  noCard?: boolean;
}

export function PageShell({ children, noCard = false }: PageShellProps) {
  return (
    <div className="page-enter">
      {noCard ? children : <div className="admin-page-card">{children}</div>}
    </div>
  );
}
