@smoke
Feature: Estado de Qolqe Wallet

  Scenario: La API está disponible
    Given url baseUrl
    And path 'api/salud'
    When method get
    Then status 200
    And match response contains { estado: 'ok', version: '#string', modo_prueba: '#boolean' }
