import { useEffect, useRef, useState } from "react";
import BuildConfirmationDialog from "@/components/BuildConfirmationDialog";
import { reauthenticateWithPassword } from "@/shared/auth/session";
import { ReauthCanceledError, registerReauthPrompt } from "@/shared/auth/recentLogin";
import { useAuth } from "@/contexts/AuthContext";

/** Pede a senha quando o servidor exige login recente para uma ação sensível. */
export default function ReauthDialogHost() {
  const { user } = useAuth();
  const [open, setOpen] = useState(false);
  const pending = useRef<{ resolve: () => void; reject: (error: Error) => void } | null>(null);

  useEffect(() => {
    registerReauthPrompt(() => new Promise<void>((resolve, reject) => {
      pending.current?.reject(new ReauthCanceledError());
      pending.current = { resolve, reject };
      setOpen(true);
    }));
    return () => registerReauthPrompt(null);
  }, []);

  if (!open || !user) return null;
  return (
    <BuildConfirmationDialog
      email={user.email}
      title="Confirme sua senha"
      description="Por segurança, confirme sua senha para concluir esta ação."
      confirmLabel="Confirmar"
      onConfirm={async (password) => {
        await reauthenticateWithPassword(password);
        setOpen(false);
        pending.current?.resolve();
        pending.current = null;
      }}
      onCancel={() => {
        setOpen(false);
        pending.current?.reject(new ReauthCanceledError());
        pending.current = null;
      }}
    />
  );
}
