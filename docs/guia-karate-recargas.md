# Guía de Karate y pruebas de recargas

En esta guía explicamos cómo organizamos las pruebas de recargas, cómo las
ejecutamos y qué encontramos al revisar los resultados. Trabajamos con Karate
para enviar solicitudes a la API y comprobar si la aplicación responde como
indican los requisitos.

El detalle de los 71 casos está en [Casos de api.feature explicados](casos-api-recargas.md).
Para ejecutarlos en Windows, preparamos una [guía con PowerShell](karate-windows.md).

## 1. Qué estamos probando

Nuestro trabajo se centra en el módulo de recargas de Qolqe, una aplicación
hecha en Python con FastAPI. Probamos tanto las recargas que realiza el usuario
en el momento como las que deja programadas para otra fecha.

Para cada caso, Karate envía una solicitud y compara la respuesta con lo esperado
según `docs/requisitos.md`. También revisamos efectos como el saldo, el historial
y los SMS simulados. Karate necesita Java; Python nos sirve para levantar la API
que vamos a probar.

Organizamos los casos según las historias HU-G1-01 a HU-G1-07 y las reglas
R-G1-01 a R-G1-05. Además, comprobamos que se necesite una sesión y que un usuario
no pueda modificar las programadas de otro. Esta selección permite revisar los
comportamientos principales, aunque no agota todas las combinaciones posibles.

Una parte queda pendiente de revisar en pantalla: **mostrar el bono antes de
confirmar la recarga**, como pide HU-G1-01 CA4. Con `@configuracion` comprobamos
los datos que entrega la API, pero para saber si el usuario ve el bono correcto se tuvo que hacer una prueba en la interfaz.

## 2. Cómo organizamos los archivos

| Archivo | Para qué sirve |
|---|---|
| `api.feature` | Escenarios de recargas, expectativas y datos de entrada. Es el archivo que se amplía al agregar casos. |
| `tests/karate/karate-config.js` | Define `baseUrl` y tiempos de espera HTTP. |
| `tests/karate/salud.feature` | Verifica disponibilidad de la API. |
| `tests/karate/autenticacion.feature` | Prueba login, acceso protegido y logout. |
| `scripts/karate.sh` | Descarga Karate 2.0.0 si falta y ejecuta los archivos, incluyendo el `api.feature` de la raíz. |
| `scripts/karate_local.py` | Levanta uvicorn con base temporal y puerto libre; espera disponibilidad, ejecuta Karate y apaga su API al terminar. |
| `docs/requisitos.md` | Fuente del comportamiento esperado. |
| `openapi.json` | Contrato de endpoints, formatos, respuestas y errores. |
| `docs/defectos.md` | Evidencia de comportamientos que incumplen requisitos. |
| `reportes/karate/karate-summary.html` | Resumen generado de la última ejecución. |

La carpeta `qolqe/` contiene la aplicación que estamos evaluando. Si una prueba
encuentra un comportamiento que no cumple el requisito, lo registramos como
defecto; no cambiamos la aplicación ni la respuesta esperada para hacer pasar el caso.

## 3. Instalación y ejecución

Para ejecutar las pruebas en Linux necesitamos Python 3.11 o superior, Java 21
o superior, Bash y curl. Primero preparamos el entorno:

```bash
java -version
curl --version
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Si ya usas `env/`, basta con `source env/bin/activate`.

Desde la raíz del repositorio:

```bash
# Recomendado: todas las recargas con API y base temporal propias.
python scripts/karate_local.py --tags @recargas

# Todos los archivos: salud, autenticación y recargas.
python scripts/karate_local.py

# Una regla o historia con etiqueta explícita.
python scripts/karate_local.py --tags @R-G1-02
python scripts/karate_local.py --tags @HU-G1-07
python scripts/karate_local.py --tags @seguridad-recargas

