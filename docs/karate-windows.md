# Ejecutar Karate en Windows con PowerShell

Esta guía ejecuta los mismos archivos de pruebas del proyecto desde PowerShell,
sin Bash, WSL ni Maven. Usa dos terminales: una para la API y otra para Karate.
Ejecuta los comandos desde la carpeta raíz del proyecto (`qolqe-wallet`).

## 1. Requisitos

- Python 3.11 o superior (el proyecto recomienda 3.12).
- Java 21 o superior, disponible en el PATH.
- PowerShell y conexión a Internet para descargar Karate la primera vez.

Comprueba la instalación:

```powershell
py --version
java -version
```

Si alguno no se reconoce, instala la herramienta correspondiente y vuelve a abrir
la terminal. Si Python está disponible como `python` en lugar de `py`, sustituye
`py` por `python` en el siguiente paso.

## 2. Preparar Python y descargar Karate

Desde la raíz del proyecto:

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt

New-Item -ItemType Directory -Force .tools | Out-Null
Invoke-WebRequest -Uri "https://github.com/karatelabs/karate/releases/download/v2.0.0/karate-2.0.0.jar" -OutFile ".tools\karate-2.0.0.jar"
```

Estos pasos se hacen una vez. Se llama directamente al Python del entorno para
evitar tener que activar scripts de PowerShell. Si ya tienes un entorno `env`,
puedes usar `.\env\Scripts\python.exe` en lugar de crear `.venv`.
No copies el entorno virtual de Linux: créalo de nuevo en Windows.

## 3. Terminal 1: iniciar una API dedicada a las pruebas

Desde la raíz del proyecto:

```powershell
New-Item -ItemType Directory -Force datos | Out-Null
$env:QOLQE_BD = Join-Path (Get-Location).Path "datos\karate-windows.db"
$env:QOLQE_MODO_PRUEBA = "1"
.\.venv\Scripts\python.exe -m uvicorn qolqe.main:app --host 127.0.0.1 --port 8001
```

Espera a que aparezca `Application startup complete` y deja esta terminal abierta.
Usa un solo proceso, sin `--workers`.

**Las pruebas de autenticación y recargas reinician toda la base de la API.**
El comando anterior utiliza `datos\karate-windows.db`, separada de la base
habitual. No ejecutes otras suites contra esta instancia al mismo tiempo.
Esta base permanece en disco al terminar; no es temporal.

## 4. Terminal 2: ejecutar Karate

Abre otra terminal PowerShell en la raíz del mismo proyecto:

```powershell
$raiz = (Get-Location).Path
$jar = Join-Path $raiz ".tools\karate-2.0.0.jar"
$reporte = Join-Path $raiz "reportes\karate"
$feature = Join-Path $raiz "api.feature"
Set-Location (Join-Path $raiz "tests\karate")
```

Solo las pruebas de recargas:

```powershell
java "-DbaseUrl=http://127.0.0.1:8001" -jar "$jar" run --threads 1 --output "$reporte" --tags @recargas . "$feature"
```

Toda la suite (salud, autenticación y recargas):

```powershell
java "-DbaseUrl=http://127.0.0.1:8001" -jar "$jar" run --threads 1 --output "$reporte" . "$feature"
```

Ejecutar una regla o buscar un escenario por nombre:

```powershell
java "-DbaseUrl=http://127.0.0.1:8001" -jar "$jar" run --threads 1 --output "$reporte" --tags @R-G1-02 . "$feature"
java "-DbaseUrl=http://127.0.0.1:8001" -jar "$jar" run --threads 1 --output "$reporte" --tags @recargas --name "Saldo insuficiente" . "$feature"
```

Se ejecuta desde `tests\karate` para usar `karate-config.js`. El argumento `.`
incluye las pruebas de esa carpeta y `$feature` incluye el `api.feature` de la
raíz. Mantén `--threads 1`: los escenarios comparten reloj y base de datos.

## 5. Abrir el reporte y detener la API

En la terminal 2:

```powershell
Start-Process (Join-Path $reporte "karate-summary.html")
Set-Location $raiz
```

Para detener la API, presiona `Ctrl+C` en la terminal 1.

Si hay escenarios fallidos, Karate termina con un código distinto de cero.
Eso también puede indicar un defecto de la aplicación: por ejemplo, recibir
`201` al intentar una sexta recarga cuando se esperaba `422`. Revisa la primera
aserción fallida en el reporte y consulta [defectos.md](defectos.md).

## 6. Problemas frecuentes

| Problema | Qué revisar |
|---|---|
| `java` no se reconoce | Java debe estar instalado y en el PATH; abre una terminal nueva. |
| `UnsupportedClassVersionError` | Comprueba con `java -version` que el Java activo sea 21 o superior. |
| `Unable to access jarfile` | Completa la descarga y ejecuta la preparación de variables desde la raíz del proyecto. |
| Conexión rechazada | La terminal 1 debe seguir abierta, con la API disponible en el puerto 8001. |
| Puerto 8001 ocupado | Detén el proceso que lo usa o cambia el puerto de uvicorn y el valor de `-DbaseUrl` al mismo número. |
| `No module named uvicorn` | Instala `requirements.txt` con el mismo Python del entorno que utilizas para iniciar la API. |
| `bash` no se reconoce al usar `karate_local.py` | Ese script llama a `scripts/karate.sh`; para PowerShell sin Bash, usa los comandos de esta guía. |

El flujo de Linux se mantiene en [guia-karate-recargas.md](guia-karate-recargas.md).
