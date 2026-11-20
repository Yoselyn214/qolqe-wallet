# Qolqe Wallet — Grupo G1: Recargas de Celular y Módulo Común

> **Curso:** CS5383 Pruebas y Verificación de Software  
> **Proyecto 2:** Sistema de Billetera Digital Ficticia (SUT)  
> **Integrantes:** Grupo G1  

---

## 📌 Guía de Documentación Oficial y Entregables

Para facilitar la revisión y evaluación del repositorio, la documentación oficial está clasificada de forma limpia para evitar duplicidades:

| Documento | Ubicación | Descripción / Propósito |
|---|---|---|
| 📘 **Informe Oficial Consolidado** | [`docs/informe.md`](docs/informe.md) | **Documento Principal de Calificación.** Reúne la Pirámide de Pruebas de Mike Cohn, justificación técnica de herramientas, Cobertura de API (Parte 1), Pruebas Web E2E y CI/CD con Qase.io (Parte 2), Pruebas de Rendimiento k6 y SLAs (Parte 3), Registro Consolidado de Defectos (DEF-01 al DEF-06) y Conclusiones. |
| 🐛 **Reporte Detallado de Defectos** | [`docs/defectos.md`](docs/defectos.md) | Ficha técnica y pasos de reproducción de los defectos detectados en la API y el sistema (DEF-01 a DEF-06). |
| ⚡ **Guía Maestra de Comandos** | [`GUIA_COMANDOS.md`](GUIA_COMANDOS.md) | Manual de referencia con comandos para reproducir localmente Playwright, Schemathesis, k6 (Rendimiento) y Qase sync. |
| 📋 **Requisitos y Reglas de Negocio** | [`docs/requisitos.md`](docs/requisitos.md) | Especificación de Historias de Usuario, criterios de aceptación y reglas del módulo G1 y núcleo común. |
| 📊 **Matriz de Trazabilidad** | [`docs/trazabilidad-recargas.json`](docs/trazabilidad-recargas.json) | Mapeo determinista entre Historias de Usuario / Reglas y los Casos de Prueba (`CP-G1-01` a `CP-G1-71`). |
| 🚀 **Suite de Rendimiento (k6)** | [`tests/performance/README.md`](tests/performance/README.md) | Explicación técnica de la suite de carga, estrés, pico, telemetría psutil y reportes interactivos HTML. |
| 🤖 **Declaración de Uso de IA** | [`IA.md`](IA.md) | Declaración formal de asistencia de Inteligencia Artificial según la rúbrica del curso. |
| 📁 **Histórico Entrega 1 (Karate)** | [`docs/historico-karate/`](docs/historico-karate/) | Guías y especificaciones iniciales con Karate DSL (conservadas solo como antecedente histórico). |

---

## ⚡ Ejecución Rápida de Suites de Prueba

Con el entorno configurado (Python + Node.js):

```bash
# 1. Pruebas Funcionales: API (71 casos) y Web E2E (17 casos con POM)
npm test

# 2. Quality Gates individuales
npm run gate:api        # Quality Gate 2: API Recargas (tolerancia estricta a DEF-03/04/05)
npm run gate:web        # Quality Gate 3: Web E2E y Regresión Visual

# 3. Pruebas de Contrato (OpenAPI 3.1 con Schemathesis)
npm run test:contract

# 4. Pruebas de Rendimiento (Grafana k6 - Smoke Test)
npm run test:perf:humo

# 5. Generar reporte HTML de Playwright
npm run report
```

Para instrucciones detalladas paso a paso y escenarios avanzados de rendimiento, consulte la [Guía Maestra de Comandos](GUIA_COMANDOS.md).

---

## 1. Requisitos del Sistema

- Python **3.11 o superior** (recomendado 3.12)
- Node.js **20 o superior** (recomendado 22 LTS)
- Git