# Buscar escenarios por nombre (expresión regular).
python scripts/karate_local.py --tags @recargas --name 'Saldo insuficiente'
```

Las etiquetas nos ayudan a elegir qué probar. Por ejemplo, `@R-G1-02` selecciona
los casos de esa regla. Para ejecutar todas las pruebas de recargas usamos
`@recargas`, ya que algunos casos originales solo tienen etiquetas de regla.

La primera ejecución descarga el JAR en `.tools/`. No necesitas Maven ni instalar
Karate con pip. El código de salida es distinto de cero si falla algún escenario.

Para utilizar una API que ya levantaste:

```bash
BASE_URL=http://127.0.0.1:8001 bash scripts/karate.sh --tags @recargas
```

Hay que tener en cuenta que **las pruebas reinician toda la base de esa API**.
Por eso usamos una instancia dedicada. El comando con `karate_local.py` se encarga
de crear una base temporal, iniciar la API y apagarla al terminar; no hace falta
levantar uvicorn aparte ni compartir los datos de la aplicación habitual.

## 4. Cómo leer un escenario

```gherkin
@recargas @HU-G1-01
Feature: Ejemplo explicativo

  Scenario: Recargar un celular
    Given url baseUrl
    And path 'api/recargas'
    And header Authorization = 'Bearer ' + token
    And request { celular: '999888777', monto: 10 }
    When method post
    Then status 201
    And match response.monto == '10.00'
```

Este ejemplo se lee así: enviamos una recarga de S/ 10 y esperamos que la API
responda `201` con el monto `10.00`. Para poder hacerlo necesitamos iniciar sesión;
en el archivo real, el `Background` obtiene el `token` antes de cada caso.

| Instrucción | Significado |
|---|---|
| `Feature` | Funcionalidad que agrupa escenarios. |
| `Background` | Preparación que se repite antes de cada escenario y cada fila de Examples. |
| `Scenario` | Caso concreto con su preparación, operación y comprobaciones. |
| `Scenario Outline` y `Examples` | Ejecutan el mismo caso una vez por fila. |
| `Given path` | Ruta del endpoint, agregada a `baseUrl`. |
| `And request` | JSON que se enviará. |
| `When method post/get/put/delete` | Envía la solicitud HTTP. |
| `Then status` | Comprueba el código HTTP esperado. |
| `response` | Cuerpo de la última respuesta; cambia con cada solicitud. |
| `* def` | Guarda una variable para usarla después. |
| `match ... ==` | Compara el valor completo. |
| `match ... contains` | Comprueba campos o elementos sin exigir igualdad completa. |
| `#string`, `#number` | Validadores de tipo. |
| `#[1]` | Lista con exactamente un elemento. |
| `##null` | Campo opcional o nulo, útil si la API omite campos con valor null. |
| `#(expresion)` | Inserta el resultado de una expresión en un JSON. |
| `karate.filter` | Selecciona elementos de una lista por una condición. |
| `@R-G1-02` | Etiqueta para filtrar y relacionar la prueba con un requisito. |

Los montos retornados son texto con dos decimales: comparar `'10.00'` con `10`
no es lo mismo. En las celdas `montoEsperado` de esta suite se escribe `10.00`
sin comillas adicionales: Karate 2 conserva esas comillas como parte del texto.

Un escenario negativo pasa si recibe el error previsto. Por ejemplo, pedir un
monto inválido y obtener `422 MONTO_NO_PERMITIDO` es una prueba aprobada.

## 5. Qué preparamos antes de cada prueba

Antes de cada caso, `Background`:

1. Devuelve el reloj de pruebas a la hora real.
2. Restaura los datos semilla con `/api/pruebas/reiniciar`.
3. Inicia sesión como Ana: celular `987654321`, PIN `4826`.
4. Guarda `access_token` y configura `Authorization: Bearer ...`.
5. Comprueba acceso al saldo inicial de `1500.00`.

Este orden es importante: al reiniciar la base se borran las sesiones, así que
primero restauramos los datos y después hacemos login. También volvemos a iniciar
sesión cuando adelantamos el reloj y el token ya venció. Así cada caso empieza
con una sesión válida y no depende del resultado del anterior.

Ejecutamos los casos uno por uno, con un solo hilo. Si se ejecutaran al mismo
tiempo sobre la misma API, uno podría reiniciar la base o cambiar el reloj
mientras otro todavía está probando.

En los casos del proceso diario también controlamos las programadas que vienen
como ejemplo y el débito automático de servicios. Como ese proceso ejecuta ambas
cosas, sus descuentos podrían alterar el saldo que esperamos para la recarga.

