const { defineConfig, devices } = require('@playwright/test');
const baseURL = 'http://127.0.0.1:8011';
module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: 1, // El reinicio y el reloj afectan a toda la base de pruebas.
  retries: 0,
  timeout: 60000,
  outputDir: 'reportes/playwright/resultados',
  reporter: [
    ['list'],
    ['html', { outputFolder: 'reportes/playwright/html', open: 'never' }],
    ['junit', { outputFile: 'reportes/playwright/junit.xml' }],
    ['./tests/support/trazabilidad-reporter.js'],
  ],
  use: { baseURL, trace: 'retain-on-failure', screenshot: 'only-on-failure' },
  projects: [
    { name: 'api', testMatch: 'api/**/*.spec.js' },
    { name: 'web', testMatch: 'e2e/**/*.spec.js', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: {
    command: `${process.env.QOLQE_PYTHON || 'python'} scripts/servidor_pruebas.py --port 8011`,
    url: `${baseURL}/api/salud`,
    reuseExistingServer: false,
    timeout: 120000,
  },
});
