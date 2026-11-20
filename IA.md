# Declaración de uso de IA

| Fecha | Herramienta | Tarea | Qué aceptamos | Qué corregimos o descartamos y por qué |
|---|---|---|---|---|
| 2026-11-20 | Codex; MCP local de Playwright Test 1.58.2 | Configurar y comprobar MCP de Playwright | MCP `test_list` enumeró 93 pruebas; Planner cargó el seed de CP-WEB-G1-01 y `browser_snapshot` inspeccionó Recargas y el comprobante. MCP configurado para usar Python del entorno local, Chrome instalado y sin video/traza durante la planificación. | El Python global carecía de `uvicorn` y la descarga del Chromium empaquetado quedó incompleta; se resolvió el MCP local usando `env/bin/python` y Chrome estable del sistema. El seed fue temporal y se eliminó. No se ejecutó la suite completa. |
| 2026-10-30 | Codex y configuración Playwright Test Agents | Plan y caso web HU-G1-01 CA4 | Plan Markdown, Page Object, CP-WEB-G1-06 y definiciones VS Code/MCP | No se ejecutaron autónomamente los tres agentes oficiales; se descartó la plantilla de workflow remoto y se impidió ocultar defectos con fixme/skip |


Detalles y límites de la asistencia: [IA con Playwright](docs/ia-playwright.md).
