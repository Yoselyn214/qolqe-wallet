# Suite de Pruebas de Rendimiento – Qolqe Wallet (Parte 3)

Este directorio contiene la suite completa de pruebas de rendimiento automatizadas para **Qolqe Wallet**, focalizadas en el **Núcleo Común** (autenticación, balance, movimientos) y el módulo asignado **G1: Recargas de Celular**, de acuerdo a los requerimientos de la campaña *"Quincena Qolqe"*.

---

## 1. Estructura del Directorio

```text
tests/performance/
├── config.js                       # Umbrales globales (SLAs), URLs base y funciones de Think Time
├── k6-reporter.js                  # Reporter standalone offline para generación de HTMLs interactivos
├── monitor_recursos.py             # Script Python (psutil) para telemetría CPU % y RAM RSS segundo a segundo
├── graficar_recursos.py            # Generador de gráficos dual-axis de recursos en PNG de alta resolución
├── data/
│   └── usuarios.json               # Dataset determinista de 500 usuarios virtuales independientes con S/ 3,000
├── flujos/
│   ├── auth.js                     # Login y extracción de JWT
│   ├── consultas.js                # Consulta de saldo, perfil y movimientos paginados (Núcleo Común)
│   ├── transferencias.js           # Transferencias P2P circulares aisladas (S/ 5.00)
│   └── recargas.js                 # Catálogo, recarga celular con bono y listado de recargas (Módulo G1)
├── scenarios/
│   ├── humo_validacion.js          # Smoke Test (2 VUs, 15s) para validar conectividad y aserciones
│   ├── carga_hora_punta.js         # Load Test (100 VUs, 9 min) basado en Ley de Little (3,000 ses/hora)
│   ├── pico_campana.js             # Spike Test (300 VUs, 4m30s) para absorción súbita de campaña
│   └── estres_campana.js           # Stress Test (200 -> 500 VUs, 9m15s) para hallar el punto de quiebre
└── resultados/
    ├── reporte_humo.html           # Reporte visual HTML de la prueba de humo
    ├── reporte_carga.html          # Reporte visual HTML de la prueba de carga
    ├── recursos_carga.csv          # Telemetría de CPU y RAM de la prueba de carga
    ├── grafico_carga_recursos.png  # Gráfico de uso de hardware en carga
    ├── reporte_pico.html           # Reporte visual HTML de la prueba de pico
    ├── recursos_pico.csv           # Telemetría de CPU y RAM de la prueba de pico
    ├── grafico_pico_recursos.png   # Gráfico de uso de hardware en pico
    ├── reporte_estres.html         # Reporte visual HTML de la prueba de estrés
    ├── recursos_estres.csv         # Telemetría de CPU y RAM de la prueba de estrés
    └── grafico_estres_recursos.png # Gráfico de uso de hardware en estrés
```

---

## 2. Requisitos Previos y Especificaciones de Hardware

### 2.1. Especificaciones Técnicas del Banco de Pruebas (Host Local)
Para garantizar la reproducibilidad y validez de los resultados de rendimiento (asegurando que el generador de carga no degrade la máquina por encima del 80% de CPU), todas las pruebas se ejecutaron sobre el siguiente entorno:

| Componente | Especificación Técnica | Detalle / Relevancia |
|---|---|---|
| **Procesador (CPU)** | **AMD Ryzen 5 7640HS w/ Radeon 760M Graphics** | 4 núcleos físicos, 8 procesadores lógicos (hilos), frecuencia base/turbo de hasta 4.3 GHz. |
| **Memoria RAM** | **16.0 GB DDR5** (15.2 GB útiles / disponibles) | Ancho de banda de alta velocidad para concurrencia en memoria sin swap a disco. |
| **Almacenamiento** | **Unidad NVMe SSD (M.2 PCIe)** | Espacio disponible > 190 GB. Baja latencia de I/O para el diario WAL de SQLite. |
| **Sistema Operativo** | **Microsoft Windows 11 Home 64-bit** (Build 26300) | Kernel moderno con soporte de sockets TCP eficientes. |
| **Herramienta de Carga** | **Grafana k6 v2.4.0** (commit/dd9395906d, go1.26.11) | Motor nativo en Go; cada VU corre como goroutine ultraligera (2-4 KB). |
| **Runtime de Backend** | **Python 3.13.7 (CPython 64-bit)** | Entorno virtual `.venv` con FastAPI / Starlette y Uvicorn v0.34.0. |
| **Motor de Base de Datos** | **SQLite 3.45+** (Modo WAL activado) | Modo *Write-Ahead Logging* para concurrencia de lectura sin bloqueo. |
| **Entorno Web / Node** | **Node.js v24.11.1 (64-bit)** | Para ejecución de herramientas auxiliares y suites de calidad. |

