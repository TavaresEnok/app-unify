import { LucideIcon } from 'lucide-react';

interface EmptyStateProps {
    icon: LucideIcon;
    title: string;
    description: string;
}

export default function EmptyState({ icon: Icon, title, description }: EmptyStateProps) {
    return (
        <div className="flex flex-col items-center justify-center text-center py-16">
            <div className="mb-4 rounded-full bg-primary/10 p-4">
                <Icon className="h-10 w-10 text-primary" strokeWidth={1.5} />
            </div>
            <h3 className="text-xl font-semibold tracking-tight">{title}</h3>
            <p className="text-sm text-muted-foreground">{description}</p>
        </div>
    );
}
