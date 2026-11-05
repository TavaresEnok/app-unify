import WorkspaceTabs from "@/components/WorkspaceTabs";

export default function AttendanceLayout() {
  return <WorkspaceTabs title="Atendimento" description="Acompanhe os chamados e os diagnósticos realizados pelos assinantes." tabs={[
    { label: "Chamados", to: "/provedor/atendimento/chamados" },
    { label: "Diagnósticos", to: "/provedor/atendimento/diagnosticos" },
  ]} />;
}
