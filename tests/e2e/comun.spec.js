const { test, expect } = require('@playwright/test');
const { LoginPage } = require('./pages/login.page');

test.describe('Módulo Común - Autenticación, Sesión y Navegación', () => {
  test.beforeEach(async ({ request }) => {
    expect((await request.delete('/api/pruebas/reloj')).status()).toBe(200);
    expect((await request.post('/api/pruebas/reiniciar', { data: {} })).status()).toBe(200);
  });

  test('CP-WEB-COMUN-01 Iniciar sesión exitosamente con credenciales válidas @comun @autenticacion', async ({ page }) => {
    const login = new LoginPage(page);
    await login.iniciarSesionUI('987654321', '4826');
    await expect(page).toHaveURL(/\/inicio$/);
    await expect(login.saludo).toBeVisible();
    await expect(login.saldoValor).toBeVisible();
  });

  test('CP-WEB-COMUN-02 Rechazar inicio de sesión con PIN incorrecto @comun @autenticacion', async ({ page }) => {
    const login = new LoginPage(page);
    await login.iniciarSesionUI('987654321', '0000');
    await expect(login.errorAlerta).toBeVisible();
    await expect(page).toHaveURL(/\/login/);
  });

  test('CP-WEB-COMUN-03 Rechazar inicio de sesión con celular no registrado @comun @autenticacion', async ({ page }) => {
    const login = new LoginPage(page);
    await login.iniciarSesionUI('911222333', '1234');
    await expect(login.errorAlerta).toBeVisible();
    await expect(page).toHaveURL(/\/login/);
  });

  test('CP-WEB-COMUN-04 Cerrar sesión y revocar acceso @comun @autenticacion', async ({ page }) => {
    const login = new LoginPage(page);
    await login.ingresar('api');
    await page.goto('/inicio');
    await expect(login.cerrarSesionBtn).toBeVisible();
    await login.cerrarSesion();
    await expect(page).toHaveURL(/\/login\?motivo=salida/);
  });

  test('CP-WEB-COMUN-05 Proteger rutas privadas contra accesos sin autenticación @comun @seguridad', async ({ page }) => {
    await page.goto('/recargas');
    await expect(page).toHaveURL(/\/login/);
  });

  test('CP-WEB-COMUN-06 Persistencia de la sesión tras recargar el navegador @comun @sesion', async ({ page }) => {
    const login = new LoginPage(page);
    await login.ingresar('api');
    await page.goto('/inicio');
    await expect(login.saludo).toBeVisible();
    await page.reload();
    await expect(login.saludo).toBeVisible();
    await expect(page).toHaveURL(/\/inicio$/);
  });
});
