const { defineConfig, devices } = require('@playwright/test');
const fs = require('node:fs');
const path = require('node:path');

const baseURL = 'http://127.0.0.1:8011';
const pythonCandidates = process.platform === 'win32'
  ? [path.resolve('env/Scripts/python.exe'), path.resolve('.venv/Scripts/python.exe')]
  : [path.resolve('env/bin/python'), path.resolve('.venv/bin/python')];
const pythonExecutable = process.env.QOLQE_PYTHON || pythonCandidates.find(candidate => fs.existsSync(candidate)) || 'python';
const pythonCmd = `"${pythonExecutable.replace(/"/g, '\\"')}"`;

// Opción de reportería con o sin evidencias visuales (imágenes, trazas, videos)
const conEvidencia = process.env.CON_EVIDENCIA !== 'false';

const reporters = [
  ['list'],
  ['html', { outputFolder: 'reportes/playwright/html', open: 'never' }],
  ['junit', { outputFile: 'reportes/playwright/junit.xml' }],
  ['./tests/support/trazabilidad-reporter.js'],
];

const qaseToken = process.env.QASE_TESTOPS_API_TOKEN || process.env.QASE_API_TOKEN;
if (qaseToken && process.env.QASE_ENABLE === 'true') {
  reporters.push([
    'playwright-qase-reporter',
    {
      mode: 'testops',
      testops: {
        api: {
          token: qaseToken,
          host: process.env.QASE_TESTOPS_API_HOST || 'qase.io',
        },
        project: process.env.QASE_TESTOPS_PROJECT || 'QOLQE',
        uploadAttachments: true,
        run: {
          id: process.env.QASE_TESTOPS_RUN_ID ? Number(process.env.QASE_TESTOPS_RUN_ID) : undefined,
          title: process.env.QASE_TESTOPS_RUN_TITLE || 'Iteración CI/CD - Qolqe Wallet',
          complete: process.env.QASE_RUN_COMPLETE === 'true' || false,
        },
      },
    },
  ]);
}

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: 1, // El reinicio y el reloj afectan a toda la base de pruebas.
  retries: process.env.CI ? 2 : 0,
  timeout: 60000,
  outputDir: 'reportes/playwright/resultados',
  snapshotPathTemplate: '{testDir}/__snapshots__/{testFilePath}/{arg}{ext}',
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.15,
      animations: 'disabled',
    },
  },
  reporter: reporters,
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
