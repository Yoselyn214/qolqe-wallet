"""Instancia exclusiva con base temporal; nunca reutiliza datos de desarrollo."""
import argparse
import os
import tempfile
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8011)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='qolqe-tests-') as directory:
        os.environ['QOLQE_BD'] = os.path.join(directory, 'pruebas.db')
        os.environ['QOLQE_MODO_PRUEBA'] = '1'
        os.environ['QOLQE_BD_PLANTILLA'] = os.path.join(directory, 'plantilla.db')
        import uvicorn
        uvicorn.run('qolqe.main:app', host='127.0.0.1', port=args.port, workers=1)


if __name__ == '__main__':
    main()
