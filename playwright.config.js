const { defineConfig, devices } = require('@playwright/test');
const fs = require('node:fs');
const path = require('node:path');

const baseURL = 'http://127.0.0.1:8011';
const pythonCmd = process.env.QOLQE_PYTHON || (process.platform === 'win32' && fs.existsSync(path.resolve('.venv/Scripts/python.exe')) ? `"${path.resolve('.venv/Scripts/python.exe')}"` : 'python');

// Opción de reportería con o sin evidencias visuales (imágenes, trazas, videos)
const conEvidencia = process.env.CON_EVIDENCIA !== 'false';

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: 1, // El reinicio y el reloj afectan a toda la base de pruebas.
  retries: 0,
  timeout: 60000,
  outputDir: 'reportes/playwright/resultados',
  snapshotPathTemplate: '{testDir}/__snapshots__/{testFilePath}/{arg}{ext}',
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.15,
      animations: 'disabled',
    },
  },
  reporter: [
    ['list'],
    ['html', { outputFolder: 'reportes/playwright/html', open: 'never' }],
    ['junit', { outputFile: 'reportes/playwright/junit.xml' }],
    ['./tests/support/trazabilidad-reporter.js'],
  ],
  use: {
    baseURL,
    trace: conEvidencia ? 'retain-on-failure' : 'off',
    screenshot: conEvidencia ? 'only-on-failure' : 'off',
    video: conEvidencia ? 'retain-on-failure' : 'off',
  },
  projects: [
    { name: 'api', testMatch: 'api/**/*.spec.js' },
    { name: 'web', testMatch: 'e2e/**/*.spec.js', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: {
    command: `${pythonCmd} scripts/servidor_pruebas.py --port 8011`,
    url: `${baseURL}/api/salud`,
    reuseExistingServer: false,
    timeout: 120000,
  },
});
