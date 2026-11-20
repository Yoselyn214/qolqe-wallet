# Plan asistido por IA: bono antes de confirmar

## Contexto y origen

Requisito: HU-G1-01 CA4 y R-G1-02 en `docs/requisitos.md`.
Seed: CP-WEB-G1-01 y beforeEach de `tests/e2e/recargas.spec.js`.
El plan y el código fueron preparados por Codex a partir del requisito y del
código existente. Las definiciones oficiales de agentes se inicializaron para
VS Code; no se afirma que hayan ejecutado autónomamente una sesión MCP aquí.

## CP-WEB-G1-06

1. Restaurar reloj y datos; ingresar por web como Ana y abrir Recargas.
2. Seleccionar S/ 20: mostrar «Este monto no recibe bono».
3. Seleccionar S/ 30: mostrar «Bono estimado: S/ 1.50».
4. Seleccionar S/ 50: mostrar «Bono estimado: S/ 2.50».
5. Seleccionar S/ 100: mostrar «Bono estimado: S/ 4.00» (tope).
6. Volver a S/ 10: eliminar el estimado anterior y mostrar que no recibe bono.
7. En cada selección, verificar que el comprobante permanece oculto.

No pulsar Recargar: se verifica la vista previa, no el bono finalmente persistido.
El defecto conocido del bono de S/ 30 en la API no cambia la expectativa de esta
pantalla. Usar `seleccionarMonto()` y `bonoEstimado` en el Page Object.

## Validación

`npm run test:e2e -- --grep CP-WEB-G1-06`

Registrar el resultado real en `docs/ia-playwright.md`, sin marcar como aprobada
una prueba que no se haya ejecutado.
