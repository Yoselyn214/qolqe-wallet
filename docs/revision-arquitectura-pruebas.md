# Revisión de la arquitectura de pruebas

Este documento resume lo implementado y cómo explicarlo en la exposición. Los
conteos citados corresponden a la validación fechada el 30 de octubre de 2026;
no representan una ejecución hecha durante esta revisión.

## Herramientas y relación entre ellas

| Herramienta | Uso actual | Qué aporta |
|---|---|---|
| Karate | Referencia de la primera entrega en `tests/karate/` y `features/api.feature` | Antecedente BDD de escenarios API. No aparece en el workflow activo. |
| Playwright Test API | `tests/api/*.spec.js` | Solicitudes, aserciones funcionales, reglas de negocio, autorización y efectos de estado. |
| Playwright Test Web | `tests/e2e/*.spec.js` en Chromium | Recorridos de interfaz, resultados visibles y regresión visual. |
| Schemathesis | `scripts/contrato.py`, contra OpenAPI | Genera solicitudes para comprobar consistencia entre el contrato y las respuestas de API. |

Karate y Playwright tienen una relación de **migración y trazabilidad**, no de
ejecución conjunta: los 71 casos G1 se trasladaron conservando CP, reglas y
expectativas. Karate queda como evidencia histórica; `npm test` y el workflow
actual ejecutan Playwright y Schemathesis. No comparten steps, runner ni
resultados.

Las suites activas de Playwright suman 76 casos API (71 de Recargas y cinco de
salud/autenticación) y 17 casos web (seis comunes y once de Recargas). La
validación histórica anterior a la ampliación web tiene otros conteos; revisar la
fecha del reporte antes de usar cifras en la presentación.

## Qué significa la salida de Schemathesis

Schemathesis lee el OpenAPI servido por la aplicación, selecciona las nueve
operaciones de Recargas mediante `--include-path-regex` y genera entradas de
prueba para validar las respuestas contra los esquemas. La configuración usa un
máximo de 20 ejemplos por operación y excluye dos checks:
`allow_header_conformance` y `positive_data_acceptance`. Esto es prueba de
contrato basada en generación, no una suite completa de aceptación ni una prueba
de interfaz.

La validación guardada del 30/10/2026 reportó 367 pruebas generadas, nueve
hallazgos únicos (tres `ST205` y seis `ST202`) y 16 casos omitidos. El XML JUnit
los resume en diez entradas, seis fallidas; una entrada JUnit no equivale a un
hallazgo único. `ST205` señala discrepancias del encabezado `Allow` en respuestas
405; `ST202` indica que el esquema permite solicitudes que la API rechaza con
422. Son señales para revisar contrato y comportamiento; no se deben clasificar
automáticamente como defectos confirmados de negocio.

La ejecución devuelve código distinto de cero ante estos hallazgos. Por eso
`pruebas-api`, que depende de `contrato`, no arranca si el contrato falla. El
trabajo web tiene `if: ${{ !cancelled() }}` para entregar resultados si trabajos
previos fallan o se omiten. El orden actual prioriza el contrato, pero puede
ocultar resultados API cuando Schemathesis encuentra hallazgos. Si se necesita
diagnóstico completo en cada PR, se puede ejecutar contrato y API en paralelo y
evaluar sus gates por separado al final.

## `features/*.feature` y lo que ejecuta Playwright

`features/api.feature` es una feature de Karate. Playwright no la interpreta:
los casos migrados están en `tests/api/recargas.spec.js` y
`tests/api/autenticacion.spec.js`.

`features/web.feature` documenta en Gherkin seis escenarios comunes y once de
Recargas. En `package.json` solo está instalado `@playwright/test`; no hay runner
Gherkin ni definiciones de pasos. Los CP web se ejecutan desde
`tests/e2e/comun.spec.js` y `tests/e2e/recargas.spec.js`. El `.feature` es una
especificación legible, no un archivo ejecutado. El gate consulta el reporte JSON
y los CP; no parsea el `.feature`.

Frase precisa para la exposición: «Los escenarios web están documentados en
Gherkin y automatizados con Playwright Test en JavaScript». Si se requiere que el
`.feature` sea fuente ejecutable, habrá que añadir un adaptador BDD y vincular
cada step a Playwright para evitar dos versiones divergentes.

