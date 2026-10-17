@recargas
Feature: Recargas de celular - G1

  Background:
    * url baseUrl
    # Ejecutar únicamente contra una instancia dedicada a pruebas.
    Given path 'api/pruebas/reloj'
    When method delete
    Then status 200

    Given path 'api/pruebas/reiniciar'
    And request {}
    When method post
    Then status 200

    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }

    # Confirmar la sesión antes de comprobar las reglas de recargas.
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1500.00'

  @HU-G1-01
  Scenario: Recargar S/ 10 y descontar el saldo
    Given path 'api/recargas'
    And request { celular: '987111222', monto: '10' }
    When method post
    Then status 201
    And match response contains
      """
      {
        codigo_operacion: '#string',
        celular: '987111222',
        monto: '10.00',
        origen: 'MANUAL',
        saldo: '1490.00'
      }
      """

    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1490.00'

  @HU-G1-01 @R-G1-01 @HU-G1-01-CA1-VALID
  Scenario Outline: Recarga exitosa a un número válido por S/ <monto>
    Given path 'api/recargas'
    And request { celular: '<celular_destino>', monto: <monto> }
    When method post
    Then status 201
    And match response contains { celular: '<celular_destino>', origen: 'MANUAL', codigo_operacion: '#string' }
    And match response.monto == montoEsperado

    Examples:
      | celular_destino | monto | montoEsperado |
      | 999999999       | 5     | 5.00          |
      | 999999999       | 10    | 10.00         |
      | 999999999       | 20    | 20.00         |
      | 999999999       | 30    | 30.00         |
      | 999999999       | 50    | 50.00         |
      | 999999999       | 100   | 100.00        |

  @HU-G1-01 @R-G1-01 @HU-G1-01-CA1-ERROR
  Scenario Outline: Rechazar celular <celular_destino> y monto <monto>
    Given path 'api/recargas'
    * def datos = { celular: '<celular_destino>' }
    * set datos.monto = '<monto>'
    And request datos
    When method post
    Then status 422
    And match response contains { codigo: '<codigo_error>', detail: '#string' }

    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1500.00'

    Examples:
      | celular_destino | monto   | codigo_error       |
      | 899999999       | 50      | CELULAR_INVALIDO   |
      | 99999999        | 50      | CELULAR_INVALIDO   |
      | 999999999       | 0       | MONTO_NO_PERMITIDO |
      | 999999999       | 15      | MONTO_NO_PERMITIDO |
      | 999999999       | -15     | MONTO_NO_PERMITIDO |
      | 999999999       | 50.5    | MONTO_NO_PERMITIDO |
      | 999999999       | cinco   | SOLICITUD_INVALIDA |

  @HU-G1-01 @HU-G1-01-CA2
  Scenario: Validar el monto descontado de la cuenta, el bono aplicado y el SMS
    Given path 'api/recargas'
    And request { celular: '987111222', monto: 50.00 }
    When method post
    Then status 201
    And match response contains { celular: '987111222', monto: '50.00', bono: '2.50', saldo: '1450.00' }

    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1450.00'

    Given path 'api/pruebas/notificaciones'
    And param celular = '987111222'
    When method get
    Then status 200
    And match response == '#[1]'
    And match response[0].celular == '987111222'
    And match response[0].mensaje contains '50.00'
    And match response[0].mensaje contains '2.50'

  @HU-G1-01 @R-G1-02
  Scenario Outline: Bono desde S/ 30 con tope de S/ 4 para monto <monto>
    Given path 'api/recargas'
    And request { celular: '999999999', monto: <monto> }
    When method post
    Then status 201
    And match response.bono == '<bono>'

    Examples:
      | monto | bono |
      | 5     | 0.00 |
      | 10    | 0.00 |
      | 20    | 0.00 |
      | 30    | 1.50 |
      | 50    | 2.50 |
      | 100   | 4.00 |

  @HU-G1-01 @R-G1-03
  Scenario: Rechazar la sexta recarga manual sin descontar saldo
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 422
    And match response.codigo == 'LIMITE_RECARGAS'
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1475.00'

  @HU-G1-01 @R-G1-03
  Scenario: Una recarga programada cuenta junto a cuatro manuales
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 5, dia: 15 }
    When method post
    Then status 201
    * def fecha = response.proxima_ejecucion
    Given path 'api/pruebas/reloj'
    And request { ahora: '#(fecha + "T10:00:00")' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas'
    When method get
    Then status 200
    And match response contains deep { celular: '999999999', origen: 'PROGRAMADA', monto: '5.00' }
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 422
    And match response.codigo == 'LIMITE_RECARGAS'

  @HU-G1-01 @R-G1-03
  Scenario: Permitir recargar al mismo número al día siguiente
    # Se asume que el reloj de pruebas interpreta estas horas en la zona de negocio.
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-10-15T23:50:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }

    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 11 }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201

  @HU-G1-03 @R-G1-04
  Scenario: Aceptar tres activas y rechazar la cuarta sin contar las pausadas
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def activas = karate.filter(response, x => x.estado == 'ACTIVA')
    * def pausadas = karate.filter(response, x => x.estado == 'PAUSADA')
    # El reinicio debe sembrar exactamente una activa y una pausada.
    And match activas == '#[1]'
    And match pausadas == '#[1]'
    * def activaId = activas[0].id
    * def pausadaId = pausadas[0].id
    Given path 'api/recargas/programadas'
    And request { celular: '999999991', monto: 10, dia: 12 }
    When method post
    Then status 201
    Given path 'api/recargas/programadas'
    And request { celular: '999999992', monto: 10, dia: 12 }
    When method post
    Then status 201
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def activas = karate.filter(response, x => x.estado == 'ACTIVA')
    And match activas == '#[3]'
    Given path 'api/recargas/programadas'
    And request { celular: '999999993', monto: 10, dia: 12 }
    When method post
    Then status 422
    And match response.codigo == 'LIMITE_PROGRAMADAS'

  @HU-G1-03 @R-G1-04
  @HU-G1-05
  Scenario: Pausar libera un cupo pero reanudar no permite superar tres activas
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def activas = karate.filter(response, x => x.estado == 'ACTIVA')
    * def pausadas = karate.filter(response, x => x.estado == 'PAUSADA')
    # El reinicio debe sembrar exactamente una activa y una pausada.
    And match activas == '#[1]'
    And match pausadas == '#[1]'
    * def activaId = activas[0].id
    * def pausadaId = pausadas[0].id
    Given path 'api/recargas/programadas'
    And request { celular: '999999991', monto: 10, dia: 12 }
    When method post
    Then status 201
    Given path 'api/recargas/programadas'
    And request { celular: '999999992', monto: 10, dia: 12 }
    When method post
    Then status 201
    Given path 'api/recargas/programadas', activaId, 'pausar'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas/programadas'
    And request { celular: '999999993', monto: 10, dia: 12 }
    When method post
    Then status 201
    Given path 'api/recargas/programadas', pausadaId, 'reanudar'
    And request {}
    When method post
    Then status 422
    And match response.codigo == 'LIMITE_PROGRAMADAS'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def activasFinales = karate.filter(response, x => x.estado == 'ACTIVA')
    * def siguePausada = karate.filter(response, x => x.id == pausadaId && x.estado == 'PAUSADA')
    And match activasFinales == '#[3]'
    And match siguePausada == '#[1]'

  @HU-G1-03 @R-G1-05
  Scenario Outline: Validar el día de programación <dia>
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 10, dia: <dia> }
    When method post
    Then status <estado>
    And match response contains <esperado>

    Examples:
      | dia | estado | esperado                               |
      | 1   | 201    | { dia: 1, estado: 'ACTIVA' }           |
      | 28  | 201    | { dia: 28, estado: 'ACTIVA' }          |
      | 0   | 422    | { codigo: 'PROGRAMACION_INVALIDA' }   |
      | 29  | 422    | { codigo: 'PROGRAMACION_INVALIDA' }   |

  @HU-G1-03 @R-G1-05
  Scenario: Rechazar duplicados activos y pausados y permitir recrear tras eliminar
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 10, dia: 12 }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 10, dia: 12 }
    When method post
    Then status 409
    And match response.codigo == 'PROGRAMACION_DUPLICADA'
    Given path 'api/recargas/programadas', id, 'pausar'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 10, dia: 12 }
    When method post
    Then status 409
    And match response.codigo == 'PROGRAMACION_DUPLICADA'
    Given path 'api/recargas/programadas', id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 10, dia: 12 }
    When method post
    Then status 201

  @HU-G1-03 @R-G1-05
  Scenario: Permitir mismo celular con otro día y otro celular con el mismo día
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def activas = karate.filter(response, x => x.estado == 'ACTIVA')
    * def pausadas = karate.filter(response, x => x.estado == 'PAUSADA')
    # El reinicio debe sembrar exactamente una activa y una pausada.
    And match activas == '#[1]'
    And match pausadas == '#[1]'
    * def activaId = activas[0].id
    * def pausadaId = pausadas[0].id
    Given path 'api/recargas/programadas', activaId, 'pausar'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 10, dia: 12 }
    When method post
    Then status 201
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 10, dia: 13 }
    When method post
    Then status 201
    Given path 'api/recargas/programadas'
    And request { celular: '999999998', monto: 10, dia: 12 }
    When method post
    Then status 201

  @HU-G1-01 @R-G1-03
  Scenario: El límite alcanzado por un número no bloquea otro número
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 422
    And match response.codigo == 'LIMITE_RECARGAS'
    Given path 'api/recargas'
    And request { celular: '999999998', monto: 5 }
    When method post
    Then status 201
    And match response contains { celular: '999999998', monto: '5.00' }
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1470.00'

  @HU-G1-01 @R-G1-03
  @HU-G1-07 @HU-G1-07-CA3
  Scenario: Una programada no puede superar cinco recargas manuales del mismo día
    # El proceso diario también cobra servicios: desactivar el débito semilla.
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    # Aislar el saldo: el proceso diario también ejecutaría las programadas semilla.
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def activasSemilla = karate.filter(response, x => x.estado == 'ACTIVA')
    And match activasSemilla == '#[1]'
    Given path 'api/recargas/programadas', activasSemilla[0].id, 'pausar'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas/programadas'
    And request { celular: '999999999', monto: 5, dia: 15 }
    When method post
    Then status 201
    * def fecha = response.proxima_ejecucion
    Given path 'api/pruebas/reloj'
    And request { ahora: '#(fecha + "T10:00:00")' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/recargas'
    And request { celular: '999999999', monto: 5 }
    When method post
    Then status 201
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    * def saldoAntes = response.saldo
    Given path 'api/recargas'
    When method get
    Then status 200
    * def recargasAntes = karate.filter(response, x => x.celular == '999999999')
    And match recargasAntes == '#[5]'
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    # No se presupone el formato de errores del procesador: se verifica el efecto.
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == saldoAntes
    Given path 'api/recargas'
    When method get
    Then status 200
    * def recargasDespues = karate.filter(response, x => x.celular == '999999999')
    And match recargasDespues == '#[5]'
    * def programadas = karate.filter(recargasDespues, x => x.origen == 'PROGRAMADA')
    And match programadas == '#[0]'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def limitada = karate.filter(response, x => x.celular == '999999999')
    And match limitada == '#[1]'
    And match limitada[0] contains { ultimo_resultado: 'FALLIDA', ultimo_detalle: '#string' }
    And assert limitada[0].proxima_ejecucion > fecha
    Given path 'api/pruebas/notificaciones'
    And param celular = '987654321'
    When method get
    Then status 200
    And match response[0].mensaje contains 'máximo'


  @HU-G1-01 @HU-G1-01-CA3
  Scenario: Saldo insuficiente no registra recarga ni descuenta dinero
    Given path 'api/pruebas/saldo'
    And request { celular: '987654321', saldo: '4.99' }
    When method put
    Then status 200
    Given path 'api/recargas'
    When method get
    Then status 200
    * def antes = response
    Given path 'api/recargas'
    And request { celular: '999888777', monto: 5 }
    When method post
    Then status 422
    And match response.codigo == 'SALDO_INSUFICIENTE'
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '4.99'
    Given path 'api/recargas'
    When method get
    Then status 200
    And match response == antes

  @HU-G1-01 @HU-G1-01-CA3
  Scenario: Saldo exacto permite recargar y termina en cero
    Given path 'api/pruebas/saldo'
    And request { celular: '987654321', saldo: '5.00' }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '999888777', monto: 5 }
    When method post
    Then status 201
    And match response.saldo == '0.00'
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '0.00'

  @HU-G1-01 @configuracion
  Scenario: Configuración publica montos y parámetros del bono según requisitos
    Given path 'api/recargas/configuracion'
    When method get
    Then status 200
    And match response.montos == ['5', '10', '20', '30', '50', '100']
    And match response.bono == { monto_minimo: '30', porcentaje: '5', tope: '4.00' }
    And match response.max_recargas_diarias_mismo_numero == 5

  @HU-G1-02
  Scenario: Historial devuelve las últimas veinte recargas con campos y orden correctos
    * def creadas = []
    Given path 'api/recargas'
    And request { celular: '988000000', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000001', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000002', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000003', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000004', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000005', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000006', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000007', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000008', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000009', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000010', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000011', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000012', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000013', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000014', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000015', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000016', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000017', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000018', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000019', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    And request { celular: '988000020', monto: 5 }
    When method post
    Then status 201
    * eval creadas.push(response)
    Given path 'api/pruebas/reloj'
    And request { avanzar_minutos: 1 }
    When method put
    Then status 200
    Given path 'api/recargas'
    When method get
    Then status 200
    And match response == '#[20]'
    * def esperadas = creadas.slice(1).reverse().map(x => ({ codigo_operacion: x.codigo_operacion, celular: x.celular, monto: x.monto, bono: x.bono, origen: x.origen, fecha: x.fecha }))
    And match response == esperadas
    * def codigos = karate.map(creadas, x => x.codigo_operacion)
    And assert codigos.every((x, i) => codigos.indexOf(x) == i)

  @HU-G1-03 @HU-G1-03-CA1
  Scenario: Alias omitido es opcional
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15 }
    When method post
    Then status 201
    And match response.alias == '##null'

  @HU-G1-03 @HU-G1-03-CA1
  Scenario: Alias de veinte caracteres es válido
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: '12345678901234567890' }
    When method post
    Then status 201
    And match response.alias == '12345678901234567890'

  @HU-G1-03 @HU-G1-03-CA1
  Scenario: Alias de veintiún caracteres se rechaza
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: '123456789012345678901' }
    When method post
    Then status 422
    And match response.codigo == 'PROGRAMACION_INVALIDA'

  @HU-G1-03 @HU-G1-03-CA1
  Scenario: Celular inválido al programar
    Given path 'api/recargas/programadas'
    And request { celular: '899888777', monto: 10, dia: 15 }
    When method post
    Then status 422
    And match response.codigo == 'PROGRAMACION_INVALIDA'

  @HU-G1-03 @HU-G1-03-CA1
  Scenario: Monto no permitido al programar
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 15, dia: 15 }
    When method post
    Then status 422
    And match response.codigo == 'PROGRAMACION_INVALIDA'

  @HU-G1-03 @HU-G1-03-CA2
  Scenario: Próxima ejecución desde 2026-01-10 para día 15
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    And match response.proxima_ejecucion == '2026-01-15'
    And match response.estado == 'ACTIVA'

  @HU-G1-03 @HU-G1-03-CA2
  Scenario: Próxima ejecución desde 2026-01-15 para día 15
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-15T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    And match response.proxima_ejecucion == '2026-02-15'
    And match response.estado == 'ACTIVA'

  @HU-G1-03 @HU-G1-03-CA2
  Scenario: Próxima ejecución desde 2026-01-20 para día 15
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-20T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    And match response.proxima_ejecucion == '2026-02-15'
    And match response.estado == 'ACTIVA'

  @HU-G1-03 @HU-G1-03-CA2
  Scenario: Próxima ejecución desde 2026-12-20 para día 15
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-12-20T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    And match response.proxima_ejecucion == '2027-01-15'
    And match response.estado == 'ACTIVA'

  @HU-G1-04
  Scenario: Listado muestra campos y resultado sin ejecuciones
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada contains { celular: '999888777', alias: 'Prueba', monto: '10.00', dia: 15, estado: 'ACTIVA', proxima_ejecucion: '#string', ultimo_resultado: 'SIN_EJECUCIONES', ultimo_detalle: null, ultima_ejecucion_en: null, creada_en: '#string' }

  @HU-G1-05 @HU-G1-05-CA1
  Scenario: Editar monto alias y día recalcula fecha sin cambiar el celular
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/recargas/programadas', id
    And request { monto: 20, alias: 'Nuevo', dia: 8 }
    When method put
    Then status 200
    And match response contains { monto: '20.00', alias: 'Nuevo', dia: 8, celular: '999888777', proxima_ejecucion: '2026-02-08' }
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada.alias == 'Nuevo'

  @HU-G1-05 @HU-G1-05-CA1
  Scenario: Edición inválida no modifica la programada { monto: 15 }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    * def original = response
    Given path 'api/recargas/programadas', id
    And request { monto: 15 }
    When method put
    Then status 422
    And match response.codigo == 'PROGRAMACION_INVALIDA'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada == original

  @HU-G1-05 @HU-G1-05-CA1
  Scenario: Edición inválida no modifica la programada { dia: 29 }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    * def original = response
    Given path 'api/recargas/programadas', id
    And request { dia: 29 }
    When method put
    Then status 422
    And match response.codigo == 'PROGRAMACION_INVALIDA'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada == original

  @HU-G1-05 @HU-G1-05-CA1
  Scenario: Edición inválida no modifica la programada { alias: '123456789012345678901' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    * def original = response
    Given path 'api/recargas/programadas', id
    And request { alias: '123456789012345678901' }
    When method put
    Then status 422
    And match response.codigo == 'PROGRAMACION_INVALIDA'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada == original

  @HU-G1-05 @HU-G1-05-CA3
  Scenario: Rechazar transición inválida pausar
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/recargas/programadas', id, 'pausar'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas/programadas', id, 'pausar'
    And request {}
    When method post
    Then status 409
    And match response.codigo == 'ESTADO_INVALIDO'

  @HU-G1-05 @HU-G1-05-CA3
  Scenario: Rechazar transición inválida reanudar
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/recargas/programadas', id, 'reanudar'
    And request {}
    When method post
    Then status 409
    And match response.codigo == 'ESTADO_INVALIDO'

  @HU-G1-05 @HU-G1-05-CA2
  Scenario: Pausada no se ejecuta y reanudar recalcula desde hoy
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/recargas/programadas', id, 'pausar'
    And request {}
    When method post
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-16T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1500.00'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada.ultimo_resultado == 'SIN_EJECUCIONES'
    Given path 'api/recargas/programadas', id, 'reanudar'
    And request {}
    When method post
    Then status 200
    And match response contains { estado: 'ACTIVA', proxima_ejecucion: '2026-02-15' }

  @HU-G1-06
  Scenario: Eliminar oculta la programada e impide futuras ejecuciones conservando historial
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-15T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas'
    When method get
    Then status 200
    * def historial = karate.filter(response, x => x.celular == '999888777')
    And match historial == '#[1]'
    Given path 'api/recargas/programadas', id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    And match response == []
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-02-15T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas'
    When method get
    Then status 200
    * def restantes = karate.filter(response, x => x.celular == '999888777')
    And match restantes == historial

  @HU-G1-07 @HU-G1-07-CA1
  Scenario: No ejecutar programada antes de su fecha
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-14T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    And match response.recargas_exitosas == 0
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1500.00'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada.ultimo_resultado == 'SIN_EJECUCIONES'

  @HU-G1-07 @HU-G1-07-CA2
  Scenario: Programada por S/ 30 aplica bono y registra origen e historial
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 30, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-15T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada contains { ultimo_resultado: 'EXITOSA', proxima_ejecucion: '2026-02-15', ultimo_detalle: null, ultima_ejecucion_en: '#string' }
    Given path 'api/recargas'
    When method get
    Then status 200
    * def propias = karate.filter(response, x => x.celular == '999888777')
    And match propias == '#[1]'
    And match propias[0] contains { monto: '30.00', bono: '1.50', origen: 'PROGRAMADA' }

  @HU-G1-07 @HU-G1-07-CA2
  Scenario: Programada por S/ 50 aplica bono y registra origen e historial
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 50, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-15T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada contains { ultimo_resultado: 'EXITOSA', proxima_ejecucion: '2026-02-15', ultimo_detalle: null, ultima_ejecucion_en: '#string' }
    Given path 'api/recargas'
    When method get
    Then status 200
    * def propias = karate.filter(response, x => x.celular == '999888777')
    And match propias == '#[1]'
    And match propias[0] contains { monto: '50.00', bono: '2.50', origen: 'PROGRAMADA' }

  @HU-G1-07 @HU-G1-07-CA2
  Scenario: Programada por S/ 100 aplica bono y registra origen e historial
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 100, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-15T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada contains { ultimo_resultado: 'EXITOSA', proxima_ejecucion: '2026-02-15', ultimo_detalle: null, ultima_ejecucion_en: '#string' }
    Given path 'api/recargas'
    When method get
    Then status 200
    * def propias = karate.filter(response, x => x.celular == '999888777')
    And match propias == '#[1]'
    And match propias[0] contains { monto: '100.00', bono: '4.00', origen: 'PROGRAMADA' }

  @HU-G1-07 @HU-G1-07-CA3 @HU-G1-07-CA4
  Scenario: Fallo por saldo insuficiente conserva saldo informa SMS y avanza fecha
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/pruebas/saldo'
    And request { celular: '987654321', saldo: '9.99' }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-15T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    And match response.recargas_fallidas == 1
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '9.99'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada contains { ultimo_resultado: 'FALLIDA', ultimo_detalle: '#string', proxima_ejecucion: '2026-02-15' }
    Given path 'api/recargas'
    When method get
    Then status 200
    * def propias = karate.filter(response, x => x.celular == '999888777')
    And match propias == []
    Given path 'api/pruebas/notificaciones'
    And param celular = '987654321'
    When method get
    Then status 200
    And match response[0].mensaje contains 'Saldo insuficiente'

  @HU-G1-07 @HU-G1-07-CA4
  Scenario: Varios meses atrasados se ejecutan una sola vez y avanzan al próximo mes
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-04-20T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    And match response.recargas_exitosas == 1
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1490.00'
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def encontrada = karate.filter(response, x => x.id == id)
    And match encontrada == '#[1]'
    * def programada = encontrada[0]
    And match programada.proxima_ejecucion == '2026-05-15'

  @HU-G1-07 @HU-G1-07-CA5
  Scenario: Procesar dos veces el mismo día no duplica recargas
    Given path 'api/recargas/programadas'
    When method get
    Then status 200
    * def semillas = response
    And match semillas == '#[2]'
    Given path 'api/recargas/programadas', semillas[0].id
    When method delete
    Then status 204
    Given path 'api/recargas/programadas', semillas[1].id
    When method delete
    Then status 204
    Given path 'api/servicios/afiliaciones'
    When method get
    Then status 200
    * def debitos = karate.filter(response, x => x.debito_automatico)
    And match debitos == '#[1]'
    Given path 'api/servicios/afiliaciones', debitos[0].id
    And request { debito_automatico: false }
    When method put
    Then status 200
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-10T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/pruebas/reloj'
    And request { ahora: '2026-01-15T10:00:00' }
    When method put
    Then status 200
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token
    * configure headers = { Authorization: '#("Bearer " + token)' }
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    Given path 'api/recargas'
    When method get
    Then status 200
    * def historial = response
    Given path 'api/pruebas/procesar-diario'
    And request {}
    When method post
    Then status 200
    And match response.recargas_exitosas == 0
    Given path 'api/recargas'
    When method get
    Then status 200
    And match response == historial
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 200
    And match response.saldo == '1490.00'

  @seguridad-recargas
  Scenario: Sin sesión no se permite get 'api/recargas'
    * configure headers = {}
    Given path 'api/recargas'
    When method get
    Then status 401
    And match response.codigo == 'NO_AUTENTICADO'

  @seguridad-recargas
  Scenario: Sin sesión no se permite post 'api/recargas'
    * configure headers = {}
    Given path 'api/recargas'
    And request { celular: '999888777', monto: 10 }
    When method post
    Then status 401
    And match response.codigo == 'NO_AUTENTICADO'

  @seguridad-recargas
  Scenario: Sin sesión no se permite get 'api/recargas/programadas'
    * configure headers = {}
    Given path 'api/recargas/programadas'
    When method get
    Then status 401
    And match response.codigo == 'NO_AUTENTICADO'

  @seguridad-recargas
  Scenario: Sin sesión no se permite post 'api/recargas/programadas'
    * configure headers = {}
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15 }
    When method post
    Then status 401
    And match response.codigo == 'NO_AUTENTICADO'

  @seguridad-recargas
  Scenario: Otro usuario no puede editar una programada de Ana
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/auth/login'
    And request { celular: '912345678', pin: '7391' }
    When method post
    Then status 200
    * def tokenBruno = response.access_token
    * configure headers = { Authorization: '#("Bearer " + tokenBruno)' }
    Given path 'api/recargas/programadas', id
    And request { monto: 20 }
    When method put
    Then status 404
    And match response.codigo == 'PROGRAMADA_NO_ENCONTRADA'

  @seguridad-recargas
  Scenario: Otro usuario no puede pausar una programada de Ana
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/auth/login'
    And request { celular: '912345678', pin: '7391' }
    When method post
    Then status 200
    * def tokenBruno = response.access_token
    * configure headers = { Authorization: '#("Bearer " + tokenBruno)' }
    Given path 'api/recargas/programadas', id, 'pausar'
    And request {}
    When method post
    Then status 404
    And match response.codigo == 'PROGRAMADA_NO_ENCONTRADA'

  @seguridad-recargas
  Scenario: Otro usuario no puede reanudar una programada de Ana
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/auth/login'
    And request { celular: '912345678', pin: '7391' }
    When method post
    Then status 200
    * def tokenBruno = response.access_token
    * configure headers = { Authorization: '#("Bearer " + tokenBruno)' }
    Given path 'api/recargas/programadas', id, 'reanudar'
    And request {}
    When method post
    Then status 404
    And match response.codigo == 'PROGRAMADA_NO_ENCONTRADA'

  @seguridad-recargas
  Scenario: Otro usuario no puede eliminar una programada de Ana
    Given path 'api/recargas/programadas'
    And request { celular: '999888777', monto: 10, dia: 15, alias: 'Prueba' }
    When method post
    Then status 201
    * def id = response.id
    Given path 'api/auth/login'
    And request { celular: '912345678', pin: '7391' }
    When method post
    Then status 200
    * def tokenBruno = response.access_token
    * configure headers = { Authorization: '#("Bearer " + tokenBruno)' }
    Given path 'api/recargas/programadas', id
    When method delete
    Then status 404
    And match response.codigo == 'PROGRAMADA_NO_ENCONTRADA'
