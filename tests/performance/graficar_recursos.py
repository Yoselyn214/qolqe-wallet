"""Generador de gráficos de telemetría de CPU y Memoria a partir de los CSVs de k6."""
import csv
import sys
from pathlib import Path
import matplotlib.pyplot as plt

def graficar(csv_path: str, output_png: str, titulo: str = "Telemetría de Recursos - Prueba de Rendimiento"):
    ruta_csv = Path(csv_path)
    if not ruta_csv.exists():
        print(f"Error: no existe {csv_path}")
        return

    horas = []
    cpus = []
    mems = []

    with open(ruta_csv, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            horas.append(row["hora"])
            cpus.append(float(row["cpu_%"]))
            mems.append(float(row["memoria_MB"]))

    if not cpus:
        print("Error: archivo CSV sin datos.")
        return

    indices = list(range(len(cpus)))

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(11, 7), sharex=True)
    fig.patch.set_facecolor('#ffffff')

    # Subplot 1: CPU %
    ax1.plot(indices, cpus, color='#2B6CB0', linewidth=1.5, label='CPU Servidor Qolqe (%)')
    ax1.axhline(y=80, color='#C53030', linestyle='--', linewidth=1.2, label='Límite Invalidez Local (80%)')
    avg_cpu = sum(cpus) / len(cpus)
    ax1.axhline(y=avg_cpu, color='#276749', linestyle=':', linewidth=1.2, label=f'Promedio CPU ({avg_cpu:.1f}%)')
    ax1.set_ylabel('Uso de CPU (%)', fontsize=11, fontweight='bold', color='#1A365D')
    ax1.set_title(titulo, fontsize=13, fontweight='bold', color='#1A365D', pad=12)
    ax1.grid(True, linestyle='--', alpha=0.6)
    ax1.legend(loc='upper right', framealpha=0.9)
    ax1.set_ylim(0, max(max(cpus) + 10, 90))

    # Subplot 2: Memoria MB
    ax2.plot(indices, mems, color='#6B46C1', linewidth=1.5, label='Memoria RAM RSS (MB)')
    avg_mem = sum(mems) / len(mems)
    ax2.axhline(y=avg_mem, color='#D69E2E', linestyle=':', linewidth=1.2, label=f'Promedio Memoria ({avg_mem:.1f} MB)')
    ax2.set_ylabel('Memoria RSS (MB)', fontsize=11, fontweight='bold', color='#1A365D')
    ax2.set_xlabel('Muestras temporales (1 muestra / segundo)', fontsize=11, fontweight='bold', color='#1A365D')
    ax2.grid(True, linestyle='--', alpha=0.6)
    ax2.legend(loc='upper left', framealpha=0.9)

    # Reducir etiquetas del eje X
    paso = max(1, len(horas) // 10)
    ax2.set_xticks(indices[::paso])
    ax2.set_xticklabels(horas[::paso], rotation=45, ha='right', fontsize=9)

    plt.tight_layout()
    ruta_png = Path(output_png)
    ruta_png.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(ruta_png, dpi=200)
    plt.close()
    print(f"Gráfico generado exitosamente en: {ruta_png.resolve()}")

if __name__ == "__main__":
    csv_file = sys.argv[1] if len(sys.argv) > 1 else "D:/workspace/PVS/Proyecto/qolqe-wallet/tests/performance/resultados/recursos_carga.csv"
    png_file = sys.argv[2] if len(sys.argv) > 2 else "D:/workspace/PVS/Proyecto/qolqe-wallet/tests/performance/resultados/grafico_carga_recursos.png"
    titulo = sys.argv[3] if len(sys.argv) > 3 else "Qolqe Wallet - Telemetría de Recursos (Hora Punta 100 VUs)"
    graficar(csv_file, png_file, titulo)
