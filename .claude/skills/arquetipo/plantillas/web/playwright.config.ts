import { defineConfig, devices } from '@playwright/test';

// Las pruebas de punta a punta usan la web ya encendida (y detrás, el gateway, seguridad y los servicios).
// verificar.ps1 enciende todo y pasa BASE_URL.
export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: 'list',
  use: {
    baseURL: process.env.BASE_URL ?? 'http://localhost:__PUERTO_DEV__',
    trace: 'retain-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
