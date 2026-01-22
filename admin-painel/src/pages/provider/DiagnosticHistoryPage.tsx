import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { collection, query, orderBy, onSnapshot, deleteDoc, doc, Timestamp } from 'firebase/firestore';
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Loader2, Activity, Trash2, Search, Download } from 'lucide-react';
import EmptyState from '@/components/EmptyState';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
    AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

interface DiagnosticResult {
    id: string;
    clientId: string;
    clientName: string;
    clientPlan: string;
    timestamp: string;
    downloadSpeed: number;
    uploadSpeed: number;
    ping: number;
    jitter: number;
    packetLoss: number;
    healthScore: number;
    testMode: string;
    connectionType: string;
    deviceInfo?: {
        model: string;
        os: string;
        appVersion: string;
    };
    additionalData?: {
        wifiRssi?: string;
        onuStatus?: string;
        deviceCount?: string;
    };
    createdAt?: Timestamp;
}

function getScoreColor(score: number): string {
    if (score >= 80) return 'bg-green-500';
    if (score >= 60) return 'bg-yellow-500';
    if (score >= 40) return 'bg-orange-500';
    return 'bg-red-500';
}

function formatDate(timestamp: string | Timestamp): string {
    try {
        const date = timestamp instanceof Timestamp
            ? timestamp.toDate()
            : new Date(timestamp);
        return date.toLocaleString('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch {
        return '-';
    }
}

export default function DiagnosticHistoryPage() {
    const { providerId } = useAuth();
    const [results, setResults] = useState<DiagnosticResult[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [deleteId, setDeleteId] = useState<string | null>(null);

    useEffect(() => {
        if (!providerId) return;

        const q = query(
            collection(db, 'provedores', providerId, 'diagnostic_results'),
            orderBy('createdAt', 'desc')
        );

        const unsubscribe = onSnapshot(q, (snapshot) => {
            const data = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            })) as DiagnosticResult[];
            setResults(data);
            setLoading(false);
        }, (error) => {
            console.error('Error fetching diagnostics:', error);
            toast.error('Erro ao carregar diagnósticos');
            setLoading(false);
        });

        return () => unsubscribe();
    }, [providerId]);

    const handleDelete = async (id: string) => {
        if (!providerId) return;
        try {
            await deleteDoc(doc(db, 'provedores', providerId, 'diagnostic_results', id));
            toast.success('Registro excluído com sucesso');
        } catch (error) {
            console.error('Error deleting:', error);
            toast.error('Erro ao excluir registro');
        }
        setDeleteId(null);
    };

    const exportCSV = () => {
        const headers = ['Cliente', 'Plano', 'Data/Hora', 'Download (Mbps)', 'Upload (Mbps)', 'Ping (ms)', 'Score', 'Modo', 'Conexão'];
        const rows = filteredResults.map(r => [
            r.clientName,
            r.clientPlan,
            formatDate(r.timestamp || r.createdAt!),
            r.downloadSpeed.toFixed(1),
            r.uploadSpeed.toFixed(1),
            r.ping,
            r.healthScore,
            r.testMode,
            r.connectionType
        ]);

        const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `diagnosticos_${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        toast.success('CSV exportado com sucesso');
    };

    const filteredResults = results.filter(r =>
        r.clientName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.clientId?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) {
        return (
            <div className="flex flex-col justify-center items-center h-full text-center">
                <Loader2 className="animate-spin h-8 w-8 mb-4" />
                <p className="text-lg font-semibold">Carregando diagnósticos...</p>
            </div>
        );
    }

    return (
        <Card>
            <CardHeader>
                <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
                    <div>
                        <CardTitle className="flex items-center gap-2">
                            <Activity className="h-5 w-5" />
                            Histórico de Diagnósticos
                        </CardTitle>
                        <CardDescription>
                            {results.length > 0
                                ? `${results.length} testes registrados no total.`
                                : "Nenhum diagnóstico registrado ainda."}
                        </CardDescription>
                    </div>
                    <div className="flex w-full sm:w-auto items-center gap-4">
                        <div className="relative flex-grow sm:flex-grow-0 sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Buscar por cliente..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <Button onClick={exportCSV} variant="outline" disabled={results.length === 0}>
                            <Download className="mr-2 h-4 w-4" />
                            Exportar CSV
                        </Button>
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                {filteredResults.length === 0 ? (
                    <EmptyState
                        icon={Activity}
                        title={searchTerm ? "Nenhum resultado para sua busca" : "Nenhum Diagnóstico Registrado"}
                        description={searchTerm
                            ? `Não foram encontrados diagnósticos para "${searchTerm}".`
                            : "Os diagnósticos feitos pelos clientes no app aparecerão aqui automaticamente."}
                    />
                ) : (
                    <div className="overflow-x-auto">
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>Cliente</TableHead>
                                    <TableHead>Data/Hora</TableHead>
                                    <TableHead className="text-right">↓ Mbps</TableHead>
                                    <TableHead className="text-right">↑ Mbps</TableHead>
                                    <TableHead className="text-right">Ping</TableHead>
                                    <TableHead className="text-center">Score</TableHead>
                                    <TableHead>Modo</TableHead>
                                    <TableHead>Conexão</TableHead>
                                    <TableHead className="text-right">Ações</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {filteredResults.map((result) => (
                                    <TableRow key={result.id}>
                                        <TableCell>
                                            <div>
                                                <div className="font-medium">{result.clientName}</div>
                                                <div className="text-xs text-muted-foreground">{result.clientPlan}</div>
                                            </div>
                                        </TableCell>
                                        <TableCell className="text-sm">
                                            {formatDate(result.timestamp || result.createdAt!)}
                                        </TableCell>
                                        <TableCell className="text-right font-mono">
                                            {result.downloadSpeed.toFixed(1)}
                                        </TableCell>
                                        <TableCell className="text-right font-mono">
                                            {result.uploadSpeed.toFixed(1)}
                                        </TableCell>
                                        <TableCell className="text-right font-mono">
                                            {result.ping}ms
                                        </TableCell>
                                        <TableCell className="text-center">
                                            <Badge className={getScoreColor(result.healthScore)}>
                                                {result.healthScore}
                                            </Badge>
                                        </TableCell>
                                        <TableCell>
                                            <Badge variant="outline">{result.testMode}</Badge>
                                        </TableCell>
                                        <TableCell className="capitalize">{result.connectionType}</TableCell>
                                        <TableCell className="text-right">
                                            <AlertDialog open={deleteId === result.id} onOpenChange={(open) => !open && setDeleteId(null)}>
                                                <AlertDialogTrigger asChild>
                                                    <Button
                                                        variant="ghost"
                                                        size="icon"
                                                        className="h-8 w-8 text-destructive hover:text-destructive"
                                                        onClick={() => setDeleteId(result.id)}
                                                    >
                                                        <Trash2 className="h-4 w-4" />
                                                    </Button>
                                                </AlertDialogTrigger>
                                                <AlertDialogContent>
                                                    <AlertDialogHeader>
                                                        <AlertDialogTitle>Excluir Diagnóstico?</AlertDialogTitle>
                                                        <AlertDialogDescription>
                                                            Esta ação não pode ser desfeita. O registro do diagnóstico de {result.clientName} será permanentemente excluído.
                                                        </AlertDialogDescription>
                                                    </AlertDialogHeader>
                                                    <AlertDialogFooter>
                                                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                        <AlertDialogAction onClick={() => handleDelete(result.id)} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                                                            Excluir
                                                        </AlertDialogAction>
                                                    </AlertDialogFooter>
                                                </AlertDialogContent>
                                            </AlertDialog>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </div>
                )}
            </CardContent>
            {filteredResults.length > 0 && (
                <CardFooter className="text-sm text-muted-foreground">
                    Exibindo {filteredResults.length} de {results.length} registros
                </CardFooter>
            )}
        </Card>
    );
}
