import { expect, test } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  // All authenticated data and mutations use local fixtures in this suite.
  await page.route('https://**', route => route.abort());
  await page.route('**/admin/performance', route => route.fulfill({ status: 204 }));
});

test('provider navigation has six areas and the overview contains measured counts', async ({ page, isMobile }) => {
  await page.goto('/provedor/dashboard');
  await expect(page.getByRole('heading', { name: 'Visão geral', exact: true, level: 2 })).toBeVisible();
  await expect(page.getByText('Clientes sincronizados', { exact: true })).toBeVisible();
  await expect(page.getByText('Instalações do app', { exact: true })).toHaveCount(0);
  await expect(page.getByText('Novas adesões', { exact: true })).toHaveCount(0);
  if (isMobile) await page.getByRole('button', { name: 'Abrir menu' }).click();
  for (const name of ['Visão geral', 'Atendimento', 'Comunicados', 'Personalização', 'Minha empresa', 'Aplicativo']) {
    await expect(page.getByRole('link', { name, exact: true })).toBeVisible();
  }
  await expect(page.getByRole('link', { name: 'Clientes', exact: true })).toHaveCount(0);
  await page.getByRole('link', { name: 'Atendimento', exact: true }).click();
  await expect(page).toHaveURL(/\/atendimento\/chamados$/);
  await expect(page.getByRole('link', { name: 'Diagnósticos', exact: true })).toBeVisible();
});

test('old links lead to the new areas and retain the painel prefix', async ({ page }) => {
  await page.goto('/painel/provedor/tickets');
  await expect(page).toHaveURL(/\/painel\/provedor\/atendimento\/chamados$/);
  await page.goto('/painel/provedor/diagnosticos');
  await expect(page).toHaveURL(/\/painel\/provedor\/atendimento\/diagnosticos$/);
  await page.goto('/painel/provedor/instabilidades');
  await expect(page).toHaveURL(/\/painel\/provedor\/comunicados\/instabilidades$/);
  await expect(page.getByText('Publicar aviso de instabilidade', { exact: true })).toBeVisible();
  await page.goto('/painel/provedor/personalizacao/notifications');
  await expect(page).toHaveURL(/\/painel\/provedor\/comunicados\/modelos$/);
  await page.goto('/painel/provedor/personalizacao/other');
  await expect(page).toHaveURL(/\/painel\/provedor\/personalizacao\/application-settings$/);
});

test('personalization keeps five groups and preserves the relocated settings', async ({ page }) => {
  await page.goto('/provedor/personalizacao/privacy');
  const areas = page.getByRole('navigation', { name: 'Áreas de personalização' });
  await expect(areas.getByRole('link')).toHaveCount(5);
  await expect(page.getByLabel('URL da política de privacidade', { exact: true })).toHaveValue('https://example.test/privacidade');
  await expect(page.getByRole('link', { name: 'Integrações', exact: true })).toHaveCount(0);
  await areas.getByRole('link', { name: 'Configurações', exact: true }).click();
  await expect(page.getByLabel('Domínio (opcional)', { exact: true })).toHaveValue('app.example.test');
  await page.getByLabel('Domínio (opcional)', { exact: true }).fill('novo.example.test');
  await page.getByRole('button', { name: 'Salvar alterações', exact: true }).click();
  await areas.getByRole('link', { name: 'Contato e informações legais' }).click();
  await page.getByRole('link', { name: 'Privacidade', exact: true }).click();
  await expect(page.getByLabel('URL da política de privacidade', { exact: true })).toHaveValue('https://example.test/privacidade');
  await areas.getByRole('link', { name: 'Configurações', exact: true }).click();
  await expect(page.getByLabel('Domínio (opcional)', { exact: true })).toHaveValue('novo.example.test');
});

test('saved templates share one sending flow and history is separate', async ({ page }) => {
  await page.goto('/provedor/comunicados/modelos');
  await page.getByRole('button', { name: 'Usar no envio' }).click();
  await expect(page).toHaveURL(/\/comunicados\/notificacoes$/);
  await expect(page.getByLabel('Título', { exact: true })).toHaveValue('Boas-vindas');
  await expect(page.getByLabel('Mensagem', { exact: true })).toHaveValue('Mensagem salva');
  await page.getByRole('button', { name: 'Enviar agora', exact: true }).click();
  await expect.poll(() => page.evaluate(() => (window as any).workspaceCalls.filter((item: any) => item.type === 'SEND_PUSH_NOTIFICATION').length)).toBe(1);
  await page.getByRole('link', { name: 'Histórico de envios', exact: true }).click();
  await expect(page.getByText('Aviso de teste', { exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Enviar agora', exact: true })).toHaveCount(0);
});

test('application offers only a verified APK and includes installation instructions', async ({ page }) => {
  await page.route('**/public_apks/*.apk', route => route.fulfill({ status: 200, headers: { 'content-type': 'application/vnd.android.package-archive' }, body: '' }));
  await page.goto('/provedor/aplicativo');
  await expect(page.getByRole('link', { name: 'Baixar APK', exact: true })).toBeVisible();
  await expect(page.getByText('Como instalar o APK', { exact: true })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Gerar aplicativo', exact: true })).toHaveCount(0);
  await page.route('**/public_apks/*.apk', route => route.fulfill({ status: 200, contentType: 'text/html', body: '<html>not an APK</html>' }));
  await page.reload();
  await expect(page.getByText('Nenhum APK disponível para download neste momento.', { exact: true })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Baixar APK', exact: true })).toHaveCount(0);
});

test('SaaS technical operations use the selected provider', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('workspaceRole', 'superAdmin'));
  await page.goto('/provedores/fixture/integrations');
  await expect(page.getByRole('navigation', { name: 'Áreas de personalização' }).getByRole('link', { name: 'Operação técnica', exact: true })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Gerar app', exact: true })).toHaveAttribute('href', '/provedores/fixture/app-build');
  await page.getByRole('button', { name: 'Comunicados', exact: true }).click();
  await expect(page).toHaveURL(/\/provedores\/fixture\/comunicados\/notificacoes$/);
});
