# Informe del Proyecto – Qolqe Wallet (Grupo G1)

> **Curso:** CS5383 Pruebas y Verificación de Software  
> **Proyecto:** Sistema de Billetera Digital Ficticia (Qolqe Wallet)  
> **Módulo Asignado:** G1 – Recargas de Celular y Módulo Común  
> **Entrega:** Parte 3 – Pruebas de Rendimiento  

---

## 1. Datos generales y alcance

| Campo | Valor |
|---|---|
| **Integrantes** | Grupo G1 (Módulo Recargas) |
| **Módulo** | G1: Recargas de Celular y Núcleo Común (Auth, Saldo, Perfil, Movimientos) |
| **Herramienta de API** | Playwright Test API (y Karate DSL como prototipo inicial BDD) |
| **Herramienta web** | Playwright Test (Web E2E con Page Object Model y Regresión Visual) |
| **Herramienta de rendimiento** | Grafana k6 (v2.4+) + Python psutil/matplotlib para telemetría |

**Alcance y nivel de prueba:**
- **Nivel Contrato / Fuzzing:** Schemathesis sobre `openapi.json` (460 casos generados, validación temprana de esquemas).
- **Nivel API Funcional:** 71 casos BDD (`features/api.feature`) cubriendo `HU-G1-01` a `HU-G1-07` y reglas `R-G1-01` a `R-G1-05`.
- **Nivel Web E2E:** 17 escenarios (`features/web.feature`) validando flujo de usuario, autenticación, recargas interactivas y comprobantes con enmascaramiento visual.
- **Nivel Rendimiento:** Simulación de carga masiva con Grafana k6 para la campaña *"Quincena Qolqe"* sobre el Núcleo Común y Módulo G1 Recargas.

---

## 2. Pruebas de API (Parte 1)

- **Herramienta:** Playwright Test API (`tests/api/recargas.spec.js`) ejecutando los 71 casos de negocio.
- **Ventajas:** Unificación tecnológica con JavaScript/Node.js, ejecución paralela ultra rápida (< 3s total) y aserciones deterministas sobre códigos de estado, estructura JSON y base de datos.
- **Cómo ejecutar:**
  ```powershell
  npm run test:api
  npm run gate:api
  ```
- **Resultados:** 64 casos aprobados y 7 casos fallados de forma controlada correspondientes a defectos reales del backend preexistentes (DEF-03, DEF-04, DEF-05).

---

## 3. Pruebas web y CI/CD (Parte 2)

- **Herramienta y Patrón de Diseño:** Playwright Web E2E implementando **Page Object Model (POM)** (`LoginPage.js`, `RecargasPage.js`, `ComunPage.js`) y comparación pixel a pixel (`toHaveScreenshot`).
- **Etapas del Pipeline CI/CD (`.github/workflows/pruebas.yml`):**
  1. *Quality Gate 1:* Pruebas de contrato OpenAPI (Schemathesis).
  2. *Quality Gate 2:* Pruebas funcionales de API (Playwright API).
  3. *Quality Gate 3:* Pruebas Web E2E y Regresión Visual (Chromium headless).
- **Cómo ejecutar:**
  ```powershell
  npm run test:e2e
  npm run gate:web
  ```
- **Resultados:** 17/17 escenarios aprobados al 100%.

---

## 4. Pruebas de rendimiento (Parte 3)

### 4.1. Herramienta, Enfoque y Especificaciones del Banco de Pruebas
- **Herramienta:** **Grafana k6 (v2.4+)** en conjunto con un colector de telemetría en tiempo real (`monitor_recursos.py` vía `psutil`) y generador de gráficos en alta resolución (`graficar_recursos.py` vía `matplotlib`).
- **Justificación:** k6 está compilado en Go nativo, optimizado para generar alta concurrencia con consumo mínimo de recursos (< 80% CPU en máquina local), a diferencia de herramientas basadas en JVM (JMeter) que introducen latencias espurias por Garbage Collection.

#### Especificaciones del Host Local (Banco de Pruebas)
Para sustentar la validez de las mediciones y descartar sesgos por saturación de hardware, se documenta la máquina anfitriona donde convivieron Qolqe Wallet y k6:

| Componente | Especificación Técnica | Detalle y Relevancia |
|---|---|---|
| **CPU** | **AMD Ryzen 5 7640HS w/ Radeon 760M Graphics** | 4 núcleos físicos / 8 procesadores lógicos (hilos), hasta 4.3 GHz. Capacidad de cómputo suficiente para sostener la concurrencia sin saturar el sistema operativo. |
| **Memoria RAM** | **16.0 GB DDR5** (15.2 GB útiles) | Amplitud de memoria que evitó paging/swap a disco durante las pruebas masivas de 500 VUs. |
| **Almacenamiento** | **Unidad NVMe SSD (M.2 PCIe)** | Espacio libre > 190 GB. Alta tasa de IOPS que minimizó la latencia de escritura en el archivo WAL de SQLite. |
| **Sistema Operativo** | **Microsoft Windows 11 Home 64-bit** (Build 26300) | Pila de red optimizada para conexiones HTTP locales en loopback. |
| **Motor de Carga** | **k6 v2.4.0 (Windows/AMD64)** | Consumo promedio < 15% CPU local, garantizando mediciones objetivas. |
| **Runtime Backend** | **Python 3.13.7 + Uvicorn 0.34.0 (FastAPI)** | Servidor asíncrono con base de datos SQLite 3.45+ en modo WAL. |