### 2.2. Requisitos de Configuración Local

1. **k6:** Versión v2.4.0 o superior instalada (`k6 version`).
2. **Python 3.11+ & Entorno Virtual:** Con las librerías `psutil`, `matplotlib` y `python-docx` instaladas en `.\qolqe-wallet\.venv\`.
3. **Servidor Qolqe en ejecución:** Corriendo en el puerto 8000:
   ```powershell
   $env:PYTHONPATH = "D:\workspace\PVS\Proyecto\qolqe-wallet"
   .\.venv\Scripts\uvicorn.exe qolqe.main:app --port 8000
   ```
4. **Semilla de datos aplicada:** Base de datos reiniciada con 500 usuarios dotados de S/ 3,000 cada uno:
   ```powershell
   Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/pruebas/reiniciar"
   ```

---

## 3. Umbrales de Rendimiento Formales (SLAs) y Ponderación de Operaciones

### 3.1. Definición Formal de Umbrales (Requerimiento $\to$ Umbrales Contractuales)
Conforme a los lineamientos del curso, se definió cada umbral de forma estricta: **métrica técnica + percentil/agregación + valor límite + carga aplicable + supuestos**:

| Requerimiento de Negocio | Métrica en k6 | Percentil / Agregación | Valor Límite | Carga Aplicable | Supuestos y Precisiones |
|---|---|---|---|---|---|
| **Consultas e inicio de sesión** | `http_req_duration{tipo:consulta}` | **p(95)** | **$\le$ 800 ms** | 100 VUs (Hora Punta) y 300 VUs (Pico) | Incluye login (`POST /api/auth/login`), saldo, perfil, movimientos y catálogo/historial de recargas. |
| **Operaciones de dinero** | `http_req_duration{tipo:dinero}` | **p(95)** | **$\le$ 1500 ms** | 100 VUs (Hora Punta) y 300 VUs (Pico) | Incluye transferencias P2P (`POST /api/transferencias`) y recargas manuales (`POST /api/recargas`). |
| **Tasa de error global en hora punta** | `http_req_failed` | **Rate (%)** | **$\le$ 1.00%** | 100 VUs sostenidos | Mide exclusivamente errores 5xx de servidor o timeouts de conexión. |
| **Throughput nominal de hora punta** | `http_reqs` (Tasa req/s) | **Promedio continuo** | **$\ge$ 5.00 req/s** | 100 VUs sostenidos | 3,000 sesiones/h $\times$ 6 op/sesión = 18,000 op/h $\implies 5.0\text{ req/s}$ nominales. |
| **Degradación admisible en pico** | `http_req_duration` | **p(95)** | **Hasta +50%** | 300 VUs (Pico) | Se tolera hasta 1200 ms en consultas y 2000 ms en dinero sin superar 1% de error. |
| **Integridad transaccional de dinero** | Auditoría pre/post de balance | **Inconsistencias** | **0.00%** | Todos los escenarios | Cero transacciones duplicadas, corruptas o con pérdida de fondos. |

### 3.2. Ponderación de Operaciones: Mapeo del Negocio al Alcance del Grupo G1

| Operación en Requerimiento General | % Original | Módulo SUT | % en Script k6 (G1) | Justificación de la Distribución |
|---|---|---|---|---|
| Consultar saldo y perfil | 30% | Núcleo | **35%** | Lectura recurrente básica antes y después de cada flujo. |
| Consultar movimientos | 15% | Núcleo | **20%** | Consulta pesada en base de datos con ordenamiento cronológico. |
| Transferir a otro usuario | 15% | Núcleo | **20%** | Transacción monetaria del núcleo común para someter a estrés la BD. |
| **Recargar un celular** | 10% | **G1 (Asignado)** | **20%** | **Módulo asignado:** Se **duplicó** su cuota para sobreexigir al módulo de recargas. |
| **Catálogo y config. de recargas** | *G1* | **G1 (Asignado)** | **5%** | Consulta previa de operadores disponibles y montos permitidos. |
| Contactos, servicios y otros | 30% | G2, G4, G5, G6 | *0% (Reasignado)* | Reasignados a Núcleo y G1 para evaluar el alcance asignado al 100%. |
| **TOTAL** | **100%** | | **100%** | **Distribución balanceada y cerrada al 100%.** |

---

### 3.3. Identificación y Justificación de los 3 Flujos Críticos
Conforme al Punto 1 del enunciado oficial, se priorizaron 3 flujos según frecuencia, impacto financiero y riesgo:
1. **Consulta de Saldo y Movimientos (`GET /api/cuentas/me/saldo`, `GET /api/movimientos`):** 45% del volumen total. Flujo de mayor frecuencia que valida la experiencia inmediata del cliente y somete a estrés las lecturas en BD.
2. **Transferencias P2P (`POST /api/transferencias`):** 20% del volumen. Flujo de impacto financiero directo que debita a un usuario y acredita a otro simultáneamente en una transacción ACID, compitiendo por locks de escritura.
3. **Recargas de Celular con Bonificación (`POST /api/recargas`):** 20% del volumen. Módulo asignado al Grupo G1, evaluando la aplicación del bono del 5% (montos $\ge 30$), topes diarios de 5 operaciones y persistencia de comprobantes bajo concurrencia masiva.

### 3.4. Cadena de Custodia, Trazabilidad y Autenticidad de las Gráficas
Para certificar que las gráficas de telemetría son legítimas y obtenidas de las ejecuciones reales:
1. **Captura en Vivo (`monitor_recursos.py`):** Muestrea segundo a segundo el proceso del servidor Uvicorn vía `psutil`, registrando hora exacta, CPU % y memoria RAM RSS.
2. **Datasets Crudos Preservados:**
   - `recursos_carga.csv`: 615 muestras continuas (prueba de 9 minutos + estabilización).
   - `recursos_pico.csv`: 332 muestras continuas (prueba de 4.5 minutos).
   - `recursos_estres.csv`: 591 muestras continuas (prueba de 9.25 minutos en 4 escalones).
3. **Regeneración Determinista:** Las imágenes PNG no son aleatorias; son renderizadas matemáticamente por `graficar_recursos.py` usando `matplotlib`.
   - Comando de regeneración en vivo:
     ```powershell
     python tests/performance/graficar_recursos.py tests/performance/resultados/recursos_carga.csv verificacion.png "Test Carga"
     ```

---

## 4. Guía de Ejecución de las Pruebas

### 4.1. Escenario 1: Prueba de Humo (Smoke Test)
Valida la integridad de los endpoints y autenticación con 2 VUs durante 15 segundos:
```powershell
k6 run tests/performance/scenarios/humo_validacion.js
```

### 4.2. Escenario 2: Prueba de Carga Normal / Hora Punta (100 VUs)
Simula el tráfico de 3,000 sesiones por hora (Ley de Little: $N = \lambda \times W = 0.833 \times 120 = 100$ VUs) con monitoreo de telemetría:
```powershell
# 1. Iniciar monitor de hardware en segundo plano
Start-Process -FilePath ".\.venv\Scripts\python.exe" -ArgumentList "tests/performance/monitor_recursos.py", "tests/performance/resultados/recursos_carga.csv", "540"

