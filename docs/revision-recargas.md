# Revisión de las pruebas de recargas

Revisamos los casos de `api.feature` tomando como referencia la sección 4 de
[requisitos.md](requisitos.md). El objetivo fue comprobar que las recargas
manuales y programadas respetaran los montos, el bono y los límites establecidos,
y que sus efectos se reflejaran en el saldo y el historial.

El archivo se ejecuta directamente mediante `scripts/karate.sh`; no es necesario
copiarlo a `tests/karate/`. Para Windows también contamos con una
[guía de ejecución en PowerShell](karate-windows.md).

## Qué revisamos

| Regla | Casos incluidos |
|---|---|
| R-G1-01: montos permitidos | Los seis montos válidos; cero, negativos, montos fuera de la lista y texto. También comprobamos celulares inválidos y que un rechazo no descuente saldo. |
| R-G1-02: bono | Los montos permitidos, especialmente S/ 30, donde empieza el bono, y S/ 100, donde se aplica el tope de S/ 4. Además, revisamos el SMS y el descuento para S/ 50. |
| R-G1-03: límite diario | La quinta y sexta recarga, combinaciones de manuales y programadas, cambio de día y cupos separados para números distintos. |
| R-G1-04: programadas activas | Tres activas, intento de crear una cuarta, exclusión de las pausadas del conteo y revisión del cupo al pausar o reanudar. |
| R-G1-05: datos de programación | Días 0, 1, 28 y 29; duplicados activos y pausados; creación después de eliminar y combinaciones con otro día u otro número. |

También incluimos saldo insuficiente y exacto, las últimas veinte recargas del
historial, alias, próximas fechas, edición, pausa, reanudación y eliminación.
Para el proceso diario comprobamos cuándo corresponde ejecutar una programada,
qué ocurre si falla y que procesar dos veces el mismo día no duplique la recarga.
Las pruebas de seguridad verifican el acceso sin sesión y los intentos de un
usuario de modificar programadas de otro.

## Cómo elegimos los datos

Usamos la técnica de **análisis de valores límite** para revisar los puntos donde
cambia el comportamiento esperado. Por ejemplo, una recarga de S/ 30 ya debe
recibir bono, mientras que la sexta recarga del día debe rechazarse.

Otros ejemplos son los días 1 y 28, que se aceptan, frente a 0 y 29, que se
rechazan; y los alias de 20 caracteres frente a los de 21. Para el bono usamos
S/ 20 y S/ 50 como vecinos válidos de S/ 30, porque S/ 29 y S/ 31 no pertenecen a
la lista de montos permitidos.

Las pruebas de historial, seguridad y cambios de estado complementan esta
técnica: no todos los casos son pruebas de valores límite.

## Cómo preparamos cada caso

Antes de cada prueba restauramos los datos y el reloj, iniciamos sesión y
comprobamos el saldo inicial. Cuando adelantamos el reloj más allá de la vigencia
del token, volvemos a iniciar sesión. Así evitamos confundir un error de sesión
con un fallo en las reglas de recargas.

En los casos que comparan el saldo después del proceso diario, controlamos las
programadas de ejemplo y desactivamos el débito automático de servicios para que
sus descuentos no alteren el resultado que estamos revisando.

También revisamos las expectativas del archivo: el monto textual `cinco` debe
responder `SOLICITUD_INVALIDA`, según el contrato de la API. En las celdas
`montoEsperado` dejamos los importes sin comillas adicionales para que Karate 2
no las interprete como parte del texto.

## Los dos defectos seleccionados para el resumen

| Defecto | Qué esperábamos | Qué observamos |
|---|---|---|
| DEF-03: bono para S/ 30 | Recarga aceptada con HTTP `201` y bono `1.50`. | La recarga se acepta, pero el bono es `0.00`. Ocurre en manuales y programadas de S/ 30. |
| DEF-04: sexta recarga | Después de cinco recargas al mismo número por usuario y día, recibir `422 LIMITE_RECARGAS` sin descuento ni nuevo registro. | La sexta recarga responde `201` y se acepta, incluso al combinar manuales y programadas. |

En el primer defecto, la comparación `monto > MONTO_MINIMO_BONO` deja fuera el
valor exacto de S/ 30. La regla requiere incluirlo con `>=`.

En el segundo, la función permite continuar cuando ya existen cinco recargas.
Como el conteo se realiza antes de crear la siguiente, solo debería permitirla
si la cantidad existente es menor que cinco. Una programada y cuatro manuales
suman cinco y son válidas; el error está en aceptar una adicional.

El detalle está en [resumen-pruebas-recargas.md](resumen-pruebas-recargas.md) y
los pasos para reproducirlos, en [defectos.md](defectos.md).

## Resultado registrado y alcance

La validación ampliada registrada del 17 de octubre de 2026 tuvo **71 casos:
64 aprobados y 7 fallidos**. De los fallidos, dos corresponden a DEF-03 y cuatro a
DEF-04. El restante corresponde a DEF-05, relacionado con superar tres programadas
activas al reanudar. Aunque el resumen se centra en los dos primeros defectos,
conservamos el resultado completo de esa ejecución.

Varios casos pueden detectar el mismo defecto. Además, cuando una comprobación
falla, Karate no ejecuta los pasos restantes de ese escenario; no podemos darlos
por verificados.

La presentación del bono antes de confirmar, requerida por HU-G1-01 CA4, necesita una prueba de pantalla: por API solo comprobamos los
parámetros de configuración. El redondeo general también requiere una prueba
específica de la función, porque los montos permitidos no producen bonos con más
de dos decimales.

La matriz por historia está en [guia-karate-recargas.md](guia-karate-recargas.md).
