@web @recargas
Feature: Interfaz Web - Recargas de celular (G1)

  Como usuario autenticado de Qolqe Wallet
  Quiero realizar y programar recargas de saldo a números celulares desde la interfaz web
  Para mantener comunicados a mis contactos y automatizar mis recargas mensuales

  Background:
    Given el usuario inicia sesión en la aplicación web con celular "987654321" y PIN "4826"
    And accede a la página de "Recargas" (/recargas)

  @HU-G1-01 @R-G1-01 @R-G1-02
  Scenario: CP-WEB-G1-01 Recarga y comprobante
    Given el usuario se encuentra en el formulario de recargas
    When ingresa el celular "999888777" y selecciona el monto 50
    And confirma la recarga
    Then se muestra el comprobante de la recarga
    And el comprobante indica el celular "999888777"
    And el comprobante indica el monto "50.00"
    And se visualiza el bono calculado de "2.50"
    And el saldo actualizado de la cuenta muestra "1,450.00"
    And se muestra un código de operación generado
    And el celular "999888777" aparece en la tabla de historial de recargas

  @HU-G1-01 @R-G1-01
  Scenario: CP-WEB-G1-02 Celular inválido
    Given el usuario se encuentra en el formulario de recargas
    When ingresa un celular inválido "899888777" con monto 10
    And presiona el botón de recargar
    Then se muestra un mensaje de error indicando celular no válido
    And no se muestra ningún comprobante de recarga

  @HU-G1-01
  Scenario: CP-WEB-G1-03 Saldo insuficiente
    Given el usuario tiene un saldo disponible insuficiente de 4.99 soles
    When intenta recargar el monto de 5 soles al celular "999888777"
    Then el sistema muestra un mensaje de alerta indicando saldo insuficiente
    And no se genera comprobante de operación

  @HU-G1-03 @HU-G1-05 @HU-G1-06 @R-G1-04 @R-G1-05
  Scenario: CP-WEB-G1-04 Programar, pausar, reanudar y eliminar
    Given el usuario se encuentra en la sección de recargas programadas
    When programa una recarga para el celular "999888777", monto 10, día 28 y alias "Prueba E2E"
    Then la fila "Prueba E2E" aparece en la tabla con estado "Activa"
    When el usuario pausa la programada "Prueba E2E"
    Then el estado de "Prueba E2E" cambia a "Pausada"
    When el usuario reanuda la programada "Prueba E2E"
    Then el estado de "Prueba E2E" vuelve a "Activa"
    When el usuario elimina la programada "Prueba E2E"
    Then la fila "Prueba E2E" desaparece de la tabla de programadas

  @HU-G1-03 @R-G1-05
  Scenario: CP-WEB-G1-05 Día inválido
    Given el usuario se encuentra en la sección de recargas programadas
    When intenta programar una recarga para el celular "999888777", monto 10, día no permitido 29 y alias "Día inválido"
    Then se muestra un mensaje de error para la fecha de programación
    And la recarga con alias "Día inválido" no se agrega a la tabla

  @HU-G1-01 @R-G1-01
  Scenario: CP-WEB-G1-06 Regresión visual del formulario de recargas
    Given el usuario abre el módulo de recargas
    Then el diseño visual del formulario debe coincidir con la captura de referencia
