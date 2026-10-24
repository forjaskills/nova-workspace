import { expect, test } from '@playwright/test';

// Contra la web encendida, con el gateway, nova-seguridad y nova-__SERVICIO__ detrás (verificar.ps1 los enciende).

test('inicia sesión y llega a __Servicio__ a través del gateway', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Usuario').fill('cliente.demo');
  await page.getByLabel('Clave').fill('NovaDemo#1');
  await page.getByRole('button', { name: 'Iniciar sesión' }).click();

  await expect(page).toHaveURL(/\/__SERVICIO__$/);
  await expect(page.getByTestId('conexion')).toContainText('a través del gateway como cliente.demo');
  // El token vive en una cookie httpOnly: ningún script de la página lo puede leer.
  expect(await page.evaluate(() => document.cookie)).not.toContain('nova_sesion');
});

test('con la clave equivocada avisa y no entra', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Usuario').fill('cliente.demo');
  await page.getByLabel('Clave').fill('clave-equivocada');
  await page.getByRole('button', { name: 'Iniciar sesión' }).click();

  // Dentro del formulario: Next.js agrega en cada página su propio aviso (role="alert") para anunciar rutas.
  await expect(page.locator('form').getByRole('alert')).toHaveText('Usuario o clave incorrectos.');
  await expect(page).toHaveURL(/\/login$/);
});

test('sin sesión, __Servicio__ manda al login', async ({ page }) => {
  await page.goto('/__SERVICIO__');

  await expect(page).toHaveURL(/\/login$/);
});

test('cerrar sesión borra la cookie', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Usuario').fill('cliente.demo');
  await page.getByLabel('Clave').fill('NovaDemo#1');
  await page.getByRole('button', { name: 'Iniciar sesión' }).click();
  await expect(page).toHaveURL(/\/__SERVICIO__$/);

  await page.getByRole('button', { name: 'Cerrar sesión' }).click();

  await expect(page).toHaveURL(/\/login$/);
  await page.goto('/__SERVICIO__');
  await expect(page).toHaveURL(/\/login$/);
});
