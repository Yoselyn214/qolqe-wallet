@auth
Feature: Autenticación y acceso a la cuenta

  Background:
    * url baseUrl
    # Usar una instancia dedicada: este endpoint restaura toda la base de datos.
    Given path 'api/pruebas/reiniciar'
    And request {}
    When method post
    Then status 200

  Scenario: Iniciar sesión y consultar el saldo semilla de Ana
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    And match response contains { access_token: '#string', token_type: 'bearer', sesion_id: '#number' }
    * def token = response.access_token

    Given path 'api/cuentas/me/saldo'
    And header Authorization = 'Bearer ' + token
    When method get
    Then status 200
    And match response contains { saldo: '1500.00', moneda: 'PEN', actualizado_en: '#string' }

  Scenario: Rechazar un PIN incorrecto
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '0000' }
    When method post
    Then status 401
    And match response contains { codigo: 'CREDENCIALES_INVALIDAS', detail: '#string' }

  Scenario: Rechazar consultas sin token
    Given path 'api/cuentas/me/saldo'
    When method get
    Then status 401
    And match response contains { codigo: 'NO_AUTENTICADO', detail: '#string' }

  Scenario: Un token deja de funcionar después de cerrar sesión
    Given path 'api/auth/login'
    And request { celular: '987654321', pin: '4826' }
    When method post
    Then status 200
    * def token = response.access_token

    Given path 'api/auth/logout'
    And header Authorization = 'Bearer ' + token
    And request {}
    When method post
    Then status 204

    Given path 'api/cuentas/me/saldo'
    And header Authorization = 'Bearer ' + token
    When method get
    Then status 401
    And match response contains { codigo: 'NO_AUTENTICADO', detail: '#string' }
