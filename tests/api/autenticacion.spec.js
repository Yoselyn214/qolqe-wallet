const { test, expect } = require('@playwright/test');
const { preparar } = require('../support/api');
test('CP-AUTH-01 Sesión y saldo @auth', async ({ request }) => {
  await preparar(request);
});
test('CP-AUTH-02 PIN incorrecto @auth', async ({ request }) => {
  await preparar(request);
  const res = await request.post('/api/auth/login', { data: { celular: '987654321', pin: '0000' } });
  expect(res.status()).toBe(401);
  expect(await res.json()).toMatchObject({ codigo: 'CREDENCIALES_INVALIDAS', detail: expect.any(String) });
});
test('CP-AUTH-03 Sin token @auth', async ({ request }) => {
  const res = await request.get('/api/cuentas/me/saldo');
  expect(res.status()).toBe(401);
  expect(await res.json()).toMatchObject({ codigo: 'NO_AUTENTICADO' });
});
test('CP-AUTH-04 Logout invalida token @auth', async ({ request }) => {
  const headers = await preparar(request);
  expect((await request.post('/api/auth/logout', { headers, data: {} })).status()).toBe(204);
  const res = await request.get('/api/cuentas/me/saldo', { headers });
  expect(res.status()).toBe(401);
  expect(await res.json()).toMatchObject({ codigo: 'NO_AUTENTICADO' });
});
test('CP-SALUD-01 API disponible @smoke', async ({ request }) => {
  const res = await request.get('/api/salud');
  expect(res.status()).toBe(200);
  expect(await res.json()).toMatchObject({ estado: 'ok' });
});
