# Resumen de pruebas de recargas con Karate

## Objetivo

Verificar mediante solicitudes HTTP que las recargas manuales y programadas
cumplan las reglas del módulo G1. Los escenarios están en
[`api.feature`](../api.feature) y se automatizaron con Karate.

Antes de cada escenario se restablecen el reloj y los datos de prueba, se inicia
sesión y se comprueba el saldo inicial. Esto permite comparar las respuestas y
los efectos de cada operación sin depender del escenario anterior.

## Resumen de los casos

| Grupo de casos | Qué se comprueba |
|---|---|
| Recargas manuales | Aceptación de S/ 5, 10, 20, 30, 50 y 100; rechazo de montos y celulares inválidos. |
| Saldo y comprobante | Descuento correcto, código de operación, origen, SMS y rechazo sin descuento cuando falta saldo; aceptación con saldo exacto. |
| Bono | Ausencia de bono debajo de S/ 30, aplicación del 5 % desde S/ 30 y tope de S/ 4.00. |
| Límite diario | Máximo de cinco recargas al mismo número por usuario y día, contando manuales y programadas; otro número conserva su cupo y el límite se renueva al día siguiente. |
| Configuración e historial | Parámetros publicados por la API y últimas veinte recargas con sus campos y orden. |
| Programación | Creación, días válidos, alias, duplicados y máximo de tres programadas activas. |
| Gestión de programadas | Edición, pausa, reanudación y eliminación; rechazo de cambios inválidos y conservación del historial. |
| Proceso diario | Ejecución al vencer, bono y origen PROGRAMADA, manejo de saldo insuficiente, próxima fecha y ausencia de duplicados al procesar dos veces el mismo día. |
| Seguridad | Rechazo sin sesión y protección de las programadas frente a operaciones de otro usuario. |

## Técnica utilizada: análisis de valores límite

Se seleccionaron valores en los bordes de las reglas y a sus lados, porque una
comparación incorrecta puede aceptar un valor que debería rechazarse o excluir
uno válido. Los dos defectos descritos abajo se detectaron en esos bordes.

| Regla | Valores o situaciones probadas | Resultado esperado |
|---|---|---|
| Bono desde S/ 30 | S/ 20, 30 y 50 | Sin bono para 20; bono de 1.50 para 30 y de 2.50 para 50. Son los montos permitidos vecinos al umbral. |
| Tope del bono | S/ 100 | El 5 % sería S/ 5, pero se debe entregar solo S/ 4.00. |
| Cinco recargas diarias | Quinta y sexta solicitud al mismo número | Aceptar la quinta y rechazar la sexta. |
| Días de programación de 1 a 28 | 0, 1, 28 y 29 | Aceptar 1 y 28; rechazar 0 y 29. |
| Alias de hasta 20 caracteres | 20 y 21 caracteres | Aceptar 20 y rechazar 21. |
| Tres programadas activas | Tercera y cuarta programada | Aceptar la tercera y rechazar la cuarta. |
| Saldo disponible | Saldo exacto e insuficiente | Permitir la recarga con saldo exacto y rechazarla cuando no alcanza. |

Para el bono no se usaron S/ 29 y S/ 31: esos montos no están permitidos y serían
rechazados antes de comprobar el beneficio. Se eligieron S/ 20 y S/ 50 como
vecinos válidos de S/ 30. Los casos de seguridad, historial y transiciones de
estado complementan las pruebas; no todos corresponden a valores límite.

## Defecto 1: la recarga de S/ 30 no recibe bono (DEF-03)

**Regla:** desde S/ 30 corresponde un bono del 5 %, con tope de S/ 4.00.

**Caso:** realizar una recarga de S/ 30 con sesión válida y saldo suficiente.

| Resultado esperado | Resultado observado |
|---|---|
| HTTP `201`, monto `30.00` y bono `1.50`. | HTTP `201`, monto `30.00` y bono `0.00`. |

La operación se acepta, pero no entrega el beneficio correspondiente. El caso
también está cubierto para una recarga programada de S/ 30.

La causa identificada en `qolqe/reglas/recargas.py`, función `calcular_bono`,
es la comparación `monto > MONTO_MINIMO_BONO`: excluye el valor exacto de 30.
La regla requiere incluirlo, es decir, una comparación `>=`.

## Defecto 2: se permite una sexta recarga (DEF-04)

**Regla:** como máximo cinco recargas al mismo número por usuario y día,
sumando las manuales y las programadas ejecutadas.

**Caso:** realizar cinco recargas de S/ 5 al mismo número y solicitar una sexta
ese mismo día. Otra variante usa una programada ejecutada y cuatro manuales
antes de intentar una manual adicional.

| Resultado esperado | Resultado observado |
|---|---|
| HTTP `422`, código `LIMITE_RECARGAS`, sin descuento ni nueva recarga. | HTTP `201`: se acepta la sexta recarga. |

Una programada más cuatro manuales suma cinco y es válido. El incumplimiento
ocurre cuando la siguiente solicitud, que sería la sexta, también se acepta.

La causa identificada en `qolqe/reglas/recargas.py`, función `puede_recargar`,
es `not recargas_hoy_mismo_numero > MAX_RECARGAS_DIARIAS_MISMO_NUMERO`.
Con cinco recargas existentes devuelve verdadero y permite crear otra.
La validación debería permitir continuar solo cuando la cantidad existente
sea menor que cinco (`<`).