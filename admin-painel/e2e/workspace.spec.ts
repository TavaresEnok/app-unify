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
  for (const name of ['Visão geral', 'Clientes', 'Atendimento', 'Comunicados', 'Personalização', 'Minha empresa', 'Aplicativo']) {
    await expect(page.getByRole('link', { name, exact: true })).toBeVisible();
  }
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
  await expect(page.getByLabel('Link próprio da política (opcional)', { exact: true })).toHaveValue('https://example.test/privacidade');
  await expect(page.getByRole('link', { name: 'Integrações', exact: true })).toHaveCount(0);
  await areas.getByRole('link', { name: 'Configurações', exact: true }).click();
  await expect(page.getByLabel('Domínio (opcional)', { exact: true })).toHaveValue('app.example.test');
  await page.getByLabel('Domínio (opcional)', { exact: true }).fill('novo.example.test');
  await page.getByRole('button', { name: 'Salvar alterações', exact: true }).click();
  await areas.getByRole('link', { name: 'Contato e informações legais' }).click();
  await page.getByRole('link', { name: 'Privacidade', exact: true }).click();
  await expect(page.getByLabel('Link próprio da política (opcional)', { exact: true })).toHaveValue('https://example.test/privacidade');
  await areas.getByRole('link', { name: 'Configurações', exact: true }).click();
  await expect(page.getByLabel('Domínio (opcional)', { exact: true })).toHaveValue('novo.example.test');
});

