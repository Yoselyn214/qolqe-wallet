# Guion de exposición · Qolqe G1

## 1. Automatización de pruebas de Recargas

Presentar el módulo G1 de una billetera ficticia. La entrega migra la automatización activa de Karate a Playwright y conserva Schemathesis. El código de la aplicación no se modifica.

## 2. Objetivo y alcance

Explicar que la aplicación usa Python/FastAPI y datos ficticios. Las pruebas API incluyen montos, bono, saldo, límites por número y día, historial, fechas, estados y ejecución programada. Se conserva la referencia histórica de Karate.

## 3. Herramientas y arquitectura

Playwright Test 1.58.2 ejecuta API y E2E con Chromium. Page Object Model separa selectores y acciones de las aserciones web. Schemathesis 4.32.7 genera pruebas a partir de OpenAPI. Cada suite levanta su servidor y base temporal. Un worker evita interferencias con el reloj y los reinicios. Karate es el antecedente histórico de los casos API; no se ejecuta junto a Playwright.

## 4. Qué se implementó

Los 71 casos de Recargas mantienen sus CP-G1; hay cinco casos API de salud/autenticación y 17 casos web (seis comunes y once de Recargas). `features/web.feature` documenta los escenarios; los ejecutables son los `.spec.js`, ya que no hay runner Gherkin de Playwright configurado. UTF-8 se aplica a los procesos del contrato y sus logs para Windows.

## 5. Pipeline en GitHub Actions

Archivo `.github/workflows/pruebas.yml`. Hay tres trabajos: contrato, API y Web. API depende del éxito del contrato; Web se intenta aunque falle un trabajo previo, mientras no se cancele la corrida. CI usa Python 3.12 y Node.js 22. Los artefactos se conservan 30 días. CI no despliega el producto.

## 6. Resultados y hallazgos

Resultados históricos fechados 30/10/2026: Playwright registró 64/71 Recargas, 4/5 salud/autenticación y 5/5 web (la suite web luego creció a 17). Total de aquella corrida: 73 aprobados y 8 fallidos. Schemathesis generó 367 pruebas: 9 hallazgos únicos, 3 ST205 y 6 ST202. No son nueve defectos de negocio confirmados; requieren revisar contrato y comportamiento. La salida compartida de GitHub Actions también reportó nueve hallazgos. No presentar estos datos como una ejecución actual.

## 7. Costos y recursos

No se dispone de facturas, horas valorizadas, visibilidad confirmada del repositorio ni plan de GitHub. No se afirma costo total cero. Las herramientas de prueba usadas no requieren compra de licencia para este uso. GitHub ofrece ejecución gratuita con runners estándar en repositorios públicos; en privados hay cuotas según plan. El almacenamiento de artefactos y las excedencias dependen del plan y consumo. La IA depende de la suscripción o modalidad contratada. Fuentes consultadas el 30/10/2026: https://docs.github.com/en/billing/concepts/product-billing/github-actions y https://docs.github.com/en/actions/concepts/billing-and-usage .

## 8. Conclusiones y cómo ver la evidencia

Cerrar mostrando el reporte HTML y un fallo conocido. `npm test` ejecuta los specs Playwright; `npm run test:contract` ejecuta Schemathesis. La conexión `playwright-test` está declarada en `.vscode/mcp.json`; si se demuestra MCP, mostrar una sesión real de Planner/Generator y el diff revisado. No afirmar que MCP fue invocado si solo se enseña su configuración. Los fallos documentados no se ocultan con skip/fixme. Fuentes internas: `docs/revision-arquitectura-pruebas.md`, `docs/validacion-playwright.md`, `docs/defectos.md` y `.github/workflows/pruebas.yml`.

## Fuentes

- Validación: [../validacion-playwright.md](../validacion-playwright.md)
- Guía: [../guia-playwright-recargas.md](../guia-playwright-recargas.md)
- [GitHub Actions: facturación](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
- [GitHub Actions: uso](https://docs.github.com/en/actions/concepts/billing-and-usage)

Los resultados son los documentados; esta presentación no ejecuta las suites ni consulta la facturación del usuario.
