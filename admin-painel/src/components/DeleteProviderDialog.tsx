import { useState } from "react";
import { Trash2 } from "lucide-react";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

/** Excluir um provedor tira o app dele do ar: exige digitar o ID para confirmar. */
export default function DeleteProviderDialog({ providerId, providerName, onConfirm }: { providerId: string; providerName?: string; onConfirm: () => void }) {
  const [typed, setTyped] = useState("");
  const matches = typed.trim() === providerId;
  return (
    <AlertDialog onOpenChange={(open) => { if (!open) setTyped(""); }}>
      <AlertDialogTrigger asChild>
        <Button variant="destructive" size="sm" aria-label={`Excluir provedor ${providerName || providerId}`} title="Excluir provedor">
          <Trash2 className="h-4 w-4" />
        </Button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Excluir {providerName || providerId}?</AlertDialogTitle>
          <AlertDialogDescription>
            O app deste provedor deixa de funcionar e os usuários do painel dele são removidos. Esta ação não pode ser desfeita.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <div className="grid gap-1.5">
          <Label htmlFor={`confirm-delete-${providerId}`}>Digite <span className="font-mono font-semibold">{providerId}</span> para confirmar</Label>
          <Input id={`confirm-delete-${providerId}`} autoComplete="off" value={typed} onChange={(event) => setTyped(event.target.value)} />
        </div>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancelar</AlertDialogCancel>
          <AlertDialogAction disabled={!matches} onClick={(event) => { if (!matches) { event.preventDefault(); return; } onConfirm(); }}>
            Excluir provedor
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
