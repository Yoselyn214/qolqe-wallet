const { expect } = require('@playwright/test');
class RecargasPage {
  constructor(page) {
    this.page = page;
    this.formulario = page.locator('#form-recarga');
    this.comprobante = page.getByTestId('comprobante');
    this.error = page.getByTestId('recarga-error');
    this.errorProgramada = page.getByTestId('programada-error');
    this.historial = page.getByTestId('lista-recargas');
    this.codigo = page.getByTestId('comprobante-codigo');
    this.celular = page.getByTestId('comprobante-celular');
    this.monto = page.getByTestId('comprobante-monto');
    this.bono = page.getByTestId('comprobante-bono');
    this.saldo = page.getByTestId('comprobante-saldo');
    this.fecha = page.getByTestId('comprobante-fecha');
  }
  async abrir() {
    await this.page.goto('/recargas');
    await expect(this.page.getByTestId('montos-recarga').getByRole('radio')).toHaveCount(6);
  }
  async recargar(celular, monto) {
    await this.page.getByTestId('input-celular').fill(celular);
    await this.page.getByTestId('montos-recarga').getByText(`S/ ${monto}`, { exact: true }).click();
    await this.page.getByTestId('boton-recargar').click();
  }
  async programar(celular, monto, dia, alias) {
    await this.page.getByTestId('input-programada-celular').fill(celular);
    await this.page.getByTestId('select-programada-monto').selectOption(String(monto));
    await this.page.getByTestId('input-programada-dia').fill(String(dia));
    await this.page.getByTestId('input-programada-alias').fill(alias);
    await this.page.getByTestId('boton-programar').click();
  }
  estado(alias) { return this.programada(alias).getByTestId('programada-estado'); }
  async pausar(alias) { await this.programada(alias).getByTestId('boton-pausar-programada').click(); }
  async reanudar(alias) { await this.programada(alias).getByTestId('boton-reanudar-programada').click(); }
  async eliminar(alias) {
    await this.programada(alias).getByTestId('boton-eliminar-programada').click();
    await this.page.getByRole('dialog').getByRole('button', { name: 'Eliminar', exact: true }).click();
  }
  programada(alias) { return this.page.getByTestId('programada').filter({ hasText: alias }); }
}
module.exports = { RecargasPage };
