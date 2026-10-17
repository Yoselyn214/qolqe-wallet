#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=2.0.0
JAR="${KARATE_JAR:-$ROOT/.tools/karate-$VERSION.jar}"

command -v java >/dev/null || { echo 'Instala Java 21 o superior.' >&2; exit 1; }
if [[ ! -f "$JAR" ]]; then
  command -v curl >/dev/null || { echo 'Instala curl para descargar Karate.' >&2; exit 1; }
  mkdir -p -- "$(dirname -- "$JAR")"
  curl -fL --retry 2 "https://github.com/karatelabs/karate/releases/download/v$VERSION/karate-$VERSION.jar" -o "$JAR.part"
  mv -- "$JAR.part" "$JAR"
fi

# Un solo hilo: los escenarios de autenticación reinician datos compartidos.
cd "$ROOT/tests/karate"
exec java "-DbaseUrl=${BASE_URL:-http://127.0.0.1:8001}" -jar "$JAR" run \
  --threads 1 --output "$ROOT/reportes/karate" "$@" . "$ROOT/api.feature"
