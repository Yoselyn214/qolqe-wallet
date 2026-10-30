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
test('CP-WEB-G1-01 Recarga y comprobante @HU-G1-01 @R-G1-01 @R-G1-02', async () => {
  await recargas.recargar('999888777', 50);
  await expect(recargas.comprobante).toBeVisible();
  await expect(recargas.celular).toHaveText('999888777');
  await expect(recargas.monto).toContainText('50.00');
  await expect(recargas.bono).toContainText('2.50');
  await expect(recargas.saldo).toContainText('1,450.00');
  await expect(recargas.codigo).not.toBeEmpty();
  await expect(recargas.historial).toContainText('999888777');
});
test('CP-WEB-G1-02 Celular inválido @HU-G1-01 @R-G1-01', async () => {
  await recargas.recargar('899888777', 10);
  await expect(recargas.error).toBeVisible();
  await expect(recargas.comprobante).toBeHidden();
});
test('CP-WEB-G1-03 Saldo insuficiente @HU-G1-01', async ({ request }) => {
  expect((await request.put('/api/pruebas/saldo', { data: { celular: '987654321', saldo: '4.99' } })).status()).toBe(200);
  await recargas.recargar('999888777', 5);
  await expect(recargas.error).toContainText(/saldo insuficiente/i);
  await expect(recargas.comprobante).toBeHidden();
});
test('CP-WEB-G1-04 Programar, pausar, reanudar y eliminar @HU-G1-03 @HU-G1-05 @HU-G1-06 @R-G1-04 @R-G1-05', async () => {
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
test('CP-WEB-G1-05 Día inválido @HU-G1-03 @R-G1-05', async () => {
  await recargas.programar('999888777', 10, 29, 'Día inválido');
  await expect(recargas.errorProgramada).toBeVisible();
  await expect(recargas.programada('Día inválido')).toHaveCount(0);
});
