# Guía Rápida de Demostración en Vivo: Rendimiento (Parte 3)
### *Procedimiento desde el encendido de la computadora para la sustentación oral*

> Este documento es tu guía de referencia rápida para el día de la presentación en clase (15 minutos de demo + 5 minutos de preguntas).

---

## 1. Al Encender la Computadora (Preparación)

1. Cierra programas pesados (juegos, clientes torrent, Spotify, navegadores con videos) para que el procesador esté libre (< 5% de uso).
2. Abre **dos terminales PowerShell** una al lado de la otra:
   - **Terminal 1:** Para el servidor backend de Qolqe Wallet.
   - **Terminal 2:** Para interactuar, resetear la BD y correr las pruebas k6.

---

## 2. Iniciar el Servidor Backend (Terminal 1)

Copia y pega en la **Terminal 1**:
```powershell
cd D:\workspace\PVS\Proyecto\qolqe-wallet
$env:PYTHONPATH = "D:\workspace\PVS\Proyecto\qolqe-wallet"
.\.venv\Scripts\uvicorn.exe qolqe.main:app --port 8000
```
*Deja esta ventana abierta de fondo durante toda la exposición.*

---

## 3. Limpiar y Restaurar la Base de Datos (Terminal 2)

En la **Terminal 2**, restaura la base de datos limpia con los 500 usuarios deterministas con saldo de S/ 3,000:
```powershell
cd D:\workspace\PVS\Proyecto\qolqe-wallet
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/pruebas/reiniciar" -Method Post
```
*Debe responder: `{"mensaje": "Datos restaurados"}`.*

---

## 4. Ejecución en Vivo de la Prueba (Terminal 2)

### Opción Recomendada (Demostración en 15 segundos - Humo)
Para no hacer esperar a la profesora varios minutos en silencio:
```powershell
npm run test:perf:humo
```
*En 15 segundos k6 terminará y mostrará todos los checks en verde (100%).*

### Si la profesora solicita ver una prueba con mayor concurrencia en vivo:
Ejecuta la prueba de Pico (300 VUs en 4 minutos y medio):
```powershell
npm run test:perf:pico
```

---

## 5. Mostrar los Resultados Oficiales (Navegador)

Explícale a la profesora:
> *"Profesora, para aprovechar al máximo los 15 minutos, hemos traído los reportes interactivos HTML y la telemetría de hardware generados en las pruebas oficiales completas de Carga, Pico y Estrés."*

Abre los reportes en tu navegador ejecutando en la Terminal 2:
```powershell
# Reporte de Carga (Hora Punta - 100 VUs)
Start-Process "tests/performance/resultados/reporte_carga.html"

# Reporte de Pico (Campaña Quincena Qolqe - 300 VUs)
Start-Process "tests/performance/resultados/reporte_pico.html"

# Reporte de Estrés (Punto de Quiebre - 500 VUs)
Start-Process "tests/performance/resultados/reporte_estres.html"
```

### Qué resaltar en pantalla:
- **Pestaña `Thresholds`:** Todo en verde. Consultas p95 < 800 ms (149 ms) y escrituras p95 < 1500 ms (123 ms).
- **Tasa de error (`http_req_failed`):** Carga 0.84% y Pico 0.10% (ambas cumplen la regla $\le$ 1%).
- **Duración de sesión:** 1m 55s (alineado al requisito de 2 minutos).

---

## 6. Mostrar los Gráficos de Telemetría (CPU y RAM)

Abre los gráficos duales generados con matplotlib:
```powershell
Start-Process "tests/performance/resultados/grafico_carga_recursos.png"
Start-Process "tests/performance/resultados/grafico_pico_recursos.png"
Start-Process "tests/performance/resultados/grafico_estres_recursos.png"
```

### Qué destacar:
- **Carga (100 VUs):** CPU promedio de 16.3% (< 80% límite) y RAM en 77 MB. Prueba válida en máquina local.
- **Pico (300 VUs):** Recuperación inmediata del sistema tras el impacto publicitario.
- **Estrés (500 VUs):** Escalamiento de memoria hasta 214 MB sin fugas (*memory leaks*), identificando el techo a 500 VUs.

---

## 7. Preguntas de Examen (Cheat Sheet de Respuestas)

1. **¿Por qué k6 y no JMeter?**
   - *Respuesta:* JMeter usa 1 hilo nativo de SO por cada VU (sobrecarga en máquina local). k6 usa goroutines de 2 KB en Go, usando < 15% de CPU y cumpliendo la restricción de validez del examen.
2. **¿Por qué 100 VUs en Hora Punta?**
   - *Respuesta:* Por la **Ley de Little** ($N = \lambda \times W$). Con 3,000 sesiones/hora (0.833 ses/s) y 120s de sesión: $0.833 \times 120 = 100$ VUs.
3. **¿Por qué no la prueba de resistencia de 12 horas?**
   - *Respuesta:* El enunciado permite explicar por qué no aplica. En laptop local monopolizaría el hardware 12h y saturaría el log WAL de SQLite. Además, demostramos en > 22,000 peticiones que la memoria RAM se libera de inmediato sin fugas.
4. **¿Cuál es el cuello de botella y qué soluciones proponen?**
   - *Respuesta:* En 500 VUs SQLite alcanza contención de bloqueo (*single-writer lock* en WAL) y Uvicorn satura CPU. Solución: migrar a **PostgreSQL con PgBouncer** (MVCC), escalar **Uvicorn multi-worker con Nginx** y cachear en **Redis**.