# 2. Ejecutar prueba k6 (duración total 9 minutos)
k6 run tests/performance/scenarios/carga_hora_punta.js

# 3. Generar gráfico de recursos
.\.venv\Scripts\python.exe tests/performance/graficar_recursos.py tests/performance/resultados/recursos_carga.csv tests/performance/resultados/grafico_carga_recursos.png "Carga Hora Punta (100 VUs)"
```

### 4.3. Escenario 3: Prueba de Pico (Spike Test - 300 VUs)
Simula el impacto publicitario de la "Quincena Qolqe" triplicando súbitamente la concurrencia a 300 VUs en 30 segundos:
```powershell
# 1. Iniciar monitor
Start-Process -FilePath ".\.venv\Scripts\python.exe" -ArgumentList "tests/performance/monitor_recursos.py", "tests/performance/resultados/recursos_pico.csv", "270"

# 2. Ejecutar prueba k6 (duración total 4m 30s)
k6 run tests/performance/scenarios/pico_campana.js

# 3. Generar gráfico
.\.venv\Scripts\python.exe tests/performance/graficar_recursos.py tests/performance/resultados/recursos_pico.csv tests/performance/resultados/grafico_pico_recursos.png "Pico Campana (300 VUs)"
```

### 4.4. Escenario 4: Prueba de Estrés y Búsqueda de Punto de Quiebre (500 VUs)
Incrementa progresivamente la concurrencia en 4 escalones (200 $\to$ 300 $\to$ 400 $\to$ 500 VUs):
```powershell
# 1. Iniciar monitor
Start-Process -FilePath ".\.venv\Scripts\python.exe" -ArgumentList "tests/performance/monitor_recursos.py", "tests/performance/resultados/recursos_estres.csv", "555"

