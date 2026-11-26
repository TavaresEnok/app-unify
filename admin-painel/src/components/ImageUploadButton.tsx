import { useId, useRef, useState } from "react";
import { Loader2, Upload } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { uploadProviderAsset } from "@/shared/api/assets";
import { getErrorMessage } from "@/shared/errors";

interface Props {
  providerId: string;
  onUploaded: (url: string) => void;
  label?: string;
  disabled?: boolean;
}

/** Envia um arquivo de imagem do computador e devolve a URL pública hospedada na plataforma. */
export default function ImageUploadButton({ providerId, onUploaded, label = "Enviar imagem", disabled }: Props) {
  const inputId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);

  const onFile = async (file: File | undefined) => {
    if (!file) return;
    setBusy(true);
    try {
      const url = await uploadProviderAsset(providerId, file);
      onUploaded(url);
    } catch (error) {
      toast.error(getErrorMessage(error, "Não foi possível enviar a imagem."));
    } finally {
      setBusy(false);
      if (inputRef.current) inputRef.current.value = "";
    }
  };

  return (
    <>
      <input
        ref={inputRef}
        id={inputId}
        type="file"
        accept="image/png,image/jpeg,image/webp"
        className="hidden"
        onChange={(event) => void onFile(event.target.files?.[0])}
      />
      <Button type="button" variant="outline" disabled={disabled || busy || !providerId} onClick={() => inputRef.current?.click()}>
        {busy ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Upload className="mr-2 h-4 w-4" />}
        {busy ? "Enviando..." : label}
      </Button>
    </>
  );
}
