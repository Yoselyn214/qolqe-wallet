# IA y agentes de Playwright en Qolqe

## Qué se configuró

Con Playwright 1.58.2 se ejecutó:

```bash
npx playwright init-agents --loop=vscode --project=web
```

Se generaron las definiciones oficiales en `.github/agents/` y la conexión
`playwright-test` en `.vscode/mcp.json`. Esta versión local no ofrece el destino
`codex` en su CLI; se eligió VS Code, que sí está disponible. No se actualizó
Playwright ni se contrataron servicios adicionales.

Se quitaron las plantillas nuevas de seed vacío y workflow de Copilot remoto:
Qolqe ya dispone de preparación real y su propio workflow. Se usa como seed
CP-WEB-G1-01 de `tests/e2e/recargas.spec.js` con su beforeEach.

## Qué se aplicó con IA en esta sesión

Codex preparó el [plan del bono estimado](../specs/bono-estimado-recargas.md),
extendió el Page Object y agregó CP-WEB-G1-06 para HU-G1-01 CA4. Comprueba la
vista previa para S/ 20, 30, 50, 100 y el retorno a S/ 10, sin enviar la recarga.

Las definiciones oficiales se configuraron, pero no se invocaron desde una sesión
MCP autónoma de Planner/Generator/Healer. El plan y el código los elaboró Codex.
No debe presentarse como una ejecución autónoma de esos tres agentes.

## Cómo usarlos en VS Code

1. Abrir el repositorio y revisar la configuración MCP de `.vscode/mcp.json`.
2. Contar con una extensión/asistente compatible con agentes y MCP; iniciar sesión
   según el proveedor. Esto puede requerir una suscripción o cuota disponible.
3. Iniciar el servidor MCP desde la interfaz de VS Code, cuando corresponda.
4. Seleccionar `playwright-test-planner` en el chat de agentes e indicar:
   «Revisa HU-G1-01 CA4. Usa CP-WEB-G1-01 como seed y el plan
   specs/bono-estimado-recargas.md. Conserva los Page Objects y las reglas del proyecto».
5. Seleccionar Generator para generar o revisar casos desde el plan.
6. Usar Healer solo para investigar errores de automatización demostrados.

La disponibilidad del selector y del modelo depende del asistente instalado;
la configuración del repositorio no instala esa extensión ni autentica al usuario.
Las definiciones deben revisarse al regenerarlas porque contienen instrucciones
específicas del proyecto añadidas a las plantillas oficiales.

## Límites de las reparaciones

No modificar `qolqe/` ni cambiar montos, códigos o expectativas para hacer pasar
un defecto de negocio. No ocultar fallos con skip/fixme. Los defectos conocidos
siguen siendo evidencia. Estas reglas se añadieron a las tres definiciones.

## Ejecución y costo

```bash
npm run test:e2e -- --grep CP-WEB-G1-06
npm run test:e2e
npm run report
```

`npm test` sigue ejecutando pruebas convencionales. GitHub Actions no llama a
modelos ni usa claves de IA. El uso del asistente puede consumir la cuota o el
saldo de su proveedor; no se ha activado facturación ni calculado un gasto real.

## Evidencia

El reporte de la ejecución web se genera en `reportes/playwright/`. Una ejecución
solo web reemplaza ese reporte con sus casos; los 81 casos de la validación
anterior se mantienen documentados como históricos. En el estado anterior a la
ampliación del módulo común había 82 casos (76 API y 6 web). El estado actual del
repositorio tiene **93 casos: 76 API y 17 web**. Consulta la
[revisión de arquitectura](revision-arquitectura-pruebas.md).

Fuente: [Playwright Test Agents](https://playwright.dev/docs/test-agents).

### Resultado de esta ampliación

Ejecución local: **6 casos web ejecutados y 6 aprobados**, incluido CP-WEB-G1-06.
Se usó el Chromium de Playwright disponible en `/tmp` con una configuración
local temporal eliminada después. No se reejecutaron los 76 casos API ni
Schemathesis para este cambio. No hubo fallo que requiriera aplicar Healer.