test('saved templates share one sending flow and history is separate', async ({ page }) => {
  await page.goto('/provedor/comunicados/modelos');
  await page.getByRole('button', { name: 'Usar no envio' }).click();
  await expect(page).toHaveURL(/\/comunicados\/notificacoes$/);
  await expect(page.getByLabel('Título', { exact: true })).toHaveValue('Boas-vindas');
  await expect(page.getByLabel('Mensagem', { exact: true })).toHaveValue('Mensagem salva');
  // Sem filtros o envio vai para todos e pede confirmação.
  page.once('dialog', dialog => void dialog.accept());
  await page.getByRole('button', { name: 'Enviar para todos', exact: true }).click();
  await expect.poll(() => page.evaluate(() => (window as any).workspaceCalls.filter((item: any) => item.type === 'HTTP' && item.payload.path === '/admin/notifications/send').length)).toBe(1);
  await page.getByRole('link', { name: 'Histórico de envios', exact: true }).click();
  await expect(page.getByText('Aviso de teste', { exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Enviar para todos', exact: true })).toHaveCount(0);
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

test('SaaS saves a permitted logo configuration before building with the current values', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('workspaceRole', 'superAdmin'));
  const errors: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  const logoUrl = 'https://firebasestorage.googleapis.com/v0/b/fixture/o/logo.png?alt=media';
  const builds: unknown[] = [];
  await page.route('**/apk-builder/generate-apk', route => {
    builds.push(route.request().postDataJSON());
    return route.fulfill({ status: 202, json: { success: true, jobId: 'fixture-build', status: 'running' } });
  });
  await page.route('**/apk-builder/jobs/fixture-build', route => route.fulfill({ json: {
    success: true, status: 'succeeded', downloadUrl: '/public_apks/f1/fixture/app.apk', versionCode: '123', versionName: '1.0.123',
  } }));
  await page.goto('/provedores/fixture/app-build');
  await expect(page.getByLabel('Nome do Aplicativo', { exact: true })).toHaveValue('Provedor Teste');
  await expect(page.getByLabel('Nome do Aplicativo', { exact: true })).toHaveAttribute('readonly', '');
  await page.getByLabel('Logo do App (Ícone)', { exact: true }).fill(logoUrl);
  await page.getByRole('button', { name: 'Salvar Configurações', exact: true }).click();
  await expect.poll(() => page.evaluate(() => (window as any).workspaceCalls.filter((item: any) => item.type === 'UPDATE_PROVIDER_CONFIG').length)).toBe(1);
  await page.getByRole('button', { name: 'Gerar APK (Teste)', exact: true }).click();
  await expect(page.getByRole('link', { name: 'Baixar APK', exact: true })).toBeVisible();
  expect(builds).toEqual([{ providerId: 'fixture', appName: 'Provedor Teste', logoUrl, format: 'apk', splashColor: '#FFFFFF', async: true }]);
  const saved = await page.evaluate(() => (window as any).workspaceCalls.filter((item: any) => item.type === 'UPDATE_PROVIDER_CONFIG'));
  expect(saved).toHaveLength(2);
  for (const item of saved) {
    expect(item.payload.config.logoUrl).toBe(logoUrl);
    expect(item.payload.config).not.toHaveProperty('details');
  }
  expect(errors).toEqual([]);
});

test('a failed configuration save is handled and prevents APK generation', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('workspaceRole', 'superAdmin');
    localStorage.setItem('workspaceSaveFailure', 'true');
  });
  const errors: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  let builds = 0;
  await page.route('**/apk-builder/generate-apk', route => { builds++; return route.abort(); });
  await page.goto('/provedores/fixture/app-build');
  await page.getByLabel('Logo do App (Ícone)', { exact: true }).fill('https://storage.googleapis.com/fixture/logo.png');
  await page.getByRole('button', { name: 'Salvar Configurações', exact: true }).click();
  await expect(page.getByText('Erro ao salvar: Falha de teste ao salvar.', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Gerar APK (Teste)', exact: true }).click();
  await expect(page.getByText('Falha na Geração', { exact: true })).toBeVisible();
  expect(builds).toBe(0);
  expect(errors).toEqual([]);
});

for (const format of ['APK', 'AAB']) {
  test(`an old manager session confirms its password before generating ${format}`, async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem('workspaceRole', 'superAdmin');
      localStorage.setItem('workspaceBuildStale', 'true');
    });
    let builds = 0;
    await page.route('**/apk-builder/generate-apk', route => {
      builds++;
      expect(route.request().postDataJSON().format).toBe(format.toLowerCase());
      return route.fulfill({ json: { success: true, downloadUrl: '/public_apks/fixture/app.apk' } });
    });
    await page.goto('/provedores/fixture/app-build');
    const logo = 'https://storage.googleapis.com/fixture/edited-logo.png';
    await page.getByLabel('Logo do App (Ícone)', { exact: true }).fill(logo);
    await page.getByRole('button', { name: format === 'APK' ? 'Gerar APK (Teste)' : 'Gerar AAB (Play Store)', exact: true }).click();
    const dialog = page.getByRole('dialog', { name: 'Confirmar geração', exact: true });
    await expect(dialog).toBeVisible();
    await expect(dialog.getByLabel('Conta de gerente', { exact: true })).toHaveValue('admin@example.test');
    expect(builds).toBe(0);
    expect(await page.evaluate(() => (window as any).workspaceCalls)).toEqual([]);
    const password = dialog.getByLabel('Senha', { exact: true });
    await password.fill('wrong');
    await dialog.getByRole('button', { name: `Confirmar e gerar ${format}`, exact: true }).click();
    await expect(dialog.getByRole('alert')).toHaveText('Senha inválida. Confira e tente novamente.');
    expect(builds).toBe(0);
    await dialog.getByRole('button', { name: 'Mostrar senha', exact: true }).click();
    await expect(password).toHaveAttribute('type', 'text');
    await password.fill('fixture-password');
    await dialog.getByRole('button', { name: `Confirmar e gerar ${format}`, exact: true }).click();
    await expect(dialog).toHaveCount(0);
    await expect(page.getByRole('link', { name: `Baixar ${format}`, exact: true })).toBeVisible();
    await expect(page.getByLabel('Logo do App (Ícone)', { exact: true })).toHaveValue(logo);
    expect(builds).toBe(1);
    await expect(page).toHaveURL(/\/provedores\/fixture\/app-build$/);
  });
}

