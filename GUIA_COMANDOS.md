# Guía Maestra de Comandos de Pruebas: Qolqe Wallet

> Este documento centraliza todos los comandos necesarios para ejecutar, depurar y generar reportes de las suites de prueba de **Playwright**, **Schemathesis** y **Karate**.  
> **Uso:** Esta guía se mantendrá actualizada a medida que se incorporen nuevas pruebas, herramientas o configuraciones al proyecto.

---

## 1. Preparación del Entorno (Prerrequisitos)

Antes de ejecutar las pruebas, asegúrate de tener el entorno preparado dentro de la carpeta `qolqe-wallet`:

```powershell
# 1. Crear y activar entorno virtual de Python (3.11 o 3.12)
py -m venv .venv
.\.venv\Scripts\Activate.ps1

# 2. Instalar dependencias de desarrollo y contrato
pip install -r requirements-dev.txt -r requirements-contract.txt

# 3. Instalar dependencias de Node.js y navegadores de Playwright
npm ci
npx playwright install chromium
```

---

## 2. Playwright (Automatización Activa: API y Web E2E)

Playwright gestiona automáticamente el ciclo de vida del servidor de pruebas (`scripts/servidor_pruebas.py` en `http://127.0.0.1:8011`).

### 2.1. Ejecución General
| Comando | Función |
|---|---|
| `npm test` | Ejecuta **todas** las pruebas (API y Web E2E) usando el navegador Chromium configurado. |
| `npm run test:api` | Ejecuta exclusivamente las pruebas de API (`tests/api/**/*.spec.js`). |
| `npm run gate:api` | Evalúa el **Quality Gate 2** (cobertura funcional/técnica y matriz de defectos conocidos). |
| `npm run test:e2e` | Ejecuta exclusivamente las pruebas Web E2E de interfaz (`tests/e2e/**/*.spec.js`). |
| `npx playwright test tests/e2e/recargas.spec.js` | Ejecuta un archivo de prueba específico. |

---

### 2.2. Filtros por Etiquetas, Reglas o Casos de Prueba
Playwright permite filtrar escenarios mediante `--grep`:

| Comando | Función |
|---|---|
| `npx playwright test --grep "@HU-G1-01"` | Ejecuta solo las pruebas vinculadas a la Historia de Usuario 1. |
| `npx playwright test --grep "@R-G1-02"` | Ejecuta solo las pruebas asociadas a la Regla de Negocio 2 (Bonos y límites). |
| `npx playwright test --grep "CP-WEB-G1-01"` | Ejecuta únicamente el caso de prueba web `CP-WEB-G1-01`. |
| `npx playwright test --grep-invert "@smoke"` | Ejecuta todas las pruebas **excepto** las que tengan el tag `@smoke`. |

---

### 2.3. Pruebas de Regresión Visual (Screenshots)
El proyecto cuenta con validación visual para el comprobante de recarga y el formulario de recarga:

| Comando | Función |
|---|---|
| `npx playwright test tests/e2e/recargas.spec.js` | Compara las pantallas actuales contra las líneas base guardadas en `tests/__snapshots__/`. Si hay discrepancias visuales (CSS, layout), la prueba falla. |
| `npx playwright test --update-snapshots` (o `-u`) | **Actualiza o regenera** las imágenes de referencia canónicas si hubo un rediseño visual intencional. |

---

### 2.4. Depuración y Modos Interactivos
| Comando | Función |
|---|---|
| `npx playwright test --ui` | Abre la **interfaz gráfica interactiva de Playwright** (Time-Travel, árbol de componentes, inspección de selectores en vivo). |
| `npx playwright test --debug` | Abre el **Playwright Inspector** paso a paso, permitiendo pausar la ejecución y depurar cada acción. |
| `npx playwright test --headed` | Ejecuta las pruebas mostrando la ventana real del navegador (modo no-headless). |
| `npx playwright show-trace <ruta-al-trace.zip>` | Abre el **Trace Viewer** para examinar la traza completa (red, consola, snapshots del DOM paso a paso). |

---

### 2.5. Grabación de Video y Evidencias en Fallos
* **Configuración activa:** `video: 'retain-on-failure'` y `screenshot: 'only-on-failure'` en `playwright.config.js`.
* Cuando una prueba falla, Playwright guarda automáticamente:
  - Video del fallo (`.webm`) en `reportes/playwright/resultados/`.
  - Captura del momento del error (`.png`).
  - Archivo de traza (`trace.zip`).

---

### 2.6. Visualización de Reportes
| Comando | Función |
|---|---|
| `npm run report` | Abre el reporte interactivo en HTML (`reportes/playwright/html/index.html`). |
| Archivo: `reportes/playwright/junit.xml` | Reporte en formato XML estándar para integración continua (CI). |
| Archivo: `reportes/playwright/trazabilidad.json` | Matriz que vincula cada `CP`, `HU`, regla de negocio, duración y estado con el pipeline. |

---

## 3. Schemathesis (Pruebas de Contrato y Fuzzing de API)

Schemathesis valida que la implementación de la API cumpla fielmente con el esquema OpenAPI (`openapi.json`), generando automáticamente casos de prueba negativos, tipos de datos límite y combinaciones de entrada para detectar fallos no contemplados en endpoints `/api/recargas`.

