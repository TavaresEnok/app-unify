import { cn } from "@/lib/utils";

type StatusTone = "blue" | "amber" | "green" | "gray" | "red";

const toneClasses: Record<StatusTone, string> = {
  blue: "bg-[#EEF2FF] text-[#2F55D4]",
  amber: "bg-[#FFF4DE] text-[#9A5B0B]",
  green: "bg-[#E4F5EC] text-[#157347]",
  gray: "bg-[#EEF0F4] text-[#5B6472]",
  red: "bg-[#FBE9E7] text-[#B3372B]",
};

function toneForStatus(status: string): StatusTone {
  const normalized = status.toLowerCase();
  if (normalized.includes("andamento") || normalized.includes("revis") || normalized.includes("aten")) return "amber";
  if (normalized.includes("aberto")) return "blue";
  if (normalized.includes("publicado") || normalized.includes("sucesso") || normalized.includes("ativo") || normalized.includes("aprov") || normalized.includes("resolvido")) return "green";
  if (normalized.includes("falha") || normalized.includes("bloque") || normalized.includes("suspens") || normalized.includes("alta")) return "red";
  return "gray";
}

interface StatusBadgeProps {
  status: string;
  className?: string;
  tone?: StatusTone;
}

export default function StatusBadge({ status, className, tone }: StatusBadgeProps) {
  const resolvedTone = tone || toneForStatus(status);

  return (
    <span className={cn("inline-flex w-fit items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[11px] font-semibold", toneClasses[resolvedTone], className)}>
      <span className="h-1.5 w-1.5 rounded-full bg-current" />
      {status}
    </span>
  );
}