## 2. Instalación y Ejecución de la Aplicación

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn qolqe.main:app --reload
```

| Recurso | URL |
|---|---|
| Interfaz web | http://localhost:8000 |
| Documentación de la API (Swagger / OpenAPI) | http://localhost:8000/docs |
| Contrato OpenAPI en JSON | http://localhost:8000/openapi.json |
| Estado del servicio | http://localhost:8000/api/salud |

La primera vez la app crea la base de datos en `datos/` (tarda unos segundos porque genera los usuarios de carga). Para empezar desde cero, borren la carpeta `datos/` o usen `POST /api/pruebas/reiniciar`.

> Ejecuten **un solo proceso** de uvicorn (sin `--workers`). El reloj de pruebas vive en memoria.

### Variables de entorno (opcionales)

| Variable | Por defecto | Uso |
|---|---|---|
| `QOLQE_BD` | `datos/qolqe.db` | Ruta de la base de datos |
| `QOLQE_MODO_PRUEBA` | `1` | `1` habilita la API de soporte para pruebas (`/api/pruebas/*`) |
| `QOLQE_MINUTOS_TOKEN` | `30` | Vigencia del token JWT |
| `QOLQE_CLAVE_SECRETA` | clave de desarrollo | Firma de los tokens |

---

## 3. Funcionalidades del SUT

| Módulo | Pantalla | Endpoints principales |
|---|---|---|
| **Núcleo:** registro, sesión, perfil, saldo y transferencias | `/registro`, `/login`, `/inicio`, `/perfil`, `/transferir` | `POST /api/usuarios` · `POST /api/auth/login` · `POST /api/auth/logout` · `GET/PUT /api/cuentas/me` · `POST /api/cuentas/me/cierre` · `GET /api/cuentas/me/saldo` · `POST /api/transferencias` · `GET /api/transferencias/comision` |
| **G1** Recargas y recargas programadas | `/recargas` | `GET /api/recargas/configuracion` · `GET/POST /api/recargas` · `GET/POST /api/recargas/programadas` · `PUT/DELETE /api/recargas/programadas/{id}` · `POST /api/recargas/programadas/{id}/pausar` · `POST .../reanudar` |
| **G2** Pago de servicios y afiliaciones | `/servicios` | `GET /api/servicios/empresas` · `GET /api/servicios/deudas` · `GET/POST /api/servicios/pagos` · `GET /api/servicios/pagos/{codigo}` · `GET/POST /api/servicios/afiliaciones` · `PUT/DELETE /api/servicios/afiliaciones/{id}` |
| **G3** Historial y categorías | `/historial` | `GET /api/movimientos` · `GET /api/movimientos/recientes` · `GET /api/movimientos/{codigo}` · `PUT /api/movimientos/{codigo}/clasificacion` · `GET /api/movimientos/exportar` · `GET/POST /api/categorias` · `PUT/DELETE /api/categorias/{id}` |
| **G4** Contactos y solicitudes de dinero | `/contactos`, `/solicitudes` | `GET/POST /api/contactos` · `PUT/DELETE /api/contactos/{id}` · `GET/POST /api/solicitudes` · `POST /api/solicitudes/{id}/aceptar` · `.../rechazar` · `.../cancelar` |
| **G5** Límites y alertas de consumo | `/limites` | `GET/PUT /api/limites` · `GET/POST /api/limites/alertas` · `PUT/DELETE /api/limites/alertas/{id}` |
| **G6** Seguridad, dispositivos y sesiones | `/seguridad`, `/desbloqueo` | `PUT /api/seguridad/pin` · `POST /api/seguridad/desbloqueo/solicitar` · `.../confirmar` · `GET/POST /api/seguridad/dispositivos` · `PUT/DELETE /api/seguridad/dispositivos/{id}` · `GET/DELETE /api/seguridad/sesiones` · `DELETE /api/seguridad/sesiones/{id}` |

Las **historias de usuario, criterios de aceptación y reglas de negocio** están en `docs/requisitos.md`.

### Autenticación y Manejo de Errores

```http
POST /api/auth/login
Content-Type: application/json

{"celular": "987654321", "pin": "4826"}
```

Envíen el token devuelto en cada solicitud protegida:

```http
Authorization: Bearer <access_token>
```

- Cada inicio de sesión crea una **sesión**; el token vence a los **30 minutos**.
- `POST /api/auth/logout` cierra la sesión.
- Tras **3 intentos fallidos** consecutivos, la cuenta se bloquea 15 minutos (`423`).

---

## 4. Datos de Prueba Predefinidos

Se restauran con `POST /api/pruebas/reiniciar`:

### Usuarios Principales

| Usuario | Celular | PIN | Saldo | Notas |
|---|---|---|---|---|
| Ana Torres Quispe | 987654321 | 4826 | S/ 1,500.00 | Usuario principal de prueba (G1 y Núcleo) |
| Bruno Díaz Mendoza | 912345678 | 7391 | S/ 800.00 | Contacto de Ana |
| Carla Ramos Huamán | 956781234 | 5917 | S/ 50.00 | Saldo bajo |
| Diego Salas Paredes | 998877665 | 3604 | S/ 2,500.00 | Límite diario configurado en S/ 1,000 |
| Elena Vargas Ccori | 923456789 | 8152 | S/ 300.00 | Cuenta bloqueada al reiniciar (para probar desbloqueo) |
| Fabián Rojas Núñez | 934567812 | 6029 | S/ 0.00 | Cuenta cerrada |

### Usuarios de Carga (Pruebas de Rendimiento)
- Celulares **900000001** a **900000500**, todos con PIN **2580** y saldo S/ 3,000.00.
- Dataset determinista generado en `tests/performance/data/usuarios.json`.

---

## 5. API de Soporte para Pruebas

Disponible con `QOLQE_MODO_PRUEBA=1`. No forma parte del producto comercial; existe para garantizar que las pruebas automatizadas sean repetibles e independientes.

| Endpoint | Propósito |
|---|---|
| `POST /api/pruebas/reiniciar` | Restaura todos los datos semilla |
| `GET /api/pruebas/reloj` | Consulta la fecha y hora de la app |
| `PUT /api/pruebas/reloj` | Modifica o adelanta el reloj en memoria |
| `DELETE /api/pruebas/reloj` | Vuelve a la hora real del sistema |
| `GET /api/pruebas/notificaciones?celular=...` | Consulta los SMS simulados enviados a un celular |
| `PUT /api/pruebas/saldo` | Ajusta el saldo disponible de un usuario |
| `POST /api/pruebas/procesar-diario` | Ejecuta el procesamiento diario (recargas y débitos automáticos) |

---

## 6. Estructura Limpia del Repositorio

```text
qolqe/                    # Sistema Bajo Prueba (SUT - FastAPI)
features/                 # Especificaciones BDD en Gherkin (api.feature, web.feature)
tests/
  api/                    # Suite de API con Playwright (71 casos de Recargas)
  e2e/                    # Suite Web E2E con Page Object Model (POM) y regresión visual
  performance/            # Suite de Rendimiento con k6, telemetría y escenarios
docs/                     # Documentación oficial del proyecto
  informe.md              # 📘 Informe Oficial Consolidado (Partes 1, 2 y 3)
  defectos.md             # 🐛 Reporte Detallado de Defectos
  requisitos.md           # 📋 Especificación de Requisitos y Reglas de Negocio
  trazabilidad-recargas.json # 📊 Matriz de Trazabilidad
  historico-karate/       # 📁 Archivo histórico de la Entrega 1 (Karate)
.github/workflows/        # Pipeline CI/CD con 4 Quality Gates
GUIA_COMANDOS.md          # ⚡ Guía Maestra de Comandos de Ejecución
IA.md                     # 🤖 Declaración de Uso de IA
```

## 7. Playwright y agentes MCP

La configuración del servidor MCP de Playwright está en [`.vscode/mcp.json`](.vscode/mcp.json),
y las definiciones de Planner, Generator y Healer están en [`.github/agents/`](.github/agents/).
Consulta [la guía de IA con Playwright](docs/ia-playwright.md) para iniciar el servidor
y probar los agentes. La [guía de automatización](docs/guia-playwright-recargas.md)
describe la ejecución local de las suites web y API.

Los casos E2E del módulo común están en `tests/e2e/comun.spec.js`; las pruebas se
ejecutan con `npm test` o `npm run test:e2e`.