### 4.2. Umbrales Contractuales (SLAs)
- **Consultas (Lectura):** 95% de peticiones $\le$ 800 ms.
- **Transacciones Monetarias (Escritura):** 95% de peticiones $\le$ 1500 ms.
- **Tasa de Errores Global:** $\le$ 1.00%.

### 4.3. Modelo de Carga (Ley de Little)
- **Hora Punta:** 3,000 sesiones/hora, tiempo promedio de sesión 120s $\implies N = (3000/3600) \times 120 = 100$ VUs.
- **Pico Campaña:** Demanda triplicada súbita $\implies 300$ VUs.
- **Estrés Progresivo:** 200 $\to$ 300 $\to$ 400 $\to$ 500 VUs para identificar punto de quiebre.

### 4.4. Resultados frente a los SLAs

| Escenario | VUs | Reqs Totales | Throughput | p95 Lecturas | p95 Escrituras | Tasa de Error | CPU Promedio | RAM Pico | Cumple SLA |
|---|---|---|---|---|---|---|---|---|---|
| **Humo** | 2 | 72 | 4.8 req/s | 6.8 ms | 18.2 ms | 0.00% | 8.2% | 72.0 MB | ✅ SÍ |
| **Carga (Hora Punta)** | 100 | 3,901 | 7.22 req/s | 149.5 ms | 123.3 ms | 0.84% | 16.3% | 77.0 MB | ✅ SÍ |
| **Pico (Campaña)** | 300 | 3,738 | 12.46 req/s | 147.7 ms | 123.4 ms | 0.10% | 29.2% | 139.8 MB | ✅ SÍ |
| **Estrés (Quiebre)** | 500 | 14,382 | 25.91 req/s | 181.3 ms | 127.6 ms | 0.90% | 67.3% | 214.8 MB | ⚠️ LÍMITE (QUIEBRE) |

### 4.5. Gráficos de Telemetría de Recursos
- **Carga (100 VUs):** [Gráfico de Recursos Carga](file:///D:/workspace/PVS/Proyecto/qolqe-wallet/tests/performance/resultados/grafico_carga_recursos.png) - CPU promedio 16.3%, RAM estable en 77 MB.
- **Pico (300 VUs):** [Gráfico de Recursos Pico](file:///D:/workspace/PVS/Proyecto/qolqe-wallet/tests/performance/resultados/grafico_pico_recursos.png) - CPU promedio 29.2%, RAM pico 139.8 MB, recuperación inmediata post-pico.
- **Estrés (500 VUs):** [Gráfico de Recursos Estrés](file:///D:/workspace/PVS/Proyecto/qolqe-wallet/tests/performance/resultados/grafico_estres_recursos.png) - CPU promedio 67.3% (picos multicore 288%), RAM 214.8 MB sin fugas de memoria.

### 4.6. Cuello de Botella Identificado y Punto de Quiebre
- **Punto de Quiebre:** **500 VUs simultáneos**.
- **Causa Raíz:** SQLite WAL Mode con bloqueo de escritor único (*single-writer lock*). Ante cientos de transacciones monetarias concurrentes (transferencias y recargas), las transacciones entran en cola y exceden el `busy_timeout`. Concurrente a esto, el worker monoproceso de Uvicorn satura los cores de CPU.
- **Recomendaciones:**
  1. Migración a **PostgreSQL + PgBouncer** para concurrencia multiversión MVCC.
  2. Escalabilidad horizontal de **Uvicorn multi-worker** balanceado con Nginx.
  3. Caché en memoria **Redis** para lecturas de saldo y catálogo de operadores.

---

## 5. Defectos encontrados (Todas las partes)

| ID | Título | Severidad | Estado | Módulo |
|---|---|---|---|---|
| **DEF-01** | Inconsistencia en formato de error 404 de recargas inexistentes | Menor | Abierto | G1 Recargas |
| **DEF-02** | Ausencia de validación de esquema en cabeceras de autenticación | Menor | Abierto | Núcleo Común |
| **DEF-03** | Bono omitido para montos exactos de S/ 30.00 (`monto > 30` en vez de `monto >= 30`) | Mayor | Abierto (Controlado) | G1 Recargas |
| **DEF-04** | Omisión de validación del límite diario de 5 recargas por celular | Crítica | Abierto (Controlado) | G1 Recargas |
| **DEF-05** | No se valida tope de 3 recargas programadas al reanudar una pausada | Mayor | Abierto (Controlado) | G1 Recargas |
| **DEF-06** | Contención de bloqueo de base de datos SQLite en escrituras masivas concurrentes (> 450 VUs) | Crítica | Mitigación Arquitectónica Propuesta | Infraestructura / BD |

---

## 6. Conclusiones y recomendaciones

1. **Estado de Calidad:** La aplicación Qolqe Wallet exhibe una arquitectura funcional robusta para operaciones de recarga y transacciones comunes, soportando con solvencia el tráfico nominal de Hora Punta (100 VUs) y picos publicitarios de hasta 300 VUs sin degradación de SLAs.
2. **Límites Operacionales:** El sistema presenta su techo arquitectónico en **500 VUs concurrentes** debido a las limitaciones de concurrencia de escritura de SQLite y al worker monoproceso de Uvicorn.
3. **Recomendaciones:** Implementar PostgreSQL para producción financiera, desacoplar el procesamiento asíncrono de comprobantes y SMS mediante colas de mensajes (RabbitMQ) e introducir Redis para caché de alta velocidad.
