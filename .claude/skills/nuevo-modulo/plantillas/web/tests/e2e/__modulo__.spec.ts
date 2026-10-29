import { expect, test, type Page } from '@playwright/test';

// Contra la web encendida, con el gateway, nova-seguridad y nova-__servicio__ detrás (verificar.ps1 los enciende).
// Un solo inicio de sesión para todo el archivo: el gateway permite 5 por minuto y las pruebas de sesión usan 3.
test.describe.configure({ mode: 'serial' });

// La misma página para todas las pruebas del archivo, con la sesión ya iniciada.
let page: Page;

test.beforeAll(async ({ browser }) => {
  page = await browser.newPage();
  await page.goto('/login');
  await page.getByLabel('Usuario').fill('cliente.demo');
  await page.getByLabel('Clave').fill('NovaDemo#1');
  await page.getByRole('button', { name: 'Iniciar sesión' }).click();
  await expect(page).not.toHaveURL(/\/login/);
});

test.afterAll(async () => {
  await page.close();
});

test('el listado muestra la franja con los permisos de __modulo__', async () => {
  await page.goto('/__modulo__');

  await expect(page.getByTestId('conexion')).toContainText('cliente.demo');
  // Cada permiso por separado: el token no garantiza el orden de los scopes.
  await expect(page.getByTestId('conexion')).toContainText('__servicio__.leer');
  await expect(page.getByTestId('conexion')).toContainText('__servicio__.escribir');
});

test('abre el detalle del primero del listado', async () => {
  await page.goto('/__modulo__');
  const primero = page.getByRole('table').getByRole('link').first();
  const clave = (await primero.textContent())!.trim();

  await primero.click();

  await expect(page.getByRole('heading', { name: clave })).toBeVisible();
});

test('crea uno nuevo y aparece en el listado', async () => {
  await page.goto('/__modulo__/nuevo');
  // TODO(nuevo-modulo): llenar cada campo por su etiqueta (getByLabel) y comprobar lo que calcula el servidor.
  await page.getByLabel('Nombre').fill('Ejemplo');

  await page.getByRole('button', { name: 'Guardar' }).click();

  await expect(page).not.toHaveURL(/\/nuevo$/);
  const clave = page.url().split('/').pop()!;
  await page.goto('/__modulo__');
  await expect(page.getByRole('link', { name: clave })).toBeVisible();
});

test('uno que no existe (o es de otro) dice que no lo encontramos', async () => {
  await page.goto('/__modulo__/NO-EXISTE-0');

  await expect(page.getByRole('heading', { name: /No (lo )?encontramos/ })).toBeVisible();
});