## 6. Qué revisamos en cada historia

| Historia y criterios | Escenarios y comprobaciones |
|---|---|
| HU-G1-01 CA1 | Seis montos permitidos; cero, negativos, fracciones no permitidas, texto y celulares inválidos. |
| HU-G1-01 CA2 | Código de operación, monto, saldo, bono y SMS de una recarga manual. Bono sin beneficio, desde S/ 30 y con tope de S/ 4. |
| HU-G1-01 CA3 | Saldo insuficiente sin descuento ni registro; saldo exacto; límite de cinco recargas y combinaciones manual/programada. |
| HU-G1-01 CA4 | Parámetros de configuración por API. Presentación y cálculo previo de la pantalla pendientes de prueba de interfaz. |
| HU-G1-02 CA1 | Crear 21 operaciones y comparar exactamente las últimas 20, sus campos y el orden; comprobar códigos únicos. Los casos diarios también verifican origen PROGRAMADA. |
| HU-G1-03 CA1 | Alias omitido, 20 y 21 caracteres; celular y monto inválidos; días válidos e inválidos. |
| HU-G1-03 CA2 | Estado ACTIVA y próxima ejecución con día futuro, hoy, pasado y cambio de año. |
| HU-G1-03 CA3 | Cuarta activa rechazada; duplicados activos/pausados; recreación tras eliminar. |
| HU-G1-04 CA1 | Campos de la programada y resultado SIN_EJECUCIONES; los casos diarios verifican EXITOSA y FALLIDA. |
| HU-G1-05 CA1 | Editar monto, alias y día; recalcular próxima fecha; edición inválida conserva los datos anteriores. |
| HU-G1-05 CA2 | Pausar libera cupo e impide ejecución; reanudar recalcula fecha; no superar tres activas al reanudar. |
| HU-G1-05 CA3 | Pausar una pausada y reanudar una activa responden 409 ESTADO_INVALIDO. |
| HU-G1-06 CA1 | Eliminada desaparece, no se ejecuta en el siguiente vencimiento y conserva su historial. |
| HU-G1-07 CA1 | No ejecutar antes del vencimiento; ejecutar hoy y atrasadas. |
| HU-G1-07 CA2 | Programadas por 30, 50 y 100: bono y origen; límite compartido con manuales. |
| HU-G1-07 CA3 | Fallo por saldo: estado FALLIDA, SMS y saldo conservado; caso de límite verifica ausencia de recarga, estado y aviso si supera las comprobaciones previas. |
| HU-G1-07 CA4 | Próxima fecha tras éxito/fallo; varios meses atrasados generan una sola ejecución. |
| HU-G1-07 CA5 | Dos llamadas al proceso diario el mismo día no duplican recargas. |
| Seguridad compartida | Sin sesión no se puede recargar ni listar/programar; otro usuario no puede editar, pausar, reanudar o eliminar la programada de Ana. |

Para elegir los datos usamos el análisis de valores límite. Por ejemplo,
probamos S/ 30, que es justo donde empieza el bono, y la quinta y sexta recarga,
que permiten comprobar dónde debe detenerse el sistema. También usamos los días
0, 1, 28 y 29, y alias de 20 y 21 caracteres. En el bono elegimos S/ 20 y S/ 50
como vecinos válidos de S/ 30, porque S/ 29 y S/ 31 no son montos permitidos.

Estos casos se complementan con pruebas de seguridad, historial y cambios de
estado.

## 7. Cómo leer el reporte

Abre `reportes/karate/karate-summary.html` en un navegador. Selecciona la feature
y el escenario rojo; revisa la primera aserción que falla, la solicitud y la respuesta.

- `expected status: 422, actual: 201`: se esperaba rechazo, pero la API aceptó.
- `0.00` frente a `1.50`: la operación respondió, pero el bono incumple el requisito.
- `401 NO_AUTENTICADO`: revisar login, header, reloj y si otra prueba reinició la base.
- `Connection refused`: la API no está disponible en la URL usada.
- Error de expresión JavaScript: revisar la prueba antes de registrar un defecto del producto.

