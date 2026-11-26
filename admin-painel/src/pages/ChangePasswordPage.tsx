import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { KeyRound, Loader2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { changeOwnPassword } from "@/shared/auth/session";
import { changePasswordFormError } from "@/lib/passwordPolicy";
import { getErrorMessage } from "@/shared/errors";
import { useAuth } from "@/contexts/AuthContext";

export default function ChangePasswordPage() {
  const navigate = useNavigate();
  const { userRole } = useAuth();
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    const formError = changePasswordFormError(current, next, confirm);
    setError(formError);
    if (formError) return;
    setSaving(true);
    try {
      const { relogin } = await changeOwnPassword(current, next);
      setCurrent(""); setNext(""); setConfirm("");
      if (relogin) {
        toast.success("Senha alterada. Entre novamente com a nova senha.");
        navigate("/login", { replace: true });
        return;
      }
      toast.success("Senha alterada. Outros computadores conectados foram desconectados.");
      // Aberta por link direto não há tela anterior: volta para o início.
      navigate(userRole === "superAdmin" ? "/dashboard" : "/provedor/dashboard", { replace: true });
    } catch (err) {
      setError(getErrorMessage(err, "Não foi possível alterar a senha."));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Card className="mx-auto max-w-lg">
      <CardHeader className="border-b border-[#EEF0F4]">
        <CardTitle className="flex items-center gap-2"><KeyRound className="h-4 w-4" aria-hidden="true" />Alterar senha</CardTitle>
        <p className="mt-0.5 text-[12.5px] text-[#687181]">Use pelo menos 10 caracteres, com letra maiúscula, minúscula e número.</p>
      </CardHeader>
      <CardContent className="p-[18px]">
        <form className="grid gap-3.5" onSubmit={submit} noValidate>
          <div className="grid gap-1.5">
            <Label htmlFor="current-password">Senha atual</Label>
            <Input id="current-password" type="password" autoComplete="current-password" value={current} onChange={(e) => setCurrent(e.target.value)} disabled={saving} />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="new-password">Nova senha</Label>
            <Input id="new-password" type="password" autoComplete="new-password" value={next} onChange={(e) => setNext(e.target.value)} disabled={saving} />
          </div>
          <div className="grid gap-1.5">
            <Label htmlFor="confirm-password">Confirmar nova senha</Label>
            <Input id="confirm-password" type="password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} disabled={saving} />
          </div>
          {error && <p role="alert" className="text-[12.5px] text-destructive">{error}</p>}
          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={() => navigate(-1)} disabled={saving}>Cancelar</Button>
            <Button type="submit" disabled={saving}>{saving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}Salvar nova senha</Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
