import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '@/firebase/config';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Check, Loader2 } from 'lucide-react';
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
        } catch (error) {
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

    const features = [
        'Integração nativa com SGP e Firebase',
        'Builds de APK automatizadas por provedor',
        'Notificações push segmentadas em escala',
    ];

    return (
        <div className="grid min-h-screen bg-[#F7F8FA] lg:grid-cols-[1.1fr_1fr]">
            <section className="hidden flex-col justify-between bg-[radial-gradient(1200px_700px_at_20%_-10%,#1A2440_0%,#0D1322_55%)] p-12 lg:flex xl:p-14">
                <div className="flex items-center gap-3">
                    <div className="grid h-[30px] w-[30px] place-items-center rounded-lg bg-gradient-to-br from-primary to-[#16265D] text-[15px] font-bold text-white">
                        U
                    </div>
                    <span className="text-[17px] font-bold text-white">Unify</span>
                </div>

                <div className="max-w-[460px]">
                    <h1 className="m-0 mb-4 text-[34px] font-bold leading-[1.2] tracking-normal text-white">
                        Um app para cada provedor. Uma plataforma para todos.
                    </h1>
                    <p className="m-0 mb-8 text-[15px] leading-6 text-[#9AA5BD]">
                        Gerencie provedores, personalize aplicativos white-label e acompanhe sua base de clientes em um único painel.
                    </p>
                    <div className="flex flex-col gap-3.5">
                        {features.map((feature) => (
                            <div key={feature} className="flex items-center gap-3 text-[13.5px] text-[#C4CCDD]">
                                <span className="grid h-[22px] w-[22px] shrink-0 place-items-center rounded-full bg-white/10 text-[#7E97E8]">
                                    <Check className="h-3 w-3" strokeWidth={2.4} />
                                </span>
                                {feature}
                            </div>
                        ))}
                    </div>
                </div>

                <div className="text-xs text-[#5D6883]">© 2026 Unify · Plataforma multi-provedor</div>
            </section>

            <section className="grid min-h-screen place-items-center px-6 py-10">
                <div className="w-full max-w-[380px] animate-in fade-in slide-in-from-bottom-2 duration-500">
                    <div className="mb-8 flex items-center gap-3 lg:hidden">
                        <div className="grid h-[30px] w-[30px] place-items-center rounded-lg bg-gradient-to-br from-primary to-[#16265D] text-[15px] font-bold text-white">
                            U
                        </div>
                        <span className="text-[17px] font-bold text-[#0E1320]">Unify</span>
                    </div>

                    <h2 className="m-0 mb-1.5 text-[21px] font-bold tracking-normal text-[#0E1320]">Acessar painel</h2>
                    <p className="m-0 mb-[26px] text-[13.5px] text-[#687181]">Insira suas credenciais para continuar.</p>

                    <form onSubmit={handleLogin} className="grid gap-3.5">
                        <div className="grid gap-1.5">
                            <Label htmlFor="email" className="text-[12.5px] font-semibold text-[#39414F]">E-mail</Label>
                            <Input
                                id="email"
                                type="email"
                                placeholder="voce@empresa.com.br"
                                required
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                disabled={isLoading}
                            />
                        </div>

                        <div className="grid gap-1.5">
                            <div className="flex items-baseline justify-between">
                                <Label htmlFor="password" className="text-[12.5px] font-semibold text-[#39414F]">Senha</Label>
                                <button type="button" className="text-xs font-medium text-primary hover:text-[#24439F]">
                                    Esqueceu a senha?
                                </button>
                            </div>
                            <Input
                                id="password"
                                type="password"
                                placeholder="••••••••"
                                required
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                disabled={isLoading || isLocked}
                            />
                        </div>

                        {isLocked && (
                            <div className="rounded-lg border border-destructive/20 bg-destructive/5 px-3 py-2 text-[12.5px] text-destructive">
                                Muitas tentativas. Tente novamente em {lockRemainingSeconds}s.
                            </div>
                        )}

                        <Button type="submit" className="mt-1 h-[39px] w-full" disabled={isLoading || isLocked}>
                            {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Entrar
                        </Button>
                    </form>
                </div>
            </section>
        </div>
    );
}
