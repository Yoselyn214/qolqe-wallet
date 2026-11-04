const { expect } = require('@playwright/test');

class LoginPage {
  constructor(page) {
    this.page = page;
    this.celularInput = page.getByTestId('input-celular');
    this.pinInput = page.getByTestId('input-pin');
    this.ingresarBtn = page.getByTestId('boton-ingresar');
    this.errorAlerta = page.getByTestId('login-error');
    this.avisoAlerta = page.getByTestId('login-aviso');
    this.cerrarSesionBtn = page.getByTestId('boton-cerrar-sesion');
    this.saludo = page.getByTestId('saludo');
    this.saldoValor = page.getByTestId('saldo-valor');
  }

  async abrir() {
    await this.page.goto('/login');
    await expect(this.celularInput).toBeVisible();
  }

  async iniciarSesionUI(celular, pin) {
    await this.abrir();
    if (celular !== null && celular !== undefined) {
      await this.celularInput.fill(celular);
    }
    if (pin !== null && pin !== undefined) {
      await this.pinInput.fill(pin);
    }
    await this.ingresarBtn.click();
  }

  async cerrarSesion() {
    await this.cerrarSesionBtn.click();
  }

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
        // En caso de contingencia por API, utiliza el flujo visual tradicional
      }
    }

    await this.page.goto('/login');
    await this.celularInput.fill('987654321');
    await this.pinInput.fill('4826');
    await this.ingresarBtn.click();
    await expect(this.page).toHaveURL(/\/inicio$/);
  }
}

module.exports = { LoginPage };
