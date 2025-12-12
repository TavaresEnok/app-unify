import { useLocation, Link } from 'react-router-dom';
import { ChevronRight, Home } from 'lucide-react';

export default function Breadcrumbs() {
    const location = useLocation();
    
    const routeNames: Record<string, string> = {
        'dashboard': 'Visão Geral',
        'provedores': 'Provedores',
        'provedor': 'Painel',
        'clientes': 'Clientes',
        'tickets': 'Chamados',
        'personalizacao': 'Personalização',
        'appearance': 'Aparência',
        'menus': 'Menus',
        'integrations': 'Integrações',
        'notificacoes': 'Notificações',
        'features': 'Funcionalidades',
        'support': 'Suporte',
        'carousel': 'Carrossel',
        'social': 'Redes Sociais',
        'tips': 'Dicas',
        'faq': 'FAQ',
        'messages': 'Mensagens',
        'other': 'Outros',
        'backup': 'Backup',
        'texts': 'Textos'
    };

    const pathnames = location.pathname.split('/').filter((x) => x);

    // Não mostra breadcrumbs na dashboard principal para não poluir
    if (pathnames.length === 0 || (pathnames.length === 1 && pathnames[0] === 'dashboard')) {
        return null;
    }

    return (
        <nav className="flex items-center text-sm text-muted-foreground mb-6 overflow-x-auto whitespace-nowrap pb-1">
            <Link to="/" className="hover:text-primary transition-colors flex-shrink-0">
                <Home className="h-4 w-4" />
            </Link>
            {pathnames.map((value, index) => {
                const to = `/${pathnames.slice(0, index + 1).join('/')}`;
                const isId = value.length > 20;
                const name = isId ? 'Detalhes' : (routeNames[value] || value);
                const isLast = index === pathnames.length - 1;

                return (
                    <div key={to} className="flex items-center">
                        <ChevronRight className="h-4 w-4 mx-2 flex-shrink-0 opacity-50" />
                        {isLast ? (
                            <span className="font-medium text-foreground capitalize">{name}</span>
                        ) : (
                            <Link to={to} className="hover:text-primary transition-colors capitalize">
                                {name}
                            </Link>
                        )}
                    </div>
                );
            })}
        </nav>
    );
}
