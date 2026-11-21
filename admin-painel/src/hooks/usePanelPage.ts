import { useCallback, useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { clearPanelReads, readPanel } from '@/shared/api/panelHttp';

type Page<T> = { data: T[]; nextCursor: string | null };
export function usePanelPage<T>(path: string) {
  const { user, userRole, providerId } = useAuth();
  const scope = `${user?.uid}:${userRole}:${providerId}:${path}`;
  const [position, setPosition] = useState({ scope, cursors: [null] as Array<string | null>, index: 0 });
  const current = position.scope === scope ? position : { scope, cursors: [null], index: 0 };
  const cursor = current.cursors[current.index];
  const key = `${scope}:${cursor || ''}`;
  const [revision, setRevision] = useState(0);
  const [state, setState] = useState<{ key: string; page?: Page<T>; loading: boolean; error?: string }>({ key, loading: true });
  const reload = useCallback(() => { clearPanelReads(); setRevision(value => value + 1); }, []);
  useEffect(() => {
    let active = true;
    setState(previous => ({ key, loading: true, page: previous.key === key ? previous.page : undefined }));
    const query = new URLSearchParams({ limit: '25', ...(cursor ? { cursor } : {}) });
    void readPanel<Page<T>>(`${path}?${query}`).then(page => {
      if (!Array.isArray(page.data) || (page.nextCursor !== null && typeof page.nextCursor !== 'string')) throw Error('Resposta inválida.');
      if (active) setState({ key, loading: false, page });
    }).catch(error => { if (active) setState({ key, loading: false, error: error instanceof Error ? error.message : 'Falha ao carregar.' }); });
    return () => { active = false; };
  }, [path, key, cursor, revision]);
  const matching = state.key === key;
  const page = matching ? state.page : undefined;
  return {
    data: page?.data || [], loading: !matching || state.loading, error: matching ? state.error : undefined,
    index: current.index, hasNext: !!page?.nextCursor, reload,
    previous: () => setPosition({ ...current, index: Math.max(0, current.index - 1) }),
    next: () => { if (page?.nextCursor) setPosition({ scope, cursors: [...current.cursors.slice(0, current.index + 1), page.nextCursor], index: current.index + 1 }); },
  };
}
