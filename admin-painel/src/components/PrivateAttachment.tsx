import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { PrivateBlob, type PrivateResource } from '@/shared/api/privateAttachments';

export default function PrivateAttachment({ resource, attachmentId }: { resource: PrivateResource; attachmentId: string }) {
  const { user, providerId } = useAuth();
  const [loaded, setLoaded] = useState<{ key: string; url: string; mime: string }>();
  const [error, setError] = useState('');
  const pathKey = 'ticketId' in resource ? resource.ticketId : `${resource.providerId}/${resource.resultId}`;
  const key = `${user?.uid}/${providerId}/${pathKey}/${attachmentId}`;
  const [request, setRequest] = useState<{ key: string; count: number }>();
  useEffect(() => {
    setLoaded(undefined); setError('');
    if (request?.key !== key || !user) return;
    let alive = true;
    const capability = new PrivateBlob();
    void capability.load(user, resource, attachmentId).then(value => {
      if (alive) setLoaded({ key, ...value });
    }, () => { if (alive) setError('Anexo indisponível.'); });
    return () => { alive = false; capability.dispose(); };
  }, [key, user, request]);
  const value = loaded?.key === key ? loaded : undefined;
  return <div>
    <button type="button" onClick={() => { setError(''); setRequest(previous => ({ key, count: (previous?.count || 0) + 1 })); }}>Carregar anexo privado</button>
    {error && <span role="status">{error}</span>}
    {value && <>
      {value.mime.startsWith('image/') && <img src={value.url} alt="Anexo privado" className="max-h-80 max-w-full" />}
      <a href={value.url} download={value.mime === 'application/pdf' ? 'relatorio.pdf' : 'anexo'}>Baixar arquivo</a>
    </>}
  </div>;
}
