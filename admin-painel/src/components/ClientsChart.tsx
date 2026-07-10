import { Bar, BarChart, XAxis, YAxis, Tooltip, ResponsiveContainer, LabelList } from 'recharts';
interface ChartData { name: string; clientes: number; }
export default function ClientsChart({ data }: { data: ChartData[] }) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={data}>
        <XAxis dataKey="name" stroke="#98A1B1" fontSize={11} tickLine={false} axisLine={false} />
        <YAxis stroke="#98A1B1" fontSize={11} tickLine={false} axisLine={false} />
        <Tooltip cursor={{fill: '#F4F6FA'}} contentStyle={{backgroundColor: '#FFFFFF', borderColor: '#E6E9EF', borderRadius: 8, fontSize: 12}}/>
        <Bar dataKey="clientes" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]}>
           <LabelList dataKey="clientes" position="top" style={{ fill: '#687181', fontSize: 11 }} />
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
