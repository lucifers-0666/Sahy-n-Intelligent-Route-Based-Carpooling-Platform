import React from 'react';

interface PageHeaderProps {
  title: string;
  description?: string;
  subtitle?: string;
  badge?: string;
  badgeVariant?: 'emerald' | 'amber' | 'blue' | 'purple';
  actions?: React.ReactNode;
  breadcrumbs?: Array<{ label: string; onClick?: () => void }>;
}

export const PageHeader: React.FC<PageHeaderProps> = ({
  title,
  description,
  subtitle,
  badge,
  badgeVariant = 'emerald',
  actions,
  breadcrumbs,
}) => {
  const displayDesc = description || subtitle;
  const badgeClasses = {
    emerald: 'bg-forest-light text-forest border-emerald-200',
    amber: 'bg-amber-50 text-amber-800 border-amber-200',
    blue: 'bg-blue-50 text-blue-800 border-blue-200',
    purple: 'bg-purple-50 text-purple-800 border-purple-200',
  }[badgeVariant];

  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-1 border-b border-surface-subtle">
      <div>
        {breadcrumbs && breadcrumbs.length > 0 && (
          <nav className="flex items-center space-x-1.5 text-xs text-textMuted mb-1.5">
            {breadcrumbs.map((crumb, i) => (
              <React.Fragment key={i}>
                {i > 0 && <span className="text-textLight">/</span>}
                {crumb.onClick ? (
                  <button
                    onClick={crumb.onClick}
                    className="hover:text-forest transition-colors cursor-pointer"
                  >
                    {crumb.label}
                  </button>
                ) : (
                  <span className="font-semibold text-textMain">{crumb.label}</span>
                )}
              </React.Fragment>
            ))}
          </nav>
        )}

        <div className="flex items-center space-x-2.5">
          <h1 className="text-xl sm:text-2xl font-extrabold text-textMain tracking-tight">
            {title}
          </h1>
          {badge && (
            <span
              className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full border ${badgeClasses}`}
            >
              {badge}
            </span>
          )}
        </div>

        {displayDesc && (
          <p className="text-xs text-textMuted font-medium mt-1 max-w-3xl">
            {displayDesc}
          </p>
        )}
      </div>

      {actions && <div className="flex items-center space-x-2 shrink-0">{actions}</div>}
    </div>
  );
};
