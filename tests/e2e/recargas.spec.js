const { test, expect } = require('@playwright/test');
const { LoginPage } = require('./pages/login.page');
const { RecargasPage } = require('./pages/recargas.page');

let recargas;

test.beforeEach(async ({ page, request }) => {
  expect((await request.delete('/api/pruebas/reloj')).status()).toBe(200);
  expect((await request.post('/api/pruebas/reiniciar', { data: {} })).status()).toBe(200);
  await new LoginPage(page).ingresar();
  recargas = new RecargasPage(page);
  await recargas.abrir();
});

test('CP-WEB-G1-01 Recarga y comprobante con cálculo de bono @HU-G1-01 @R-G1-01 @R-G1-02', async () => {
  await recargas.recargar('999888777', 50);
  await expect(recargas.comprobante).toBeVisible();
  await expect(recargas.celular).toHaveText('999888777');
  await expect(recargas.monto).toContainText('50.00');
  await expect(recargas.bono).toContainText('2.50');
  await expect(recargas.saldo).toContainText('1,450.00');
  await expect(recargas.codigo).not.toBeEmpty();
  await expect(recargas.historial).toContainText('999888777');
});

test('CP-WEB-G1-02 Recarga exitosa con monto base sin bono @HU-G1-01 @R-G1-01', async () => {
  await recargas.recargar('999888777', 10);
  await expect(recargas.comprobante).toBeVisible();
  await expect(recargas.monto).toContainText('10.00');
  await expect(recargas.bono).toContainText('0.00');
  await expect(recargas.saldo).toContainText('1,490.00');
});

test('CP-WEB-G1-03 Recarga exitosa con monto máximo y tope de bono @HU-G1-01 @R-G1-01 @R-G1-02', async () => {
  await recargas.recargar('999888777', 100);
  await expect(recargas.comprobante).toBeVisible();
  await expect(recargas.monto).toContainText('100.00');
  await expect(recargas.bono).toContainText('4.00');
  await expect(recargas.saldo).toContainText('1,400.00');
});

test('CP-WEB-G1-04 Estimación dinámica de bonos en el formulario @HU-G1-01 @R-G1-02', async () => {
  await recargas.seleccionarMonto(20);
  await expect(recargas.bonoEstimado).toContainText(/no recibe bono/i);

  await recargas.seleccionarMonto(30);
  await expect(recargas.bonoEstimado).toContainText(/1.50/);

  await recargas.seleccionarMonto(50);
  await expect(recargas.bonoEstimado).toContainText(/2.50/);

  await recargas.seleccionarMonto(100);
  await expect(recargas.bonoEstimado).toContainText(/4.00/);
});

test('CP-WEB-G1-05 Celular inválido @HU-G1-01 @R-G1-01', async () => {
  await recargas.recargar('899888777', 10);
  await expect(recargas.error).toBeVisible();
  await expect(recargas.comprobante).toBeHidden();
});

test('CP-WEB-G1-06 Saldo insuficiente @HU-G1-01', async ({ request }) => {
  expect((await request.put('/api/pruebas/saldo', { data: { celular: '987654321', saldo: '4.99' } })).status()).toBe(200);
  await recargas.recargar('999888777', 5);
  await expect(recargas.error).toContainText(/saldo insuficiente/i);
  await expect(recargas.comprobante).toBeHidden();
});

test('CP-WEB-G1-07 Programar recarga mensual con datos válidos @HU-G1-03 @R-G1-04 @R-G1-05', async () => {
  await recargas.programar('999888777', 20, 15, 'Recarga Mamá');
  await expect(recargas.estado('Recarga Mamá')).toHaveText('Activa');
  await expect(recargas.programada('Recarga Mamá')).toContainText('15');
});

test('CP-WEB-G1-08 Programar, pausar, reanudar y eliminar @HU-G1-03 @HU-G1-05 @HU-G1-06 @R-G1-04 @R-G1-05', async () => {
  await recargas.programar('999888777', 10, 28, 'Prueba E2E');
  const fila = recargas.programada('Prueba E2E');
  await expect(recargas.estado('Prueba E2E')).toHaveText('Activa');
  await recargas.pausar('Prueba E2E');
  await expect(recargas.estado('Prueba E2E')).toHaveText('Pausada');
  await recargas.reanudar('Prueba E2E');
  await expect(recargas.estado('Prueba E2E')).toHaveText('Activa');
  await recargas.eliminar('Prueba E2E');
  await expect(fila).toHaveCount(0);
});

test('CP-WEB-G1-09 Día inválido @HU-G1-03 @R-G1-05', async () => {
  await recargas.programar('999888777', 10, 29, 'Día inválido');
  await expect(recargas.errorProgramada).toBeVisible();
  await expect(recargas.programada('Día inválido')).toHaveCount(0);
});

test('CP-WEB-G1-10 Regresión visual del formulario de recargas @HU-G1-01 @R-G1-01 @regresion-visual', async () => {
  await expect(recargas.formulario).toHaveScreenshot('formulario-recarga.png');
});

test('CP-WEB-G1-11 Regresión visual del comprobante de recarga @HU-G1-01 @R-G1-01 @R-G1-02 @regresion-visual', async () => {
  await recargas.recargar('999888777', 50);
  await expect(recargas.comprobante).toBeVisible();
  await expect(recargas.comprobante).toHaveScreenshot('comprobante-recarga.png', {
    mask: [recargas.codigo, recargas.fecha],
  });
});
