import { useState, type FormEvent } from 'react';
import { Eye, EyeOff, Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';

interface Props {
    email: string;
    format: 'apk' | 'aab';
    onConfirm: (password: string) => Promise<void>;
    onCancel: () => void;
}

export default function BuildConfirmationDialog({ email, format, onConfirm, onCancel }: Props) {
    const [password, setPassword] = useState('');
    const [visible, setVisible] = useState(false);
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState('');

    const submit = async (event: FormEvent) => {
        event.preventDefault();
        if (busy) return;
        setBusy(true);
        setError('');
        try {
            await onConfirm(password);
            setPassword('');
        } catch (failure) {
            const code = failure && typeof failure === 'object' && 'code' in failure ? String(failure.code) : '';
            setError(['auth/invalid-credential', 'auth/wrong-password'].includes(code)
                ? 'Senha inválida. Confira e tente novamente.'
                : code === 'auth/too-many-requests'
                    ? 'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.'
                    : 'Não foi possível confirmar sua senha. Tente novamente.');
        } finally { setBusy(false); }
    };

    return <Dialog open onOpenChange={open => { if (!open && !busy) onCancel(); }}>
        <DialogContent className="max-w-[calc(100%-2rem)] sm:max-w-md">
            <DialogHeader>
                <DialogTitle>Confirmar geração</DialogTitle>
                <DialogDescription>Confirme sua senha para gerar o aplicativo. Você continua no painel e suas configurações serão mantidas.</DialogDescription>
            </DialogHeader>
            <form onSubmit={submit} className="space-y-4">
                <div className="space-y-2">
                    <Label htmlFor="build-confirm-email">Conta de gerente</Label>
                    <Input id="build-confirm-email" type="email" autoComplete="username" value={email} readOnly />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="build-confirm-password">Senha</Label>
                    <div className="relative">
                        <Input id="build-confirm-password" type={visible ? 'text' : 'password'} autoComplete="current-password"
                            autoFocus required value={password} onChange={event => setPassword(event.target.value)}
                            disabled={busy} className="pr-12" aria-invalid={!!error} aria-describedby={error ? 'build-confirm-error' : undefined} />
                        <Button type="button" variant="ghost" className="absolute inset-y-0 right-0 w-11 px-0" disabled={busy}
                            aria-label={visible ? 'Ocultar senha' : 'Mostrar senha'} aria-controls="build-confirm-password"
                            aria-pressed={visible} onClick={() => setVisible(value => !value)}>
                            {visible ? <EyeOff className="h-4 w-4" aria-hidden="true" /> : <Eye className="h-4 w-4" aria-hidden="true" />}
                        </Button>
                    </div>
                    {error && <p id="build-confirm-error" role="alert" className="text-sm text-destructive">{error}</p>}
                </div>
                <DialogFooter className="gap-2 sm:gap-0">
                    <Button type="button" variant="outline" disabled={busy} onClick={onCancel}>Cancelar</Button>
                    <Button type="submit" disabled={busy || !password}>
                        {busy && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Confirmar e gerar {format.toUpperCase()}
                    </Button>
                </DialogFooter>
            </form>
        </DialogContent>
    </Dialog>;
}
