// src/components/NewClientsChart.tsx
import { Bar, BarChart, ResponsiveContainer, XAxis, YAxis, Tooltip, Legend } from "recharts";
import { useTheme } from "@/components/theme-provider";

interface NewClientsChartProps {
  data: {
    name: string;
    clientes: number;
  }[];
}

export default function NewClientsChart({ data }: NewClientsChartProps) {
    const { theme } = useTheme();
    const tickColor = theme === 'dark' ? '#A1A1AA' : '#71717A'; // zinc-400 or zinc-500

    if (data.length === 0) {
        return (
            <div className="flex h-[350px] w-full items-center justify-center">
                <p className="text-muted-foreground">Sem dados de novos clientes nos últimos 7 dias.</p>
            </div>
        )
    }

    return (
        <ResponsiveContainer width="100%" height={350}>
            <BarChart data={data}>
                <XAxis
                    dataKey="name"
                    stroke={tickColor}
                    fontSize={12}
                    tickLine={false}
                    axisLine={false}
                />
                <YAxis
                    stroke={tickColor}
                    fontSize={12}
                    tickLine={false}
                    axisLine={false}
                    allowDecimals={false}
                />
                 <Tooltip 
                    cursor={{fill: 'transparent'}}
                    contentStyle={{
                        backgroundColor: theme === 'dark' ? '#09090B' : '#FFFFFF', // zinc-950 or white
                        borderColor: theme === 'dark' ? '#27272A' : '#E4E4E7' // zinc-800 or zinc-200
                    }}
                />
                <Legend />
                <Bar dataKey="clientes" name="Novos Clientes" fill="#8884d8" radius={[4, 4, 0, 0]} />
            </BarChart>
        </ResponsiveContainer>
    );
}
