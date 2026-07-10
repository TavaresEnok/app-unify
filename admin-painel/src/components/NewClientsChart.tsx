// src/components/NewClientsChart.tsx
import { Bar, BarChart, ResponsiveContainer, XAxis, YAxis, Tooltip, Legend } from "recharts";

interface NewClientsChartProps {
  data: {
    name: string;
    clientes: number;
  }[];
}

export default function NewClientsChart({ data }: NewClientsChartProps) {
    const tickColor = '#98A1B1';

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
                        backgroundColor: '#FFFFFF',
                        borderColor: '#E6E9EF',
                        borderRadius: 8,
                        fontSize: 12,
                    }}
                />
                <Legend />
                <Bar dataKey="clientes" name="Novos Clientes" fill="#2F55D4" radius={[4, 4, 0, 0]} />
            </BarChart>
        </ResponsiveContainer>
    );
}
