import { LucideIcon } from 'lucide-react';
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

interface StatsCardProps {
    title: string;
    value: number | string;
    icon: LucideIcon;
    trend?: number; // Porcentagem de crescimento (opcional)
    trendLabel?: string;
}

export default function StatsCard({ title, value, icon: Icon, trend, trendLabel = "vs. mês passado" }: StatsCardProps) {
    const trendState = trend === undefined ? 'neutral' : trend > 0 ? 'up' : trend < 0 ? 'down' : 'neutral';
    const trendText = trend === undefined ? 'Atual' : trend > 0 ? `+${trend}%` : trend < 0 ? `${trend}%` : '0%';
    const trendClasses = {
        up: 'bg-[#EAF7EF] text-[#157347]',
        down: 'bg-[#FDECEC] text-[#C2362B]',
        neutral: 'bg-[#EEF2FF] text-primary',
    }[trendState];

    return (
        <Card className="relative overflow-hidden p-4 transition-colors hover:bg-[#FDFEFF]">
            <div className="mb-2.5 flex items-center justify-between gap-3">
                <div className="text-[12.5px] font-medium text-[#687181]">{title}</div>
                <Icon className="h-4 w-4 text-[#B9C0CC]" strokeWidth={1.8} />
            </div>
            <div className="mb-2 text-[26px] font-bold leading-none tracking-normal text-[#0E1320]">{value}</div>
            <div className="flex items-center gap-2">
                <span className={cn("rounded-full px-2 py-0.5 text-[11.5px] font-semibold", trendClasses)}>{trendText}</span>
                <span className="text-[11.5px] text-[#98A1B1]">{trend === undefined ? "dados em tempo real" : trendLabel}</span>
            </div>
        </Card>
    );
}
