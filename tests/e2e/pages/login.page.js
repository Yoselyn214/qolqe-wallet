const { expect } = require('@playwright/test');

class LoginPage {
  constructor(page) { this.page = page; }

  async ingresar(modo = 'api') {
    if (modo === 'api') {
      try {
        const resp = await this.page.request.post('/api/auth/login', {
          data: { celular: '987654321', pin: '4826' },
        });
        if (resp.ok()) {
          const sesionData = await resp.json();
          await this.page.addInitScript((datos) => {
            window.sessionStorage.setItem('qolqe.sesion', JSON.stringify(datos));
          }, sesionData);
          return;
        }
      } catch {
        // En caso de falla por API, continúa con el login interactivo tradicional
      }
    }

    await this.page.goto('/login');
    await this.page.getByTestId('input-celular').fill('987654321');
    await this.page.getByTestId('input-pin').fill('4826');
    await this.page.getByTestId('boton-ingresar').click();
    await expect(this.page).toHaveURL(/\/inicio$/);
  }
}

module.exports = { LoginPage };
