# GUÍA MAESTRA DE COMANDOS DE PRUEBAS: QOLQE WALLET
**Proyecto:** Verificación Integral de API, Web E2E y Rendimiento (Módulo Recargas G1 y Núcleo Común)  
**Repositorio:** [https://github.com/Yoselyn214/qolqe-wallet](https://github.com/Yoselyn214/qolqe-wallet)  
**Directorio de Ejecución:** `D:\workspace\PVS\Proyecto\qolqe-wallet`

---

## 📋 ÍNDICE RÁPIDO
1. [Preparación del Entorno (Prerrequisitos)](#1-preparación-del-entorno-prerrequisitos)
2. [Los 4 Quality Gates Automatizados (Compuertas de Calidad)](#2-los-4-quality-gates-automatizados-compuertas-de-calidad)
3. [Playwright: Pruebas de API y Reglas Financieras](#3-playwright-pruebas-de-api-y-reglas-financieras)
4. [Playwright: Pruebas Web E2E y Regresión Visual](#4-playwright-pruebas-web-e2e-y-regresión-visual)
5. [Qase.io: Sincronización y Trazabilidad en la Nube (TestOps)](#5-qaseio-sincronización-y-trazabilidad-en-la-nube-testops)
6. [Grafana k6: Pruebas de Rendimiento y SLAs](#6-grafana-k6-pruebas-de-rendimiento-y-slas)
7. [Schemathesis: Pruebas de Contrato OpenAPI](#7-schemathesis-pruebas-de-contrato-openapi)
8. [GitHub Actions: Ejecución Manual y Pipelines](#8-github-actions-ejecución-manual-y-pipelines)
9. [Tabla Resumen (Cheat Sheet Rápido)](#9-tabla-resumen-cheat-sheet-rápido)

---

## 1. Preparación del Entorno (Prerrequisitos)

Antes de ejecutar cualquier comando, asegúrate de estar dentro de la carpeta `qolqe-wallet`:

```powershell
cd D:\workspace\PVS\Proyecto\qolqe-wallet
```

### 1.1. Activar Entorno Virtual de Python (Backend y Contrato)
```powershell
# En Windows PowerShell:
.\.venv\Scripts\Activate.ps1

# Si no existe el entorno:
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt -r requirements-contract.txt
```

### 1.2. Instalar Dependencias de Node.js y Navegadores Playwright
```powershell
npm ci
npx playwright install chromium
```

---

## 2. Los 4 Quality Gates Automatizados (Compuertas de Calidad)

Estos comandos ejecutan y evalúan los criterios de aprobación exactos definidos en la rúbrica y en el pipeline de CI/CD:

| Quality Gate | Herramienta | Comando npm | Qué evalúa |
|---|---|---|---|
| **Gate 1: Contrato** | Schemathesis | `npm run test:contract` | Levanta servidor temporal, valida conformidad de OpenAPI en `/api/recargas` con 20 ejemplos deterministas por endpoint y genera JUnit XML. |
| **Gate 2: API** | Playwright API | `npm run gate:api` | Ejecuta los 71 casos de negocio, evalúa 64 aprobados y valida exactamente los 3 defectos conocidos (`DEF-03`, `DEF-04`, `DEF-05`). |
| **Gate 3: Web E2E** | Playwright Web | `npm run gate:web` | Ejecuta los 17 escenarios Web en Chromium (6 Núcleo Común + 11 Recargas G1) y valida que no existan regresiones visuales. |
| **Gate 4: Rendimiento** | Grafana k6 | `npm run test:perf:humo` | Valida conectividad y aserciones de SLAs bajo tráfico concurrente mínimo en CI/CD. |

---

## 3. Playwright: Pruebas de API y Reglas Financieras

Playwright administra automáticamente el levantamiento del backend de pruebas (`scripts/servidor_pruebas.py` en `http://127.0.0.1:8011`).

### 3.1. Ejecución de Pruebas de API
```powershell
# Ejecutar todas las pruebas de API
npm run test:api
# o directamente con Playwright:
npx playwright test tests/api/recargas.spec.js
```

### 3.2. Filtros por Historias de Usuario, Reglas o Casos
```powershell
# Filtrar por Historia de Usuario (ej. HU-G1-01)
npx playwright test tests/api/recargas.spec.js --grep "@HU-G1-01"

# Filtrar por Regla de Negocio (ej. Bono del 5% R-G1-02)
npx playwright test tests/api/recargas.spec.js --grep "@R-G1-02"

# Ejecutar un caso crítico específico (ej. caso del bono en S/ 30)
npx playwright test tests/api/recargas.spec.js --grep "CP-G1-19"

# Ejecutar el caso del límite diario de 5 recargas
npx playwright test tests/api/recargas.spec.js --grep "CP-G1-22"
```

---

## 4. Playwright: Pruebas Web E2E y Regresión Visual

### 4.1. Ejecución General Web
```powershell
# Ejecutar todos los 17 escenarios Web E2E (Modo Headless)
npm run test:e2e
# o directamente:
npx playwright test tests/e2e/
```

### 4.2. Ejecución con Navegador Visible (Modo Headed - Ideal para Sustentación)
```powershell
npx playwright test tests/e2e/recargas.spec.js --headed
```

### 4.3. Modo UI Interactivo (Time-Travel Debugger)
```powershell
# Abre la interfaz gráfica interactiva de Playwright
npx playwright test --ui
```

### 4.4. Depuración Paso a Paso (Playwright Inspector)
```powershell
# Ejecuta deteniéndose en cada clic y aserción
npx playwright test tests/e2e/recargas.spec.js --debug
```

### 4.5. Pruebas de Regresión Visual (Comparación de Snapshots)
```powershell
# Ejecuta y compara contra las capturas base en tests/__snapshots__/
npx playwright test tests/e2e/recargas.spec.js --grep "Regresión visual"

# Actualizar las imágenes base de referencia si cambió el diseño intencionalmente:
npx playwright test tests/e2e/recargas.spec.js -u
```

### 4.6. Abrir Reportes de Playwright
```powershell
# Abre el reporte HTML interactivo generado en la última corrida
npm run report
# o directamente:
npx playwright show-report reportes/playwright/html
```

---

## 5. Qase.io: Sincronización y Trazabilidad en la Nube (TestOps)

Qase.io centraliza los 98 casos de prueba organizados en 3 suites y almacena la multiejecución histórica.

### 5.1. Variables de Entorno de Qase
El proyecto ya cuenta con el token de API preconfigurado en `scripts/qase_sync.js`. Si deseas definirlo explícitamente en tu consola:
```powershell
$env:QASE_TESTOPS_API_TOKEN = "108a30d1577b504d18bafd40e002c724c36b2871d37e6a4a1f2f74b08edc2f39"
$env:QASE_TESTOPS_PROJECT = "QOLQE"
```

### 5.2. Sincronizar Casos y Registrar Multiejecución en Qase.io
Este script crea automáticamente las suites, publica los 98 casos y genera las 2 corridas históricas (Run 2: Detección vs Run 3: Regresión Final):
```powershell
npm run qase:sync
# o con Node:
node scripts/qase_sync.js
```

---

## 6. Grafana k6: Pruebas de Rendimiento y SLAs

La suite de rendimiento está ubicada en `tests/performance/scenarios/` y modela el tráfico de la **Campaña Quincena Qolqe**.

> **Nota:** Para ejecutar k6 localmente, inicia previamente el backend de pruebas en una terminal separada si no está levantado:
> ```powershell
> .\.venv\Scripts\python.exe -m uvicorn qolqe.main:app --host 127.0.0.1 --port 8000
> ```

### 6.1. Ejecución de Escenarios k6
```powershell
# 1. Prueba de Humo (Smoke Test: 2 VUs, 15 segundos)
npm run test:perf:humo
# o: k6 run tests/performance/scenarios/humo_validacion.js

# 2. Prueba de Carga Hora Punta (Load Test: 100 VUs, 9 minutos)
npm run test:perf:carga
# o: k6 run tests/performance/scenarios/carga_hora_punta.js

# 3. Prueba de Pico de Campaña (Spike Test: 300 VUs repentinos)
npm run test:perf:pico
# o: k6 run tests/performance/scenarios/pico_campana.js

# 4. Prueba de Estrés y Capacidad Máxima (Stress Test: 200 -> 500 VUs)
npm run test:perf:estres
# o: k6 run tests/performance/scenarios/estres_campana.js
```

### 6.2. Monitoreo y Gráficos de Recursos (CPU y RAM)
Ubicados en `tests/performance/`:
```powershell
# Registrar consumo de CPU/RAM en segundo plano durante una prueba
.\.venv\Scripts\python.exe tests/performance/monitor_recursos.py --duracion 60 --salida tests/performance/resultados/recursos_prueba.csv

# Generar gráfico PNG de telemetría a partir del CSV
.\.venv\Scripts\python.exe tests/performance/graficar_recursos.py tests/performance/resultados/recursos_carga.csv tests/performance/resultados/grafico_carga.png
```

---

## 7. Schemathesis: Pruebas de Contrato OpenAPI

Valida automáticamente el contrato de la API contra `openapi.json` con property-based testing:

```powershell
# Opción automatizada (levanta servidor en puerto 8012 y genera JUnit XML):
npm run test:contract
# o con Python:
.\.venv\Scripts\python.exe scripts/contrato.py
```

---

## 8. GitHub Actions: Ejecución Manual y Pipelines

Para ejecutar el pipeline en la nube o mostrarlo en vivo durante la sustentación:

1. Ingresa a: [https://github.com/Yoselyn214/qolqe-wallet/actions](https://github.com/Yoselyn214/qolqe-wallet/actions)
2. Selecciona el workflow: **`Automatización de Pruebas - Qolqe Wallet (G1 Recargas)`**.
3. Haz clic en el botón gris **Run workflow**:
   - Casilla marcada (por defecto): Genera reportes completos con capturas, videos y trazas ZIP.
   - Casilla desmarcada: Realiza una pasada ultrarrápida sin artefactos pesados.
4. Al terminar la ejecución:
   - Revisa el grafo secuencial de los 4 jobs (`contrato` → `pruebas-api` → `pruebas-web` → `rendimiento`).
   - Revisa la tabla del **Step Summary** al pie de la página con los Quality Gates en verde.
   - Descarga los artefactos generados en la sección **Artifacts** (`evidencia-contrato`, `evidencia-api`, `evidencia-web`, `evidencia-rendimiento`).

---

## 9. Tabla Resumen (Cheat Sheet Rápido)

| Qué quieres probar | Comando exacto |
|---|---|
| **Probar todo (API + Web)** | `npm test` |
| **Compuerta 1: Contrato OpenAPI** | `npm run test:contract` |
| **Compuerta 2: Reglas de Negocio API** | `npm run gate:api` |
| **Compuerta 3: Interfaz Web E2E** | `npm run gate:web` |
| **Compuerta 4: Rendimiento k6 (Humo)** | `npm run test:perf:humo` |
| **Rendimiento: Carga Hora Punta (100 VUs)** | `npm run test:perf:carga` |
| **Rendimiento: Pico de Campaña (300 VUs)** | `npm run test:perf:pico` |
| **Rendimiento: Estrés Máximo (500 VUs)** | `npm run test:perf:estres` |
| **Ver Web con Navegador Abierto (Headed)** | `npx playwright test tests/e2e/ --headed` |
| **Playwright Modo Interactivo (UI)** | `npx playwright test --ui` |
| **Ver Reporte HTML de Playwright** | `npm run report` |
| **Sincronizar Casos y Corridas con Qase.io** | `npm run qase:sync` |
| **Filtrar por Caso Crítico en API** | `npx playwright test tests/api/ --grep "CP-G1-19"` |
| **Verificar Regresión Visual** | `npx playwright test tests/e2e/ --grep "Regresión visual"` |