test('canceling confirmation preserves the form and never starts a build', async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem('workspaceRole', 'superAdmin');
    localStorage.setItem('workspaceBuildStale', 'true');
  });
  let builds = 0;
  await page.route('**/apk-builder/generate-apk', route => { builds++; return route.abort(); });
  await page.goto('/provedores/fixture/app-build');
  const logo = 'https://storage.googleapis.com/fixture/edited-logo.png';
  await page.getByLabel('Logo do App (Ícone)', { exact: true }).fill(logo);
  await page.getByRole('button', { name: 'Gerar APK (Teste)', exact: true }).click();
  const dialog = page.getByRole('dialog', { name: 'Confirmar geração', exact: true });
  await dialog.getByLabel('Senha', { exact: true }).fill('discard-this-password');
  await dialog.getByRole('button', { name: 'Cancelar', exact: true }).click();
  await expect(dialog).toHaveCount(0);
  await expect(page.getByLabel('Logo do App (Ícone)', { exact: true })).toHaveValue(logo);
  expect(builds).toBe(0);
  await page.getByRole('button', { name: 'Gerar APK (Teste)', exact: true }).click();
  await expect(dialog.getByLabel('Senha', { exact: true })).toHaveValue('');
  await expect(dialog.getByLabel('Senha', { exact: true })).toHaveAttribute('type', 'password');
});

test('a current session with denied manager access is not retried through confirmation', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('workspaceRole', 'superAdmin'));
  let builds = 0;
  await page.route('**/apk-builder/generate-apk', route => {
    builds++;
    return route.fulfill({ status: 403, json: { success: false, error: 'build-authorization-denied' } });
  });
  await page.goto('/provedores/fixture/app-build');
  await page.getByLabel('Logo do App (Ícone)', { exact: true }).fill('https://storage.googleapis.com/fixture/logo.png');
  await page.getByRole('button', { name: 'Gerar APK (Teste)', exact: true }).click();
  await expect(page.getByText('Falha na Geração', { exact: true })).toBeVisible();
  await expect(page.getByRole('dialog')).toHaveCount(0);
  expect(builds).toBe(1);
});

for (const route of ['/utilizadores', '/tickets']) {
  test(`SaaS HTTP pagination navigates forward and back on ${route}`, async ({ page }) => {
    await page.addInitScript(() => localStorage.setItem('workspaceRole', 'superAdmin'));
    await page.goto(route);
    const first = route === '/tickets' ? 'Primeiro chamado' : 'primeiro@example.test';
    const second = route === '/tickets' ? 'Segundo chamado' : 'segundo@example.test';
    await expect(page.getByText(first, { exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Anterior', exact: true })).toBeDisabled();
    await page.getByRole('button', { name: 'Próxima', exact: true }).click();
    await expect(page.getByText(second, { exact: true })).toBeVisible();
    await expect(page.getByText(first, { exact: true })).toHaveCount(0);
    await expect(page.getByRole('button', { name: 'Próxima', exact: true })).toBeDisabled();
    await page.getByRole('button', { name: 'Anterior', exact: true }).click();
    await expect(page.getByText(first, { exact: true })).toBeVisible();
  });
}

test('provider tickets paginate and show an error instead of an empty success', async ({ page }) => {
  await page.goto('/provedor/atendimento/chamados');
  await expect(page.getByText('Primeiro chamado', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Próxima', exact: true }).click();
  await expect(page.getByText('Segundo chamado', { exact: true })).toBeVisible();
  await page.evaluate(() => localStorage.setItem('workspaceReadFailure', '1'));
  await page.getByRole('button', { name: 'Atualizar', exact: true }).click();
  await expect(page.getByText('Erro: Falha ao carregar.', { exact: true })).toBeVisible();
  await expect(page.getByText('Nenhum ticket encontrado', { exact: true })).toHaveCount(0);
});
