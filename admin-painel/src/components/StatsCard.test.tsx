import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { Users } from 'lucide-react';
import { expect, it } from 'vitest';
import StatsCard from './StatsCard';
it('renders measured zero and unavailable without inventing freshness or trend badges', () => {
  for (const value of [0, 'N/D']) {
    const html = renderToStaticMarkup(<StatsCard title="Registros" value={value} icon={Users} description="Firestore, sem período." />);
    expect(html).toContain('>'+value+'</div>');
    expect(html).toContain('Firestore, sem período.');
    for (const invented of ['Atual', 'tempo real', '%', 'mês passado']) expect(html).not.toContain(invented);
  }
});
