const { expect } = require('@playwright/test');
class LoginPage {
  constructor(page) { this.page = page; }
  async ingresar() {
    await this.page.goto('/login');
    await this.page.getByTestId('input-celular').fill('987654321');
    await this.page.getByTestId('input-pin').fill('4826');
    await this.page.getByTestId('boton-ingresar').click();
    await expect(this.page).toHaveURL(/\/inicio$/);
  }
}
module.exports = { LoginPage };
