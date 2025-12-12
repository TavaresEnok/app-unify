import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LucideIcon } from 'lucide-react';

interface StatsCardProps {
    title: string;
    value: number | string;
    icon: LucideIcon;
    trend?: number; // Porcentagem de crescimento (opcional)
    trendLabel?: string;
}

export default function StatsCard({ title, value, icon: Icon, trend, trendLabel = "vs. mês passado" }: StatsCardProps) {
    return (
        <Card className="hover:shadow-md transition-shadow duration-200">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
                <Icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
                <div className="text-2xl font-bold">{value}</div>
                {trend !== undefined && (
                    <p className="text-xs text-muted-foreground mt-1 flex items-center">
                        {trend > 0 ? (
                            <span className="text-emerald-500 flex items-center font-medium">
                                +{trend}% <span className="ml-1">↗</span>
                            </span>
                        ) : trend < 0 ? (
                            <span className="text-rose-500 flex items-center font-medium">
                                {trend}% <span className="ml-1">↘</span>
                            </span>
                        ) : (
                            <span className="text-muted-foreground flex items-center">
                                0% <span className="ml-1">-</span>
                            </span>
                        )}
                        <span className="ml-2 opacity-80">{trendLabel}</span>
                    </p>
                )}
            </CardContent>
        </Card>
    );
}