Al revisar un caso rojo, empezamos por la primera comprobación que falló:
Karate se detiene ahí y no ejecuta los pasos restantes de ese escenario. Los otros
casos sí pueden continuar. Además, varios casos pueden fallar por el mismo error;
por ejemplo, el límite de recargas afecta tanto a manuales como a programadas.
Por eso no contamos cada caso fallido como un defecto distinto.

Cada ejecución actualiza el reporte y puede respaldar el anterior en `reportes/`.
Asegúrate de abrir el resultado de la última ejecución y recargar el navegador.

## 8. Cómo agregar un caso

1. Identifica HU, criterio y regla en `docs/requisitos.md`.
2. Confirma endpoint, esquema y código de error con OpenAPI.
3. Agrega un Scenario, o una fila si aplica un Scenario Outline existente.
4. Usa datos que no colisionen con semilla o limita explícitamente ese estado.
5. Comprueba el efecto: respuesta, saldo, historial, estado, fecha y SMS según el criterio.
6. Usa etiquetas de HU/regla y ejecútalo con la API aislada.
7. Si falla, distingue problema de preparación, error de prueba y defecto de la aplicación.
8. Documenta los defectos sin cambiar las expectativas para acomodar errores del producto.

Evita copiar tokens al archivo, usar credenciales personales, depender del día real
para los límites temporales o reutilizar una base con datos que quieras conservar.

## 9. Qué encontramos al ejecutar las pruebas

En la ejecución registrada del 17 de octubre de 2026 usamos una API con base
propia. El resultado fue de **71 casos ejecutados: 64 aprobados y 7 fallidos**.
La suite pasó de 34 a 71 casos al agregar 37 pruebas.

Para la explicación principal del trabajo seleccionamos dos defectos:

- **S/ 30 sin bono (DEF-03):** esperábamos una recarga aceptada con bono de
  S/ 1.50, pero recibimos bono `0.00`. El error aparece justo en el monto donde
  empieza el beneficio, tanto en una recarga manual como en una programada.
- **Sexta recarga aceptada (DEF-04):** después de cinco recargas al mismo número
  por usuario y día, esperábamos `422 LIMITE_RECARGAS`. La API respondió `201` y
  aceptó otra. Una programada y cuatro manuales sí son válidas; la siguiente
  debe rechazarse.

Al revisar el código encontramos comparaciones que dejan fuera la igualdad del
bono y permiten continuar cuando ya hay cinco recargas. Los detalles están en
[DEF-03](defectos.md#def-03-una-recarga-de-s-30-no-recibe-el-bono) y
[DEF-04](defectos.md#def-04-se-acepta-una-sexta-recarga-diaria-al-mismo-número).

La ejecución ampliada también registró un hallazgo al reanudar programadas.
Conservamos el desglose completo para que los resultados coincidan con el reporte:

| Defecto | Escenarios fallidos | Qué ocurre |
|---|---|---|
| DEF-03 | 2 | Recarga manual y programada de S/ 30 devuelven bono `0.00` en vez de `1.50`. |
| DEF-04 | 4 | Se permite una sexta recarga: manual, combinada y programada. |
| DEF-05 | 1 | Reanudar permite superar tres programadas activas. |

El escenario sobre cupos de números distintos falla antes de probar el segundo
número: se detiene porque la sexta recarga del primero se acepta. Por eso ese
resultado no demuestra que un número bloquee a otro; esa comprobación queda
pendiente dentro del escenario.

En esa ejecución no se registraron problemas de login ni de preparación de los
datos. Los pasos para reproducir los errores están en [defectos.md](defectos.md).
También preparamos un [resumen de los casos y de los dos defectos seleccionados](resumen-pruebas-recargas.md):
el bono que falta para S/ 30 y la sexta recarga que se acepta.

Aunque las otras 64 pruebas pasen, Karate termina con un código de error mientras
haya casos fallidos. Para interpretar el resultado hay que revisar qué esperaba
cada caso y qué respondió la aplicación.

Estos resultados corresponden a la ejecución registrada, no a una nueva corrida
realizada al actualizar esta guía. La revisión del alcance está en
[revision-recargas.md](revision-recargas.md).
