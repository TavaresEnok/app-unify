import { Bar, BarChart, XAxis, YAxis, Tooltip, ResponsiveContainer, LabelList } from 'recharts';
interface ChartData { name: string; clientes: number; }
export default function ClientsChart({ data }: { data: ChartData[] }) {
  return (
    <ResponsiveContainer width="100%" height={350}>
      <BarChart data={data}>
        <XAxis dataKey="name" stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
        <YAxis stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
        <Tooltip cursor={{fill: 'hsl(var(--secondary))'}} contentStyle={{backgroundColor: 'hsl(var(--background))', borderColor: 'hsl(var(--border))'}}/>
        <Bar dataKey="clientes" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]}>
           <LabelList dataKey="clientes" position="top" style={{ fill: 'hsl(var(--foreground))' }} />
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
