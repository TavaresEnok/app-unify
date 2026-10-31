import { LucideIcon } from 'lucide-react';
import { Card } from "@/components/ui/card";

interface StatsCardProps {
    title: string;
    value: number | string;
    icon: LucideIcon;
    trend?: number; // Porcentagem de crescimento (opcional)
    trendLabel?: string;
    description?: string;
}

export default function StatsCard({ title, value, icon: Icon, description }: StatsCardProps) {

    return (
        <Card className="relative overflow-hidden p-4 transition-colors hover:bg-[#FDFEFF]">
            <div className="mb-2.5 flex items-center justify-between gap-3">
                <div className="text-[12.5px] font-medium text-[#687181]">{title}</div>
                <Icon className="h-4 w-4 text-[#B9C0CC]" strokeWidth={1.8} />
            </div>
            <div className="mb-2 text-[26px] font-bold leading-none tracking-normal text-[#0E1320]">{value}</div>
            <div className="flex items-center gap-2">
                {description && <span className="text-[11.5px] text-[#98A1B1]">{description}</span>}
            </div>
        </Card>
    );
}
