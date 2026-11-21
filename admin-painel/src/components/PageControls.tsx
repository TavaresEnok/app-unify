import { Button } from '@/components/ui/button';
export function PageControls({ page }: { page: { index: number; hasNext: boolean; loading: boolean; previous: () => void; next: () => void } }) {
  return <div className="flex flex-wrap items-center justify-between gap-3">
    <span className="text-xs text-muted-foreground">Página {page.index + 1} · Até 25 registros por página</span>
    <div className="flex gap-2">
      <Button variant="outline" size="sm" disabled={page.loading || page.index === 0} onClick={page.previous}>Anterior</Button>
      <Button variant="outline" size="sm" disabled={page.loading || !page.hasNext} onClick={page.next}>Próxima</Button>
    </div>
  </div>;
}