### 3.1. Ejecución Automatizada
El script `scripts/contrato.py` levanta una instancia temporal del servidor en el puerto `8012`, reinicia los datos, obtiene un token JWT válido, ejecuta Schemathesis y apaga el servidor al terminar:

```powershell
# Opción 1: A través del script de npm
npm run test:contract

# Opción 2: Directamente con el intérprete de Python del entorno
python scripts/contrato.py
# O en Windows:
.\.venv\Scripts\python.exe scripts/contrato.py
```

### 3.2. Ejecución Manual Directa por CLI
Si el servidor ya está corriendo manualmente en `http://127.0.0.1:8012`:

```powershell
schemathesis run http://127.0.0.1:8012/openapi.json `
  --include-path-regex "^/api/recargas(?:/.*)?$" `
  --header "Authorization: Bearer <TU_TOKEN_AQUI>" `
  --max-examples 20 `
  --seed 5383 `
  --report junit `
  --report-junit-path reportes/contrato/junit.xml
```

* **Explicación de parámetros:**
  - `--include-path-regex`: Limita las pruebas a las rutas bajo `/api/recargas`.
  - `--header`: Proporciona la cabecera de autorización Bearer.
  - `--max-examples 20`: Genera 20 ejemplos de prueba por cada operación.
  - `--seed 5383`: Garantiza que la generación de datos sea 100% determinista y reproducible.
  - `--report junit`: Exporta el reporte a `reportes/contrato/junit.xml`.

---

## 4. Karate (Pruebas BDD / API - Referencia Histórica)

Karate contiene la suite histórica de 71 escenarios de la primera entrega definidos en `features/api.feature`. Requiere Java 21+ y Karate standalone (`karate-2.0.0.jar`).

### 4.1. Preparación previa
Descargar el JAR de Karate (solo una vez):
```powershell
New-Item -ItemType Directory -Force .tools | Out-Null
Invoke-WebRequest -Uri "https://github.com/karatelabs/karate/releases/download/v2.0.0/karate-2.0.0.jar" -OutFile ".tools\karate-2.0.0.jar"
```

### 4.2. Terminal 1: Iniciar API dedicada (puerto 8001)
```powershell
New-Item -ItemType Directory -Force datos | Out-Null
$env:QOLQE_BD = Join-Path (Get-Location).Path "datos\karate-windows.db"
$env:QOLQE_MODO_PRUEBA = "1"
.\.venv\Scripts\python.exe -m uvicorn qolqe.main:app --host 127.0.0.1 --port 8001
```

### 4.3. Terminal 2: Comandos de ejecución de Karate
Desde la raíz del proyecto, inicializa las variables y posiciónate en `tests/karate`:
```powershell
$raiz = (Get-Location).Path
$jar = Join-Path $raiz ".tools\karate-2.0.0.jar"
$reporte = Join-Path $raiz "reportes\karate"
$feature = Join-Path $raiz "features\api.feature"
Set-Location (Join-Path $raiz "tests\karate")
```

| Comando | Función |
|---|---|
| `java "-DbaseUrl=http://127.0.0.1:8001" -jar "$jar" run --threads 1 --output "$reporte" --tags @recargas . "$feature"` | Ejecuta solo los escenarios de recargas. |
| `java "-DbaseUrl=http://127.0.0.1:8001" -jar "$jar" run --threads 1 --output "$reporte" . "$feature"` | Ejecuta toda la suite (salud, autenticación y recargas). |
| `java "-DbaseUrl=http://127.0.0.1:8001" -jar "$jar" run --threads 1 --output "$reporte" --tags @R-G1-02 . "$feature"` | Filtra por una regla específica (ej. `@R-G1-02`). |
| `java "-DbaseUrl=http://127.0.0.1:8001" -jar "$jar" run --threads 1 --output "$reporte" --tags @recargas --name "Saldo insuficiente" . "$feature"` | Busca y ejecuta un escenario por nombre. |
| `Start-Process (Join-Path $reporte "karate-summary.html")` | Abre el reporte HTML generado por Karate. |

> [!IMPORTANT]
> Mantén siempre `--threads 1`: los escenarios comparten base de datos y control de reloj; la ejecución en paralelo corrompería las aserciones de saldo y límites.

---

## 5. Tabla Resumen Rápida (Cheat Sheet)

| Herramienta | Objetivo | Comando Rápido |
|---|---|---|
| **Playwright** | Ejecutar todo | `npm test` |
| **Playwright** | Solo API (funcional + técnica) | `npm run test:api` |
| **Quality Gate** | Evaluar Quality Gate 2 (API) | `npm run gate:api` |
| **Playwright** | Solo Web E2E | `npm run test:e2e` |
| **Playwright** | Modo Interactivo UI | `npx playwright test --ui` |
| **Playwright** | Depurador paso a paso | `npx playwright test --debug` |
| **Playwright** | Actualizar screenshots | `npx playwright test --update-snapshots` |
| **Playwright** | Ver reporte HTML | `npm run report` |
| **Schemathesis** | Pruebas de contrato (Quality Gate 1) | `npm run test:contract` |
| **Karate** | Recargas API | `java -DbaseUrl=... -jar karate-2.0.0.jar run --threads 1 --tags @recargas . features/api.feature` |
| **Karate** | Ver reporte | `Start-Process reportes/karate/karate-summary.html` |
