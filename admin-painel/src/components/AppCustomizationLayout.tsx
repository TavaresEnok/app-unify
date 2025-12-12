import { NavLink, Outlet, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";

const tabs = [
    { name: "Aplicativo", path: "/provedor/personalizacao/aplicativo" },
    { name: "Menus", path: "/provedor/personalizacao/menus" },
    { name: "Redes Sociais", path: "/provedor/personalizacao/redes-sociais" },
    { name: "Contatos para Suporte", path: "/provedor/personalizacao/contatos" },
    { name: "Termos de Uso", path: "/provedor/personalizacao/termos" },
    { name: "Textos Personalizados", path: "/provedor/personalizacao/textos" },
];

export default function AppCustomizationLayout() {
    const location = useLocation();

    const getTabClass = (path: string) => {
        return cn(
            "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
            location.pathname.startsWith(path)
                ? "bg-primary text-primary-foreground shadow"
                : "hover:bg-accent hover:text-accent-foreground"
        );
    };

    return (
        <div className="flex flex-col gap-6">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Aplicativos</h1>
                <p className="text-muted-foreground">
                    Personalize a aparência e as funcionalidades do seu aplicativo.
                </p>
            </div>

            <div className="flex items-center space-x-2 overflow-x-auto pb-2">
                {tabs.map((tab) => (
                    <NavLink key={tab.path} to={tab.path} className={getTabClass(tab.path)}>
                        {tab.name}
                    </NavLink>
                ))}
            </div>

            <div className="w-full">
                <Outlet />
            </div>
        </div>
    );
}
