import { useState } from "react";
import { KeyRound, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { validateAdminPassword } from "@/lib/passwordPolicy";
import { resetAdminUserPassword } from "@/shared/api/adminUsers";
import { getErrorMessage } from "@/shared/errors";

export default function ResetPasswordDialog({ uid, email }: { uid: string; email?: string }) {
  const [open, setOpen] = useState(false);
  const [password, setPassword] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const close = (next: boolean) => {
    setOpen(next);
    if (!next) { setPassword(""); setError(null); }
  };

  const save = async () => {
    const check = validateAdminPassword(password);
    if (!check.valid) { setError(`Senha: ${check.errors.join(", ").toLowerCase()}.`); return; }
    setSaving(true);
    try {
      await resetAdminUserPassword(uid, password);
      toast.success("Senha redefinida. Envie a nova senha à pessoa por um canal seguro.");
      close(false);
    } catch (err) {
      setError(getErrorMessage(err, "Não foi possível redefinir a senha."));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={close}>
      <DialogTrigger asChild>
        <Button variant="outline" size="icon" aria-label={`Redefinir senha de ${email || uid}`} title="Redefinir senha">
          <KeyRound className="h-4 w-4" />
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Redefinir senha</DialogTitle>
          <DialogDescription>
            Defina uma senha nova para {email || "este usuário"}. As sessões abertas dele serão encerradas.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-1.5 py-2">
          <Label htmlFor={`reset-password-${uid}`}>Nova senha</Label>
          <Input id={`reset-password-${uid}`} type="password" autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} disabled={saving} />
          <p className="text-[12px] text-muted-foreground">Mínimo de 10 caracteres, com maiúscula, minúscula e número.</p>
          {error && <p role="alert" className="text-[12.5px] text-destructive">{error}</p>}
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => close(false)} disabled={saving}>Cancelar</Button>
          <Button onClick={() => void save()} disabled={saving || !password}>{saving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}Redefinir senha</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
