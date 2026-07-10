import { useContext, useState, useEffect, useCallback } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Loader2, Phone, Mail, MapPin, Trash2, MessageCircle } from 'lucide-react';
import { toast } from 'sonner';
import AddEditContactDialog from '@/components/dialogs/AddEditContactDialog';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

interface SupportContact {
    id: string;
    name: string;
    type: 'phone' | 'email' | 'address' | 'whatsapp';
    value: string;
}

// ... (in component)

// Mapeia o tipo para um ícone
const getIcon = (type: 'phone' | 'email' | 'address' | 'whatsapp') => {
    switch (type) {
        case 'phone': return <Phone className="h-5 w-5 text-gray-600" />;
        case 'whatsapp': return <MessageCircle className="h-5 w-5 text-green-600" />;
        case 'email': return <Mail className="h-5 w-5 text-red-600" />;
        case 'address': return <MapPin className="h-5 w-5 text-blue-600" />;
        default: return null;
    }
};

export default function SupportSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    const [localContacts, setLocalContacts] = useState<SupportContact[]>(config.supportContacts || []);

    useEffect(() => {
        setLocalContacts(config.supportContacts || []);
    }, [config.supportContacts]);

    // Função interna para atualizar o contexto e o estado local
    const updateAndSave = (updatedContacts: SupportContact[]) => {
        setLocalContacts(updatedContacts);

        // Atualiza o contexto
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev: ProviderConfig) => ({ ...prev, supportContacts: updatedContacts }));
    };

    // CORRIGIDO: Assinatura da função para corresponder ao AddEditContactDialog
    const handleSaveContact = (contact: Omit<SupportContact, 'id'>, id?: string) => {
        if (id) {
            // Edição
            const updatedContacts = localContacts.map(c =>
                c.id === id ? { ...c, ...contact } : c
            );
            updateAndSave(updatedContacts);
            toast.success("Contato atualizado. Salve no topo para confirmar.");
        } else {
            // Adição
            const newContact: SupportContact = { id: `contact-${Date.now()}`, ...contact };
            const updatedContacts = [...localContacts, newContact];
            updateAndSave(updatedContacts);
            toast.success("Contato adicionado. Salve no topo para confirmar.");
        }
    };

    const handleRemoveContact = (id: string) => {
        const updatedContacts = localContacts.filter(c => c.id !== id);
        updateAndSave(updatedContacts);
        toast.warning("Contato removido. Salve no topo para confirmar.");
    };



    return (
        <SettingsPage
            title="Contatos de Suporte"
            description="Gerencie os telefones, emails e endereços exibidos na tela de suporte do app."
            icon={Phone}
            actions={<AddEditContactDialog onSave={handleSaveContact} />}
        >
            <SettingsSection title="Lista de contatos" description="Canais que aparecem para o assinante no aplicativo.">
                {localContacts.length === 0 ? (
                    <p className="rounded-lg border border-dashed border-[#C6CDD9] bg-white p-6 text-center text-sm text-muted-foreground">Nenhum contato configurado ainda.</p>
                ) : (
                    <div className="space-y-3">
                        <Label className="text-[12.5px] font-semibold text-[#39414F]">Contatos cadastrados</Label>
                        <div className="grid gap-4">
                            {localContacts.map((contact) => (
                                <div key={contact.id} className="flex flex-col justify-between gap-3 rounded-lg border border-[#EEF0F4] bg-white p-3 sm:flex-row sm:items-center">
                                    <div className="flex items-center gap-4">
                                        {getIcon(contact.type)}
                                        <div>
                                            <p className="font-medium">{contact.name}</p>
                                            <p className="text-sm text-muted-foreground">{contact.value}</p>
                                        </div>
                                    </div>
                                    <div className="flex gap-2">
                                        {/* Diálogo de Edição */}
                                        <AddEditContactDialog
                                            contact={contact}
                                            onSave={handleSaveContact}
                                            onDelete={handleRemoveContact}
                                        />
                                        <Button
                                            variant="destructive"
                                            size="icon"
                                            onClick={() => handleRemoveContact(contact.id)}
                                            disabled={isSaving}
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </SettingsSection>
        </SettingsPage>
    );
}
