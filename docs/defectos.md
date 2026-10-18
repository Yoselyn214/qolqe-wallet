# Reporte de defectos

En este documento explicamos los errores encontrados al probar Qolqe con Karate.
Para el resumen del trabajo seleccionamos dos del módulo de recargas: el bono
que no se entrega al recargar S/ 30 y la aceptación de una sexta recarga diaria.
Conservamos sus identificadores DEF-03 y DEF-04 para mantener la relación con
los demás documentos. También mantenemos los hallazgos adicionales registrados.

Los resultados corresponden a ejecuciones anteriores. Esta actualización organiza
la evidencia y no representa una nueva ejecución ni una corrección de la aplicación.

## Resultado de recargas que tomamos como referencia

Ejecución registrada del **17 de octubre de 2026 (hora de Lima)**, con Karate
2.0.0 y una API dedicada con base temporal:

```bash
python scripts/karate_local.py --tags @recargas
```

```text
scenarios: 71 | passed: 64 | 7 failed
```

| Defecto | Casos fallidos | Relación con el trabajo |
|---|---|---|
| DEF-03: falta el bono para S/ 30 | 2 | Defecto seleccionado: recarga manual y programada. |
| DEF-04: se acepta la sexta recarga | 4 | Defecto seleccionado: límite diario en distintas combinaciones. |
| DEF-05: reanudar supera tres activas | 1 | Hallazgo adicional de la suite ampliada. |

Los registros anteriores de 29 y 34 casos corresponden a versiones más pequeñas
de la suite. Usamos aquí el resultado ampliado para no mezclar cifras de distintas
ejecuciones. Los siete casos fallidos representan tres defectos, porque varios
casos pueden detectar el mismo problema.

## DEF-03: una recarga de S/ 30 no recibe el bono

| Campo | Detalle |
|---|---|
| Módulo / regla | Recargas / R-G1-02 |
| Severidad y prioridad | Alta / Alta |
| Entorno registrado | API 1.0.0, Karate 2.0.0, API aislada con base temporal. |
| Casos que lo detectan | «Bono desde S/ 30 con tope de S/ 4 para monto 30» y «Programada por S/ 30 aplica bono y registra origen e historial», en `api.feature`. |

### Cómo reproducirlo

1. Restaurar los datos con `POST /api/pruebas/reiniciar` en una API de pruebas.
2. Iniciar sesión como Ana con `POST /api/auth/login`, usando celular `987654321` y PIN `4826`.
3. Guardar el token y enviarlo como `Authorization: Bearer <token>`.
4. Enviar `POST /api/recargas` con este cuerpo:

```json
{"celular":"999999999","monto":30}
```

**Esperábamos:** HTTP `201` y bono `1.50`, porque el 5 % de S/ 30 es S/ 1.50.

**Observamos:** HTTP `201` y bono `0.00`. La recarga se realiza, pero no entrega
el beneficio. El mismo problema aparece al ejecutar una programada de S/ 30.

### Por qué ocurre y cómo lo detectamos

En `qolqe/reglas/recargas.py`, la función `calcular_bono` usa:

```python
if monto > MONTO_MINIMO_BONO:
```

La comparación excluye el valor exacto de S/ 30. La regla indica «desde S/ 30»,
por lo que debe incluir la igualdad (`>=`). Esta es la causa identificada al
revisar el código; la aplicación no se modificó como parte de este reporte.

El análisis de valores límite permitió detectar el problema justo donde comienza
el beneficio. Usamos S/ 20 y S/ 50 como vecinos válidos, ya que 29 y 31 no son
montos permitidos. En la ejecución ampliada fallaron dos casos por este defecto.

## DEF-04: se acepta una sexta recarga diaria al mismo número

| Campo | Detalle |
|---|---|
| Módulo / regla | Recargas / R-G1-03 |
| Severidad y prioridad | Alta / Alta |
| Entorno registrado | API 1.0.0, Karate 2.0.0, API aislada con base temporal. |
| Caso principal | «Rechazar la sexta recarga manual sin descontar saldo», en `api.feature`. |
| Variantes | Una programada más cuatro manuales; independencia entre números; programada después de cinco manuales. |

### Cómo reproducirlo

1. Restaurar los datos e iniciar sesión como Ana en una API dedicada a pruebas.
2. Enviar cinco solicitudes `POST /api/recargas` con el siguiente cuerpo y el token de Ana:

```json
{"celular":"999999999","monto":5}
```

3. Enviar una sexta solicitud idéntica el mismo día.

**Esperábamos:** HTTP `422` con código `LIMITE_RECARGAS`, sin nueva recarga ni
descuento. La quinta sí debe aceptarse.

**Observamos:** HTTP `201`; la sexta recarga se acepta y genera un descuento
adicional. En la variante de cinco manuales seguidas de una programada se
registró saldo `1470.00` en lugar de `1475.00`.

También se reproduce con una programada ejecutada y cuatro manuales previas.
Esa combinación suma cinco y es válida: el fallo ocurre al aceptar otra después.

### Por qué ocurre y cómo lo detectamos

En `qolqe/reglas/recargas.py`, la función `puede_recargar` usa:

```python
return not recargas_hoy_mismo_numero > MAX_RECARGAS_DIARIAS_MISMO_NUMERO
```

El conteo se hace antes de crear la nueva recarga. Si ya existen cinco, la
expresión `not 5 > 5` devuelve verdadero y permite una sexta. La regla requiere
permitir la operación solo si la cantidad existente es menor que cinco (`<`).

Probamos la quinta y sexta solicitud mediante valores límite. En la ejecución
ampliada, cuatro escenarios fallaron por este defecto. El caso «El límite
alcanzado por un número no bloquea otro número» se detiene al intentar rechazar
la sexta del primer número: **la comprobación final sobre el otro número no llega
a ejecutarse**. Su fallo no demuestra que se estén mezclando los cupos.

## Hallazgo adicional: DEF-05, reanudar permite superar tres activas

| Campo | Detalle |
|---|---|
| Módulo / regla | Recargas / R-G1-04 |
| Severidad y prioridad | Alta / Alta |
| Caso | «Pausar libera un cupo pero reanudar no permite superar tres activas», en `api.feature`. |

Para reproducirlo, restauramos los datos e iniciamos sesión como Ana. Partimos de
una programada activa y otra pausada. Creamos dos activas, pausamos la activa
inicial y creamos una más. Con tres activas, intentamos reanudar la pausada inicial.

**Esperábamos:** `422 LIMITE_PROGRAMADAS`, conservando tres activas.

**Observamos:** `200` con la programada reanudada en estado `ACTIVA`, superando
el máximo. Este hallazgo corresponde al séptimo caso fallido de la ejecución
ampliada y se mantiene separado de los dos defectos seleccionados para el resumen.

## Hallazgo previo de autenticación

El siguiente registro pertenece a otra ejecución y no forma parte del conteo de
71 casos de recargas.

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

## Dónde revisar la evidencia

El reporte HTML se genera en `reportes/karate/karate-summary.html`. Cada ejecución
puede actualizarlo; comprueba que corresponda a la ejecución que estás revisando.
Karate detiene cada escenario en su primera comprobación fallida, por lo que los
pasos posteriores no se consideran verificados.

La [guía de Karate](guia-karate-recargas.md) explica cómo ejecutar las pruebas y
leer el reporte. El [resumen de recargas](resumen-pruebas-recargas.md) presenta
los casos, los valores límite y los dos defectos seleccionados.
