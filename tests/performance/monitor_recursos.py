"""Monitor de telemetría de recursos (CPU y Memoria) para Qolqe Wallet.

Basado en la especificación de la entrega (Sección 5: Recursos - CPU y memoria).
Mide el proceso del servidor Qolqe cada segundo y guarda las muestras en un archivo CSV.

Uso:
    python monitor_recursos.py <PID> [archivo_salida.csv]
O sin argumentos (detecta automáticamente el proceso de Qolqe/uvicorn):
    python monitor_recursos.py
"""

import csv
import sys
import time
from pathlib import Path

try:
    import psutil
except ImportError:
    print("Error: psutil no está instalado. Ejecuta: pip install psutil")
    sys.exit(1)


def buscar_pid_qolqe() -> int | None:
    """Busca automáticamente el PID del proceso de Qolqe o uvicorn."""
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            cmdline = " ".join(proc.info['cmdline'] or [])
            if "uvicorn" in cmdline or "qolqe" in cmdline:
                # Evitar coincidir con este mismo script
                if "monitor_recursos.py" not in cmdline:
                    return proc.info['pid']
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return None


def main():
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        pid = int(sys.argv[1])
    else:
        pid = buscar_pid_qolqe()
        if pid is None:
            print("No se encontró automáticamente el proceso de Qolqe.")
            print("Uso: python monitor_recursos.py <PID> [archivo.csv]")
            sys.exit(1)

    archivo_csv = sys.argv[2] if len(sys.argv) > 2 else "recursos.csv"
    ruta_salida = Path(archivo_csv)
    ruta_salida.parent.mkdir(parents=True, exist_ok=True)

    try:
        p = psutil.Process(pid)
    except psutil.NoSuchProcess:
        print(f"Error: No existe el proceso con PID {pid}")
        sys.exit(1)

    print(f"==================================================")
    print(f"  Iniciando monitoreo de telemetría Qolqe Wallet")
    print(f"  PID monitoreado: {pid} ({p.name()})")
    print(f"  Destino CSV:     {ruta_salida.resolve()}")
    print(f"  Presiona Ctrl + C para detener y guardar")
    print(f"==================================================")

    # Inicializar contador de cpu_percent
    p.cpu_percent(interval=None)

    with open(ruta_salida, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["hora", "cpu_%", "memoria_MB"])
        f.flush()

        muestras = 0
        try:
            while True:
                hora = time.strftime("%H:%M:%S")
                cpu = p.cpu_percent(interval=1.0)
                mem = round(p.memory_info().rss / 1e6, 1)

                w.writerow([hora, cpu, mem])
                f.flush()
                muestras += 1

                # Muestra visual en consola cada 5 segundos
                if muestras % 5 == 0:
                    print(f"[{hora}] CPU: {cpu:5.1f}% | Memoria: {mem:6.1f} MB (muestras: {muestras})")

        except KeyboardInterrupt:
            print(f"\nMonitoreo finalizado. {muestras} muestras guardadas en {ruta_salida.name}.")


if __name__ == "__main__":
    main()
