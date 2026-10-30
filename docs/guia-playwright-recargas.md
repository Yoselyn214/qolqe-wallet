# G1 – Recargas con Playwright

La automatización activa usa Playwright Test para API y web, Page Object Model para
la interfaz y Schemathesis para contrato. No modifica la aplicación `qolqe/`.
Los archivos Karate se conservan como referencia histórica de la primera entrega;
el pipeline ejecuta las suites nuevas.

## Instalación

Se requiere Python 3.11 o superior y Node.js 22.

```bash
python -m venv .venv
source .venv/bin/activate
# PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt -r requirements-contract.txt
npm ci
npx playwright install chromium
```

## Ejecución

Con el entorno Python activado, desde la raíz:

```bash
npm test
npm run test:api
npm run test:e2e
npm run test:api -- --grep @R-G1-02
npm run test:api -- --grep CP-G1-01
npm run test:contract
npm run report
```

Playwright levanta automáticamente una API en `127.0.0.1:8011`; Schemathesis usa
`127.0.0.1:8012`. Ambos crean bases temporales y detienen su servidor al terminar.
Los puertos deben estar libres. No se reutilizan servidores existentes. Para usar
otro intérprete con Playwright, define `QOLQE_PYTHON` con su ruta.
Se ejecuta un solo worker y sin reintentos: el reloj y los reinicios son globales.
No ejecutes dos comandos Playwright simultáneamente.

## Casos y trazabilidad

`tests/api/recargas.spec.js` migra los **71 casos** de `api.feature` en su mismo
orden, con identificadores `CP-G1-01` a `CP-G1-71`. Conserva las etiquetas HU,
criterios de aceptación y `R-G1-01` a `R-G1-05`. También se migran los cinco casos de salud y autenticación a
`tests/api/autenticacion.spec.js`. Los detalles originales de cada caso
están en [casos-api-recargas.md](casos-api-recargas.md); los enlaces a Karate sirven
como fuente histórica. [trazabilidad-recargas.json](trazabilidad-recargas.json)
relaciona cada CP con su nombre y etiquetas. Las verificaciones de acceso pertenecen
transversalmente a G1.

| Regla | Cobertura |
|---|---|
| R-G1-01 | Montos permitidos, valores inválidos y celular |
| R-G1-02 | Bono, umbral y tope |
| R-G1-03 | Cinco recargas por número y día, manuales y programadas |
| R-G1-04 | Máximo de tres programadas activas, pausa y reanudación |
| R-G1-05 | Día 1–28 y duplicados |

`tests/e2e/recargas.spec.js` añade `CP-WEB-G1-01` a `05`: recarga y comprobante,
celular inválido, saldo insuficiente, ciclo de programada y día inválido.
Los selectores y acciones están en `tests/e2e/pages/`. Las pruebas ingresan desde
la pantalla de login y usan la API real, sin simular respuestas.

## Reportes y pipeline

`.github/workflows/pruebas.yml` ejecuta dos trabajos independientes ante push y pull
request. Ambos deben aprobar. No oculta errores con `continue-on-error` ni marca
los defectos del producto como éxitos esperados.

| Evidencia | Ruta |
|---|---|
| HTML Playwright | `reportes/playwright/html/index.html` |
| JUnit Playwright | `reportes/playwright/junit.xml` |
| HU → CP → resultado y enlace al pipeline | `reportes/playwright/trazabilidad.json` |
| Capturas y trazas de fallos web | `reportes/playwright/resultados/` |
| JUnit Schemathesis | `reportes/contrato/junit.xml` |

GitHub Actions conserva ambos directorios como artefactos incluso si fallan las
pruebas. El reporte de trazabilidad contiene el estado real de cada caso y la URL
de la ejecución en CI. Schemathesis obtiene el contrato del servidor, se autentica
y prueba únicamente rutas `/api/recargas`, con semilla reproducible y 20 ejemplos
por operación. Sus datos generados pueden cambiar saldos y estados dentro de su
propia base; no sustituyen las verificaciones de negocio aisladas de Playwright.

Los resultados anteriores (64 aprobados y 7 fallidos en Karate) son históricos.
La ejecución actual es la evidencia válida para Playwright. Se mantienen las
expectativas de requisitos aunque los defectos DEF-03 a DEF-05 provoquen fallos.

Referencias oficiales: [API testing](https://playwright.dev/docs/api-testing),
[servidor de pruebas](https://playwright.dev/docs/test-webserver),
[reportes](https://playwright.dev/docs/test-reporters) y
[CLI de Schemathesis](https://schemathesis.readthedocs.io/en/stable/reference/cli/).

La ejecución local validada y sus hallazgos están en
[validacion-playwright.md](validacion-playwright.md).
