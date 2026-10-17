"""Ejecuta Karate contra una API propia con base temporal y un solo proceso."""
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import time
from urllib.error import URLError
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parent.parent


def main():
    with tempfile.TemporaryDirectory(prefix="qolqe-karate-") as directory:
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        base_url = f"http://127.0.0.1:{port}"
        environment = {
            **os.environ,
            "QOLQE_BD": str(Path(directory) / "qolqe.db"),
            "QOLQE_MODO_PRUEBA": "1",
            "BASE_URL": base_url,
        }
        with open(Path(directory) / "api.log", "w+") as log:
            server = subprocess.Popen(
                [sys.executable, "-m", "uvicorn", "qolqe.main:app",
                 "--host", "127.0.0.1", "--port", str(port)],
                cwd=ROOT, env=environment, stdout=log, stderr=subprocess.STDOUT,
            )
            try:
                deadline = time.monotonic() + 120
                while time.monotonic() < deadline:
                    if server.poll() is not None:
                        raise RuntimeError("La API de pruebas terminó antes de iniciar")
                    try:
                        with urlopen(base_url + "/api/salud", timeout=1) as response:
                            if response.status == 200:
                                break
                    except (URLError, TimeoutError):
                        pass
                    time.sleep(0.2)
                else:
                    raise RuntimeError("La API no inició en 120 segundos")
                print(f"API aislada lista en {base_url}; base de datos temporal", flush=True)
                return subprocess.call(
                    ["bash", "scripts/karate.sh", *sys.argv[1:]],
                    cwd=ROOT, env=environment,
                )
            except RuntimeError as error:
                log.seek(0)
                print(f"{error}\n{log.read()}", file=sys.stderr)
                return 1
            finally:
                if server.poll() is None:
                    server.terminate()
                    try:
                        server.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        server.kill()
                        server.wait()


if __name__ == "__main__":
    raise SystemExit(main())
