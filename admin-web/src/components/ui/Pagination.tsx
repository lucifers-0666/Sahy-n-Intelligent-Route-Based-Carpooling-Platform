import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface PaginationProps {
  page: number;
  totalPages: number;
  totalItems: number;
  limit?: number;
  pageSize?: number;
  onPageChange: (newPage: number) => void;
  itemName?: string;
}

export const Pagination: React.FC<PaginationProps> = ({
  page,
  totalPages,
  totalItems,
  limit,
  pageSize,
  onPageChange,
  itemName = 'records',
}) => {
  if (totalPages <= 1) return null;

  const actualLimit = limit || pageSize || 15;
  const start = Math.min((page - 1) * actualLimit + 1, totalItems);
  const end = Math.min(page * actualLimit, totalItems);

  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-3 border-t border-surface-subtle text-xs">
      <div className="text-textMuted font-medium">
        Showing <span className="font-bold text-textMain">{start}</span>–
        <span className="font-bold text-textMain">{end}</span> of{' '}
        <span className="font-bold text-textMain">{totalItems.toLocaleString()}</span> {itemName}
      </div>

      <div className="flex items-center space-x-2">
        <button
          onClick={() => onPageChange(page - 1)}
          disabled={page <= 1}
          className="px-3 py-1.5 rounded-xl border border-surface-subtle bg-white text-textMain font-semibold hover:bg-surface disabled:opacity-40 disabled:cursor-not-allowed transition-colors flex items-center space-x-1 cursor-pointer"
        >
          <ChevronLeft className="w-3.5 h-3.5" />
          <span>Previous</span>
        </button>

        <span className="px-3 py-1 font-bold text-textMain bg-surface rounded-lg">
          Page {page} of {totalPages}
        </span>

        <button
          onClick={() => onPageChange(page + 1)}
          disabled={page >= totalPages}
          className="px-3 py-1.5 rounded-xl border border-surface-subtle bg-white text-textMain font-semibold hover:bg-surface disabled:opacity-40 disabled:cursor-not-allowed transition-colors flex items-center space-x-1 cursor-pointer"
        >
          <span>Next</span>
          <ChevronRight className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  );
};
