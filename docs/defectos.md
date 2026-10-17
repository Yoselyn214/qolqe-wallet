# Reporte de defectos

## DEF-01: <título breve y descriptivo>

| Campo | Valor |
|---|---|
| Módulo / regla | |
| Severidad | Crítica / Alta / Media / Baja |
| Prioridad | Alta / Media / Baja |
| Entorno | Versión de la app, navegador, SO |
| Prueba que lo detecta | `tests/...::test_...` |

**Pasos para reproducir**
1.
2.

**Resultado esperado:**

**Resultado obtenido:**

**Evidencia:** captura, solicitud/respuesta o log

## DEF-02: El token sigue autorizando solicitudes después del logout

| Campo | Valor |
|---|---|
| Módulo / regla | Autenticación: revocación de sesión al cerrar sesión |
| Severidad | Alta |
| Prioridad | Alta |
| Entorno | API 1.0.0, Karate 2.0.0, OpenJDK 27, instancia local con base temporal y modo de prueba |
| Prueba que lo detecta | `tests/karate/autenticacion.feature`, escenario «Un token deja de funcionar después de cerrar sesión» |

**Pasos para reproducir**
1. Restaurar los datos con `POST /api/pruebas/reiniciar`.
2. Iniciar sesión con `POST /api/auth/login`, cuerpo `{"celular":"987654321","pin":"4826"}`, y guardar el `access_token` de la respuesta `200`.
3. Enviar `POST /api/auth/logout` con `Authorization: Bearer <access_token>`. Responde `204`.
4. Consultar `GET /api/cuentas/me/saldo` con el mismo token.

**Resultado esperado:** `401` con código `NO_AUTENTICADO`, según la documentación de autenticación del README y OpenAPI.

**Resultado obtenido:** `200` con el saldo de Ana, incluso después del cierre de sesión.

**Evidencia:** ejecución de Karate el 16 de octubre de 2026 (hora de Lima):

```text
POST /api/auth/logout       -> 204
GET /api/cuentas/me/saldo   -> 200
{"saldo":"1500.00","moneda":"PEN","actualizado_en":"2026-10-16T21:07:20"}
expected status: 401, actual: 200
scenarios: 5 | passed: 4 | 1 failed
```

El reporte completo se genera en `reportes/karate/karate-summary.html` al ejecutar
`bash scripts/karate.sh`. La suite devuelve un código de salida distinto de cero
mientras persista este defecto.

## DEF-03: No se aplica bono a una recarga de S/ 30

| Campo | Valor |
|---|---|
| Módulo / regla | Recargas / R-G1-02 |
| Severidad | Alta |
| Prioridad | Alta |
| Entorno | API 1.0.0, Karate 2.0.0, API aislada con base temporal |
| Prueba que lo detecta | `api.feature`: Bono desde S/ 30 con tope de S/ 4 para monto 30 |

**Pasos para reproducir:** Restaurar datos, iniciar sesión con Ana y enviar `POST /api/recargas` con `{"celular":"999999999","monto":30}`.

**Resultado esperado:** `201` con bono `1.50`.

**Resultado obtenido:** `201` con bono `0.00`.

**Evidencia:** ejecución del 17 de octubre de 2026 (Lima),
`python scripts/karate_local.py --tags @recargas`: 29 casos, 25 aprobados y 4 fallidos.
Detalle HTTP en `reportes/karate/karate-summary.html`.

## DEF-04: Se permite una sexta recarga diaria al mismo número

| Campo | Valor |
|---|---|
| Módulo / regla | Recargas / R-G1-03 |
| Severidad | Alta |
| Prioridad | Alta |
| Entorno | API 1.0.0, Karate 2.0.0, API aislada con base temporal |
| Prueba que lo detecta | `api.feature`: Rechazar la sexta recarga manual sin descontar saldo; Una recarga programada cuenta junto a cuatro manuales |

**Pasos para reproducir:** Restaurar datos e iniciar sesión con Ana. Realizar cinco recargas de S/ 5 al `999999999` y solicitar una sexta el mismo día. También se reproduce con una programada ejecutada y cuatro manuales previas.

**Resultado esperado:** La sexta responde `422 LIMITE_RECARGAS`, sin descontar saldo.

**Resultado obtenido:** La sexta responde `201`. Se reproduce tanto con recargas manuales como combinadas con una programada.

**Evidencia:** ejecución del 17 de octubre de 2026 (Lima),
`python scripts/karate_local.py --tags @recargas`: 29 casos, 25 aprobados y 4 fallidos.
Detalle HTTP en `reportes/karate/karate-summary.html`.

## DEF-05: Reanudar permite superar tres programadas activas

| Campo | Valor |
|---|---|
| Módulo / regla | Recargas / R-G1-04 |
| Severidad | Alta |
| Prioridad | Alta |
| Entorno | API 1.0.0, Karate 2.0.0, API aislada con base temporal |
| Prueba que lo detecta | `api.feature`: Pausar libera un cupo pero reanudar no permite superar tres activas |

**Pasos para reproducir:** Restaurar datos e iniciar sesión con Ana (una programada activa y una pausada). Crear dos activas, pausar la activa semilla y crear otra. Reanudar la pausada semilla.

**Resultado esperado:** `422 LIMITE_PROGRAMADAS`; se mantienen tres activas.

**Resultado obtenido:** `200` con la programada reanudada en estado `ACTIVA`, superando las tres activas.

**Evidencia:** ejecución del 17 de octubre de 2026 (Lima),
`python scripts/karate_local.py --tags @recargas`: 29 casos, 25 aprobados y 4 fallidos.
Detalle HTTP en `reportes/karate/karate-summary.html`.

## Actualización de evidencia: revisión de api.feature del 17 de octubre de 2026

La nueva versión ejecuta **34 casos: 28 aprobados y 6 fallidos**, con
`python scripts/karate_local.py --tags @recargas`.

- DEF-03: sigue devolviendo bono `0.00` para S/ 30 (se espera `1.50`).
- DEF-04: cuatro escenarios detectan el límite incorrecto: sexta manual,
  programada seguida de manuales, independencia entre números (se detiene en el
  rechazo esperado de la sexta), y programada después de cinco manuales.
  Este último devuelve saldo `1470.00` en lugar de `1475.00`, incluso tras pausar
  la programada semilla y desactivar el débito automático del servicio semilla.
- DEF-05: reanudar responde `200` en lugar de `422 LIMITE_PROGRAMADAS`.

Las comprobaciones posteriores al primer fallo de cada escenario no llegan a
ejecutarse; el caso de independencia entre números aún no valida su última
recarga debido a DEF-04.
