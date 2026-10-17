# Revisión de api.feature

Referencia: sección 4 de `docs/requisitos.md`. La suite se integra directamente
mediante `scripts/karate.sh`; no necesita copiarse a `tests/karate/`.

| Regla | Cobertura actual |
|---|---|
| R-G1-01 | Seis montos permitidos; cero, negativos, montos ajenos a la lista y texto. También valida celular y conservación de saldo ante errores. |
| R-G1-02 | Todos los montos permitidos, incluyendo umbral de S/ 30 y tope de S/ 4. SMS y descuento para S/ 50. |
| R-G1-03 | Sexta manual, combinación manual/programada en ambos órdenes, cruce de medianoche y separación entre números. |
| R-G1-04 | Tres activas, rechazo de cuarta, pausadas excluidas, liberación de cupo y límite al reanudar. |
| R-G1-05 | Días 1, 28, 0 y 29; duplicados activos y pausados; recreación tras eliminar; otro día u otro número. |

Los resultados esperados se ajustan a las cinco reglas. El caso textual `cinco`
usa `SOLICITUD_INVALIDA` según el contrato de validación de la API. Las comillas
en las celdas `montoEsperado` se retiraron para que Karate 2 compare el importe
sin comillas literales.

El reloj usa hora de Lima según las convenciones de requisitos. Se restaura antes
de cada caso y se vuelve a iniciar sesión cuando cambia la fecha.
El caso que compara saldo tras el proceso diario pausa la programada semilla y
desactiva el débito de servicios para evitar descuentos ajenos a su objetivo.

Validación: 34 casos, 28 aprobados, 6 fallidos por DEF-03, DEF-04 y DEF-05.
Los pasos posteriores a una aserción fallida no se ejecutan.

Esta cobertura no equivale a probar todas las historias del módulo: faltan,
entre otros, historial de últimas 20 recargas, saldo insuficiente, edición y
recálculo de fechas, transiciones inválidas y ejecución diaria idempotente.
Con los montos permitidos no hay bonos con más de dos decimales; el redondeo
general requiere una prueba de la función, no introducir montos inválidos en HTTP.
