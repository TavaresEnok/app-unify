import { ReactNode } from "react";
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export interface DataTableColumn {
  label?: ReactNode;
  className?: string;
}

interface DataTableProps<T> {
  title: ReactNode;
  description?: ReactNode;
  actions?: ReactNode;
  columns: DataTableColumn[];
  gridTemplate: string;
  rows: T[];
  getRowKey: (row: T, index: number) => string;
  renderRow: (row: T, index: number) => ReactNode;
  empty?: ReactNode;
  footer?: ReactNode;
  className?: string;
  minWidth?: string;
}

export default function DataTable<T>({
  title,
  description,
  actions,
  columns,
  gridTemplate,
  rows,
  getRowKey,
  renderRow,
  empty,
  footer,
  className,
  minWidth = "820px",
}: DataTableProps<T>) {
  return (
    <Card className={cn("overflow-hidden", className)}>
      <div className="flex flex-row flex-wrap items-center justify-between gap-3 border-b border-[#EEF0F4] p-[18px]">
        <div className="min-w-0">
          <h2 className="text-[15px] font-semibold leading-none tracking-normal text-[#0E1320]">{title}</h2>
          {description && <p className="mt-1 text-[12.5px] leading-5 text-[#687181]">{description}</p>}
        </div>
        {actions && <div className="flex w-full flex-wrap items-center gap-2 sm:w-auto">{actions}</div>}
      </div>

      {rows.length === 0 ? (
        <div className="p-8">{empty}</div>
      ) : (
        <div className="overflow-x-auto">
          <div style={{ minWidth }}>
            <div
              className="grid gap-x-3 border-b border-[#EEF0F4] bg-[#FAFBFC] px-[18px] py-2.5 text-[11px] font-semibold uppercase tracking-[0.06em] text-[#77808F]"
              style={{ gridTemplateColumns: gridTemplate }}
            >
              {columns.map((column, index) => (
                <span key={index} className={column.className}>
                  {column.label}
                </span>
              ))}
            </div>
            {rows.map((row, index) => (
              <div key={getRowKey(row, index)}>{renderRow(row, index)}</div>
            ))}
          </div>
        </div>
      )}

      {footer && <div className="border-t border-[#EEF0F4] px-[18px] py-3">{footer}</div>}
    </Card>
  );
}
