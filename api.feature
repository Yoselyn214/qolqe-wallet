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

  @R-G1-01 @HU-G1-01-CA1-VALID
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

  @R-G1-01 @HU-G1-01-CA1-ERROR
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

  @HU-G1-01-CA2
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

  @R-G1-02
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

  @R-G1-03
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

  @R-G1-03
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

  @R-G1-03
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

  @R-G1-04
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

  @R-G1-04
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

  @R-G1-05
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

  @R-G1-05
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

  @R-G1-05
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

  @R-G1-03
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

  @R-G1-03
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
