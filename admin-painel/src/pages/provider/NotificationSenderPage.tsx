import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useApi } from '@/hooks/useApi';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Send, Loader2 } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
// Import de useEffect removido - TS6133

// Tipos de Filtro (MOCK, na realidade deveriam vir de uma API de lista de planos/status)
const statusOptions = [
    { value: 'all', label: 'Todos os Status' },
    { value: 'Ativo', label: 'Ativos' },
    { value: 'Suspenso', label: 'Suspensos (Inadimplentes)' },
    { value: 'Ativo V. Reduzida', label: 'Ativos (Velocidade Reduzida)' },
    { value: 'Cancelado', label: 'Cancelados' },
];

const planOptions = [
    { value: 'all', label: 'Todos os Planos' },
    { value: 'VIBE 500 MEGA', label: 'VIBE 500 MEGA' },
    { value: 'VIBE 1 GIGA', label: 'VIBE 1 GIGA' },
    { value: 'ECONOMICO 100', label: 'ECONOMICO 100' },
];

export default function NotificationSenderPage() {
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');
    const [planFilter, setPlanFilter] = useState('all');

    const { callFunction, loading } = useApi();
    const { providerId, user } = useAuth();
    
    const handleSendNotification = async () => {
        if (!user) {
            toast.error("Erro de Autenticação", { description: "Usuário não autenticado." });
            return;
        }
        if (!title.trim() || !body.trim()) {
            toast.error("Erro de Validação", { description: "O título e a mensagem não podem estar vazios." });
            return;
        }

        try {
            await callFunction('SEND_SCOPED_NOTIFICATION_SEGMENTED', {
                // O providerId é incluído, mas o hook useApi o sobrescreverá com o ID do token para garantir segurança.
                providerId, 
                title,
                body,
                statusFilter: statusFilter,
                planFilter: planFilter,
            });
            
            // Limpa após o sucesso
            setTitle('');
            setBody('');
            setStatusFilter('all');
            setPlanFilter('all');
            
        } catch (error) {
            // O hook useApi já trata os erros com toast.
        }
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Enviar Notificação Push Segmentada</CardTitle>
                <CardDescription>
                    Envie uma mensagem para clientes específicos do seu provedor que têm o aplicativo instalado.
                </CardDescription>
            </CardHeader>
            <CardContent>
                <div className="grid gap-6">
                    
                    <div className="grid gap-4 sm:grid-cols-2">
                        {/* Filtro por Status */}
                        <div className="grid gap-2">
                            <Label htmlFor="statusFilter">Filtrar por Status</Label>
                            <Select value={statusFilter} onValueChange={setStatusFilter} disabled={loading}>
                                <SelectTrigger id="statusFilter">
                                    <SelectValue placeholder="Selecione um status" />
                                </SelectTrigger>
                                <SelectContent>
                                    {statusOptions.map(option => (
                                        <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                        
                        {/* Filtro por Plano */}
                        <div className="grid gap-2">
                            <Label htmlFor="planFilter">Filtrar por Plano</Label>
                            <Select value={planFilter} onValueChange={setPlanFilter} disabled={loading}>
                                <SelectTrigger id="planFilter">
                                    <SelectValue placeholder="Selecione um plano" />
                                </SelectTrigger>
                                <SelectContent>
                                    {planOptions.map(option => (
                                        <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                    </div>
                    
                    <div className="grid gap-2">
                        <Label htmlFor="title">Título da Notificação</Label>
                        <Input
                            id="title"
                            placeholder="Ex: Aviso Importante (máx. 50 caracteres)"
                            value={title}
                            onChange={(e) => setTitle(e.target.value.substring(0, 50))}
                            disabled={loading}
                        />
                    </div>
                    <div className="grid gap-2">
                        <Label htmlFor="body">Mensagem</Label>
                        <Textarea
                            id="body"
                            placeholder="Digite sua mensagem aqui..."
                            value={body}
                            onChange={(e) => setBody(e.target.value)}
                            rows={5}
                            disabled={loading}
                        />
                    </div>
                    <Button onClick={handleSendNotification} disabled={loading}>
                        {loading ? (
                            <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Enviando...
                            </>
                        ) : (
                            <>
                                <Send className="mr-2 h-4 w-4" />
                                Enviar Notificação
                            </>
                        )}
                    </Button>
                </div>
            </CardContent>
        </Card>
    );
}
