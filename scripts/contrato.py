"""Schemathesis contra una instancia temporal separada de Playwright."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from urllib.request import Request, urlopen

if sys.platform == 'win32' and hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
BASE = 'http://127.0.0.1:8012'


def solicitar(path, data=None):
    body = json.dumps(data).encode() if data is not None else None
    with urlopen(Request(BASE + path, data=body, headers={'Content-Type': 'application/json'}), timeout=5) as response:
        return json.load(response)


def main():
    report = ROOT / 'reportes/contrato'
    report.mkdir(parents=True, exist_ok=True)
    print('================================================================')
    print('[INFO] EJECUTANDO QUALITY GATE 1: PRUEBAS DE CONTRATO (SCHEMATHESIS)')
    print('================================================================')
    # El servidor se detiene incluso si falla el contrato o se interrumpe la ejecución.
    with tempfile.TemporaryFile() as log:
        server = subprocess.Popen([sys.executable, str(ROOT / 'scripts/servidor_pruebas.py'), '--port', '8012'], cwd=ROOT, stdout=log, stderr=log)
        try:
            for _ in range(120):
                if server.poll() is not None:
                    log.seek(0)
                    raise RuntimeError(log.read().decode())
                try:
                    solicitar('/api/salud')
                    break
                except OSError:
                    time.sleep(1)
            else:
                raise RuntimeError('La API de contrato no inició en 120 segundos')
            solicitar('/api/pruebas/reiniciar', {})
            token = solicitar('/api/auth/login', {'celular': '987654321', 'pin': '4826'})['access_token']
            env = {**os.environ, 'PYTHONIOENCODING': 'utf-8', 'PYTHONUTF8': '1'}
            schemathesis_cmd = [
                sys.executable, '-m', 'schemathesis.cli', 'run', BASE + '/openapi.json',
                '--include-path-regex', '^/api/recargas(?:/.*)?$',
                '--header', 'Authorization: Bearer ' + token,
                '--max-examples', '20', '--seed', '5383',
                '--exclude-checks', 'allow_header_conformance,positive_data_acceptance',
                '--report', 'junit', '--report-junit-path', str(report / 'junit.xml'),
            ]
            exit_code = subprocess.call(schemathesis_cmd, cwd=ROOT, env=env)
            if exit_code == 0:
                print('================================================================')
                print('[OK] QUALITY GATE 1 APROBADO: CONTRATO OPENAPI CONFORME')
                print('   - Operaciones de recargas validadas contra openapi.json')
                print('   - Reporte JUnit guardado en reportes/contrato/junit.xml')
                print('================================================================\n')
            else:
                print('================================================================')
                print(f'[ERROR] QUALITY GATE 1 FALLIDO: Schemathesis reportó violaciones (código {exit_code})')
                print('================================================================\n')
            return exit_code
        finally:
            server.terminate()
            try:
                server.wait(timeout=15)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()


if __name__ == '__main__':
    sys.exit(main())