# 2. Ejecutar prueba k6 (duración total 9m 15s)
k6 run tests/performance/scenarios/estres_campana.js

# 3. Generar gráfico
.\.venv\Scripts\python.exe tests/performance/graficar_recursos.py tests/performance/resultados/recursos_estres.csv tests/performance/resultados/grafico_estres_recursos.png "Estres Progresivo (500 VUs)"
```

---

## 5. Visualización e Interpretación de Resultados

Los reportes interactivos HTML se encuentran en `tests/performance/resultados/`:
- `reporte_carga.html` (Hora Punta - 100 VUs)
- `reporte_pico.html` (Pico Campaña - 300 VUs)
- `reporte_estres.html` (Estrés y Breakpoint - 500 VUs)
- `reporte_humo.html` (Smoke Test - 2 VUs)

### 5.1. Guía de Lectura de los Indicadores en los Reportes HTML
* **Total Requests:** Volumen acumulado de peticiones completadas (ej. 3,899 en Hora Punta, 14,439 en Estrés).
* **Failed Requests:** Cantidad de peticiones no exitosas. En Hora Punta se registró solo **1 petición fallida de 3,899** (tasa de error real: **0.025%**, cumpliendo con creces el límite de 1.00%).
* **p(95) frente a avg:** El percentil 95 certifica el tiempo experimentado por el 95% de los usuarios, evitando el sesgo del promedio.
* **Throughput (req/s):** Tasa de procesamiento sostenida del servidor (7.22 req/s en carga, superando la meta de 5.0 req/s).

### 5.2. Matriz Ejecutiva de Verificación de Umbrales (SLAs)

| Escenario | Métrica Evaluada | Umbral Contractual | Valor Real Obtenido | Margen de Holgura | Estado de Calidad |
|---|---|---|---|---|---|
| **Humo (2 VUs)** | Consultas p(95)<br/>Dinero p(95)<br/>Tasa de Error | $< 800\text{ ms}$<br/>$< 1500\text{ ms}$<br/>$\le 1.00\%$ | **176.9 ms**<br/>**112.8 ms**<br/>**0.00%** | 77.8% holgura<br/>92.4% holgura<br/>Sin fallos | ✅ **CUMPLE** |
| **Carga (100 VUs)** | Consultas p(95)<br/>Dinero p(95)<br/>Tasa de Error<br/>Throughput | $< 800\text{ ms}$<br/>$< 1500\text{ ms}$<br/>$\le 1.00\%$<br/>$\ge 5.0\text{ req/s}$ | **163.9 ms**<br/>**120.7 ms**<br/>**0.025%** (1 / 3,899)<br/>**7.22 req/s** | **79.5% holgura**<br/>**91.9% holgura**<br/>**97.5% bajo el tope**<br/>+44.4% capacidad | ✅ **CUMPLE PLENAMENTE** |
| **Pico (300 VUs)** | Consultas p(95)<br/>Dinero p(95)<br/>Tasa de Error<br/>Throughput | $< 800\text{ ms}$ (hasta +50%)<br/>$< 1500\text{ ms}$<br/>$\le 1.00\%$<br/>Absorción | **195.7 ms**<br/>**126.3 ms**<br/>**0.027%** (1 / 3,720)<br/>**12.46 req/s** | **75.5% holgura**<br/>**91.6% holgura**<br/>Sin degradación<br/>Triple de carga | ✅ **CUMPLE PLENAMENTE** |
| **Estrés (500 VUs)** | Consultas p(95)<br/>Dinero p(95)<br/>Tasa de Error<br/>CPU Servidor | $< 800\text{ ms}$<br/>$< 1500\text{ ms}$<br/>$\le 1.00\%$<br/>$< 80\%$ | **162.1 ms**<br/>**126.7 ms**<br/>**0.11%** (16 / 14,439)<br/>**67.3%** prom. (pico 288%) | Latencia contenida<br/>Latencia contenida<br/>Contención de lock<br/>Saturación worker | ⚠️ **BREAKPOINT (500 VUs)** |

