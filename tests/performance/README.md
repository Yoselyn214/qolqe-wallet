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

## 3. Umbrales de Rendimiento (SLAs)

Definidos contractualmente en `config.js` conforme al documento de requisitos:
- **Transacciones de Consulta (Lectura):** 95% de peticiones (`p(95)`) $\le$ 800 ms.
- **Transacciones Monetarias (Escritura):** 95% de peticiones (`p(95)`) $\le$ 1500 ms.
- **Tasa Global de Fallos HTTP:** $\le$ 1.00% (`http_req_failed`).
- **Validez de Entorno Local:** Uso de CPU de herramientas $\le$ 80% para evitar saturación espuria.

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

## 5. Visualización de Resultados

Los reportes HTML generados se abren directamente en cualquier navegador web:
- `tests/performance/resultados/reporte_carga.html`
- `tests/performance/resultados/reporte_pico.html`
- `tests/performance/resultados/reporte_estres.html`
- `tests/performance/resultados/reporte_humo.html`