## Por qué Page Object Model

`LoginPage` y `RecargasPage` agrupan selectores y acciones repetidas. Los specs
conservan el flujo de negocio y sus aserciones. Esto centraliza selectores,
permite reutilizar acciones como login y recarga, y hace más legibles los CP. Es
útil para flujos comunes y de Recargas; no hace falta convertir cada aserción o
componente en una clase. API no usa POM porque no interactúa con una pantalla.

## Justificación del pipeline

`.github/workflows/pruebas.yml` separa contrato, API funcional y Web E2E. Cada
trabajo instala sus dependencias, usa una instancia temporal, tiene timeout y
publica artefactos. Contrato detecta incompatibilidades con OpenAPI; API comprueba
reglas y efectos de negocio; Web comprueba la integración visible en Chromium.
Los resultados JUnit/HTML/JSON y evidencias ayudan a investigar cada capa. CI
valida las pruebas; no despliega la aplicación.

En el orden actual, API depende del éxito del contrato. Web intenta ejecutarse si
la corrida no fue cancelada, incluso si un trabajo previo falla o se omite. Esto
conserva evidencia de interfaz, pero la dependencia en serie puede impedir
obtener feedback API cuando Schemathesis encuentra discrepancias. Paralelizar
contrato y API y evaluar gates finales independientes es una alternativa si se
prioriza diagnóstico completo sobre bloqueo temprano.

## Qué debe cubrirse fuera de Schemathesis

La generación de contrato no demuestra estas reglas ni el recorrido del usuario;
deben estar explícitas en casos Playwright API o E2E:

- Umbral inclusivo del bono de S/ 30 y tope de S/ 4.
- Saldo descontado, historial y notificación simulada después de una recarga.
- Límite diario que combina recargas manuales/programadas y depende del estado y
  el reloj de prueba.
- Crear, editar, pausar, reanudar y eliminar programadas, incluidos límites y
  transiciones inválidas.
- Autorización entre cuentas, sesión cerrada y protección de rutas.
- Formularios, mensajes, vista previa, comprobante e historial en navegador.

La suite API G1 contiene casos para reglas y estados; los casos web ejercitan una
selección de flujos visuales. No se infiere cobertura de negocio por el número de
solicitudes generadas por Schemathesis.

## Trazabilidad y herramienta de gestión de pruebas

El reporter propio registra CP, HU, reglas, etiquetas, estado, duración, error y
URL del workflow; además escribe resultados API/web y un histórico local. JUnit
es un formato práctico para importar resultados en una herramienta de gestión de
pruebas (TMS). Los CP estables sirven para enlazar cada resultado con el caso
existente.

La integración con un TMS **no está implementada**: no hay reporter, token ni
llamadas API configuradas. Para añadirla, primero escoger el TMS del equipo,
mapear cada CP a su ID externo, guardar el token como secreto de CI y publicar
runs separados para API y Web. JUnit puede servir para una importación inicial;
el JSON actual no sustituye un catálogo de casos ni un historial centralizado.

## Playwright MCP y evidencia de IA

El repo contiene `.vscode/mcp.json` con el servidor `playwright-test` y
definiciones Planner, Generator y Healer en `.github/agents/`. El MCP local
enumeró 93 pruebas con `test_list`; Planner ejecutó el seed de CP-WEB-G1-01 hasta
el estado interactivo y `browser_snapshot` confirmó formulario, bono de S/ 2.50,
comprobante e historial. Para hacerlo funcionar, Playwright detecta el Python del
entorno `env/` y la configuración MCP usa Chrome estable del sistema. La
descarga local del Chromium empaquetado quedó incompleta; no fue necesaria para
esta sesión MCP. El seed fue temporal, no integra la suite.

La capacidad de IA demostrable con artefactos del repo incluye el plan en
`specs/bono-estimado-recargas.md`, la actualización del Page Object, el caso
automatizado del bono estimado, el registro en `IA.md` y restricciones para no
modificar el producto ni ocultar fallos con `skip`/`fixme`. Para una demo con MCP,
abrir el repo en VS Code, iniciar `playwright-test`, pedir al Planner analizar un
criterio, revisar el plan, pedir al Generator derivar casos y revisar el diff.
Usar Healer solo para separar fallos de automatización de defectos reales; no
cambiar expectativas para volver verde un caso.
