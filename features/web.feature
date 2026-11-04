@web
Feature: Interfaz Web - Módulo Común y Módulo de Recargas (G1)

  Como usuario de Qolqe Wallet
  Quiero acceder al sistema de forma segura y gestionar recargas de saldo
  Para mantener comunicados a mis contactos y automatizar mis recargas mensuales

  # =========================================================================
  # MÓDULO COMÚN: AUTENTICACIÓN, SESIÓN Y NAVEGACIÓN
  # =========================================================================

  @comun @autenticacion
  Scenario: CP-WEB-COMUN-01 Iniciar sesión exitosamente con credenciales válidas
    Given el usuario se encuentra en la pantalla de inicio de sesión (/login)
    When ingresa el celular "987654321" y el PIN "4826"
    And presiona el botón "Ingresar"
    Then el sistema autentica al usuario y redirige a la página principal "/inicio"
    And se visualiza el saludo del usuario y el saldo disponible

  @comun @autenticacion
  Scenario: CP-WEB-COMUN-02 Rechazar inicio de sesión con PIN incorrecto
    Given el usuario se encuentra en la pantalla de inicio de sesión (/login)
    When ingresa el celular "987654321" y un PIN incorrecto "0000"
    And presiona el botón "Ingresar"
    Then el sistema muestra una alerta de error indicando credenciales inválidas
    And el usuario permanece en la pantalla de login

  @comun @autenticacion
  Scenario: CP-WEB-COMUN-03 Rechazar inicio de sesión con celular no registrado
    Given el usuario se encuentra en la pantalla de inicio de sesión (/login)
    When ingresa un celular no registrado "911222333" y el PIN "1234"
    And presiona el botón "Ingresar"
    Then el sistema muestra un mensaje de error de acceso
    And no se inicia la sesión

  @comun @autenticacion
  Scenario: CP-WEB-COMUN-04 Cerrar sesión y revocar acceso
    Given el usuario ha iniciado sesión en Qolqe Wallet
    When hace clic en el botón "Cerrar sesión" del menú de navegación
    Then el sistema finaliza la sesión activa
    And redirige al usuario a la pantalla de login con el aviso de salida

  @comun @seguridad
  Scenario: CP-WEB-COMUN-05 Proteger rutas privadas contra accesos sin autenticación
    Given el usuario no tiene una sesión activa en el navegador
    When intenta navegar directamente a la URL protegida "/recargas"
    Then el sistema bloquea el acceso y redirige automáticamente a "/login"

  @comun @sesion
  Scenario: CP-WEB-COMUN-06 Persistencia de la sesión tras recargar el navegador
    Given el usuario ha iniciado sesión y se encuentra en "/inicio"
    When el usuario recarga la página en el navegador
    Then la sesión se mantiene activa sin solicitar nuevamente las credenciales
    And el menú de navegación y los datos del usuario continúan visibles

  # =========================================================================
  # MÓDULO G1: RECARGAS DE CELULAR
  # =========================================================================

  @recargas @HU-G1-01 @R-G1-01 @R-G1-02
  Scenario: CP-WEB-G1-01 Recarga y comprobante con cálculo de bono
    Given el usuario autenticado accede a la página de "Recargas" (/recargas)
    When ingresa el celular "999888777" y selecciona el monto de S/ 50
    And confirma la recarga
    Then se muestra el comprobante de la recarga
    And el comprobante indica el celular "999888777"
    And el comprobante indica el monto "50.00"
    And se visualiza el bono calculado de "2.50"
    And el saldo actualizado de la cuenta muestra "1,450.00"
    And se muestra un código de operación generado
    And el celular "999888777" aparece en la tabla de historial de recargas

  @recargas @HU-G1-01 @R-G1-01
  Scenario: CP-WEB-G1-02 Recarga exitosa con monto base sin bono
    Given el usuario autenticado accede al formulario de recargas
    When ingresa el celular "999888777" y selecciona el monto de S/ 10
    And confirma la recarga
    Then el comprobante muestra el monto "10.00" y un bono de "0.00"
    And el saldo se descuenta correctamente

  @recargas @HU-G1-01 @R-G1-01 @R-G1-02
  Scenario: CP-WEB-G1-03 Recarga exitosa con monto máximo y tope de bono
    Given el usuario autenticado accede al formulario de recargas
    When ingresa el celular "999888777" y selecciona el monto de S/ 100
    And confirma la recarga
    Then el comprobante muestra el monto "100.00" y el bono tope de "4.00"

  @recargas @HU-G1-01 @R-G1-02
  Scenario: CP-WEB-G1-04 Estimación dinámica de bonos en el formulario
    Given el usuario se encuentra en el formulario de recargas
    When selecciona el chip de monto S/ 20
    Then la vista previa indica que el monto no recibe bono
    When selecciona el chip de monto S/ 30
    Then la vista previa calcula un bono estimado de S/ 1.50
    When selecciona el chip de monto S/ 50
    Then la vista previa calcula un bono estimado de S/ 2.50
    When selecciona el chip de monto S/ 100
    Then la vista previa calcula el bono tope estimado de S/ 4.00

  @recargas @HU-G1-01 @R-G1-01
  Scenario: CP-WEB-G1-05 Celular inválido
    Given el usuario se encuentra en el formulario de recargas
    When ingresa un celular inválido "899888777" con monto 10
    And presiona el botón de recargar
    Then se muestra un mensaje de error indicando celular no válido
    And no se muestra ningún comprobante de recarga

  @recargas @HU-G1-01
  Scenario: CP-WEB-G1-06 Saldo insuficiente
    Given el usuario tiene un saldo disponible insuficiente de 4.99 soles
    When intenta recargar el monto de 5 soles al celular "999888777"
    Then el sistema muestra un mensaje de alerta indicando saldo insuficiente
    And no se genera comprobante de operación

  @recargas @HU-G1-03 @R-G1-04 @R-G1-05
  Scenario: CP-WEB-G1-07 Programar recarga mensual con datos válidos
    Given el usuario se encuentra en la sección de recargas programadas
    When completa el formulario con celular "999888777", monto 20, día 15 y alias "Recarga Mamá"
    Then la fila "Recarga Mamá" aparece en la tabla de programadas con estado "Activa"

  @HU-G1-03 @HU-G1-05 @HU-G1-06 @R-G1-04 @R-G1-05
  Scenario: CP-WEB-G1-08 Programar, pausar, reanudar y eliminar
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
  Scenario: CP-WEB-G1-09 Día inválido
    Given el usuario se encuentra en la sección de recargas programadas
    When intenta programar una recarga para el celular "999888777", monto 10, día no permitido 29 y alias "Día inválido"
    Then se muestra un mensaje de error para la fecha de programación
    And la recarga con alias "Día inválido" no se agrega a la tabla

  @HU-G1-01 @R-G1-01 @regresion-visual
  Scenario: CP-WEB-G1-10 Regresión visual del formulario de recargas
    Given el usuario abre el módulo de recargas
    Then el diseño visual del formulario debe coincidir con la captura de referencia

  @HU-G1-01 @R-G1-01 @regresion-visual
  Scenario: CP-WEB-G1-11 Regresión visual del comprobante de recarga
    Given el usuario realiza una recarga de S/ 50
    Then la apariencia del comprobante debe coincidir con la captura de referencia
