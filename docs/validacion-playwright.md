# Validación de la migración G1

Fecha: 30 de octubre de 2026 (America/Lima). Validación local contra servidores
exclusivos y bases temporales, sin cambios en `qolqe/`.

Herramientas: Playwright Test 1.58.2 y Schemathesis 4.32.7. El entorno local usa
Python 3.14; GitHub Actions está configurado con Python 3.12 y Node.js 22.
La ejecución remota del workflow ocurrirá al hacer push o abrir un pull request.

## API

- Recargas: **71 ejecutados, 64 aprobados y 7 fallidos**.
- Salud/autenticación: **5 ejecutados, 4 aprobados y 1 fallido**.
- CP-G1-19 y CP-G1-58: bono de S/ 30, DEF-03.
- CP-G1-22, CP-G1-23, CP-G1-33 y CP-G1-34: límite diario, DEF-04.
- CP-G1-26: reanudar supera tres activas, DEF-05.
- CP-AUTH-04: token aceptado tras logout, DEF-02.

Los fallos reproducen los requisitos incumplidos documentados en
[defectos.md](defectos.md). No se usan `skip`, `fixme`, fallos esperados ni reintentos
para ocultarlos. Se verificó que los 71 CP sean únicos y mantengan el orden y las
cinco reglas de la suite original.

## Web y resultado conjunto

Los **cinco casos E2E aprobaron**: recarga con comprobante, celular inválido,
saldo insuficiente, crear/pausar/reanudar/eliminar programada y día inválido.

Resultado conjunto de Playwright: **81 ejecutados, 73 aprobados y 8 fallidos**,
todos los fallos correspondientes a los defectos API descritos arriba.
La validación web usó el Chromium 145 distribuido con Playwright 1.58.2, extraído
en `/tmp` y seleccionado mediante una configuración local temporal que se eliminó
al terminar. Esto evitó la extracción lenta en la caché del entorno. Para las
próximas ejecuciones usa `npx playwright install chromium` según la guía; CI instala
el navegador y sus dependencias automáticamente.

## Contrato

Schemathesis seleccionó **9 operaciones de Recargas** de las 69 del contrato.
Generó **367 pruebas**, con **9 hallazgos únicos** y 16 casos omitidos por la
herramienta. Reportó 3 `ST205 Allow header mismatch` y 6
`ST202 Schema-valid request rejected`. El JUnit agrupa los resultados en 10 entradas,
6 de ellas fallidas; no hay equivalencia uno a uno entre hallazgos y entradas JUnit.

Estos hallazgos requieren revisión del contrato y las respuestas. Por ejemplo,
el contrato permite valores textuales que la validación decimal rechaza; la
aceptación de datos generados también puede depender del estado acumulado por
la prueba. No se clasifican automáticamente como nuevos defectos de negocio.
La ejecución devuelve código distinto de cero y queda visible en CI.

## Evidencias

HTML, JUnit y resultados por CP están en `reportes/playwright/`; el contrato está
en `reportes/contrato/junit.xml`. Son artefactos generados, excluidos de Git. El
workflow los publica como artefactos incluso ante fallos. La trazabilidad local
lleva `pipeline: null`; en GitHub Actions incluye la URL de la ejecución.

Se verificaron sintaxis JavaScript/Python y ausencia de errores de espacios con
`git diff --check`.
