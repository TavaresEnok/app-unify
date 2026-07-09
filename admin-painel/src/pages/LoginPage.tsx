import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '@/firebase/config';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Loader2 } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

export default function LoginPage() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [failedAttempts, setFailedAttempts] = useState(0);
    const [lockedUntil, setLockedUntil] = useState<number | null>(null);
    const navigate = useNavigate();
    const { user } = useAuth();

    const MAX_ATTEMPTS = 10;
    const LOCKOUT_MINUTES = 15;

    useEffect(() => {
        // O redirecionamento agora é centralizado no App.tsx
        if (user) {
            navigate('/', { replace: true });
        }
    }, [user, navigate]);

    // Verifica se está bloqueado
    const isLocked = lockedUntil !== null && Date.now() < lockedUntil;
    const lockRemainingSeconds = isLocked ? Math.ceil(((lockedUntil ?? 0) - Date.now()) / 1000) : 0;

    // Timer para atualizar o countdown do lockout
    useEffect(() => {
        if (!isLocked) return;
        const interval = setInterval(() => {
            if (lockedUntil && Date.now() >= lockedUntil) {
                setLockedUntil(null);
                setFailedAttempts(0);
            }
        }, 1000);
        return () => clearInterval(interval);
    }, [isLocked, lockedUntil]);

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email || !password) {
            toast.error('Por favor, preencha o email e a senha.');
            return;
        }

        if (isLocked) {
            toast.error(`Conta temporariamente bloqueada. Tente novamente em ${lockRemainingSeconds}s.`);
            return;
        }

        setIsLoading(true);

        // Delay progressivo após falhas (2^n segundos, max 16s)
        if (failedAttempts >= 3) {
            const delayMs = Math.min(Math.pow(2, failedAttempts - 2), 16) * 1000;
            await new Promise(resolve => setTimeout(resolve, delayMs));
        }

        try {
            await signInWithEmailAndPassword(auth, email, password);
            setFailedAttempts(0);
            toast.success('Login bem-sucedido! A redirecionar...');
            // A navegação será tratada pelo useEffect e pelo PostLoginRedirect
        } catch (error: any) {
            const newAttempts = failedAttempts + 1;
            setFailedAttempts(newAttempts);

            if (newAttempts >= MAX_ATTEMPTS) {
                const lockUntil = Date.now() + LOCKOUT_MINUTES * 60 * 1000;
                setLockedUntil(lockUntil);
                toast.error(`Muitas tentativas falhadas. Bloqueado por ${LOCKOUT_MINUTES} minutos.`);
            } else if (newAttempts >= 3) {
                toast.error(`Credenciais inválidas. ${MAX_ATTEMPTS - newAttempts} tentativas restantes.`);
            } else {
                toast.error('Falha no login. Verifique suas credenciais.');
            }
            console.error(error);
        } finally {
            setIsLoading(false);
        }
    };

    if (user) {
        return null;
    }

    return (
        <div className="flex min-h-screen items-center justify-center bg-background">
            <Card className="w-full max-w-sm">
                <CardHeader>
                    <CardTitle className="text-2xl">Login</CardTitle>
                    <CardDescription>Insira seu email e senha para aceder ao painel.</CardDescription>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleLogin} className="grid gap-4">
                        <div className="grid gap-2">
                            <Label htmlFor="email">Email</Label>
                            <Input id="email" type="email" placeholder="m@example.com" required value={email} onChange={(e) => setEmail(e.target.value)} disabled={isLoading} />
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="password">Senha</Label>
                            <Input id="password" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} disabled={isLoading} />
                        </div>
                        <Button type="submit" className="w-full" disabled={isLoading}>
                            {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Entrar
                        </Button>
                    </form>
                </CardContent>
            </Card>
        </div>
    );
}
