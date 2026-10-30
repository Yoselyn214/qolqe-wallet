const { expect } = require('@playwright/test');
async function preparar(request) {
  expect((await request.delete('/api/pruebas/reloj')).status()).toBe(200);
  expect((await request.post('/api/pruebas/reiniciar', { data: {} })).status()).toBe(200);
  const login = await request.post('/api/auth/login', { data: { celular: '987654321', pin: '4826' } });
  expect(login.status()).toBe(200);
  const headers = { Authorization: `Bearer ${(await login.json()).access_token}` };
  const saldo = await request.get('/api/cuentas/me/saldo', { headers });
  expect(saldo.status()).toBe(200);
  expect((await saldo.json()).saldo).toBe('1500.00');
  return headers;
}
module.exports = { preparar };
