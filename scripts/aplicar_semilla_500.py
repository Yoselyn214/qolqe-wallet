import sys
import sqlite3
from pathlib import Path

# Add qolqe to path
sys.path.insert(0, "D:/workspace/PVS/Proyecto/qolqe-wallet")
from qolqe.semilla import reiniciar_datos

print("Ejecutando reiniciar_datos()...")
reiniciar_datos()

db_path = Path("D:/workspace/PVS/Proyecto/qolqe-wallet/datos/qolqe.db")
conn = sqlite3.connect(db_path)
cur = conn.cursor()

u_total = cur.execute("SELECT count(*) FROM usuarios").fetchone()[0]
u_activos = cur.execute("SELECT count(*) FROM usuarios WHERE estado = 'ACTIVA'").fetchone()[0]
saldos = cur.execute("SELECT count(*), min(saldo_cent), max(saldo_cent) FROM cuentas WHERE usuario_id IN (SELECT id FROM usuarios WHERE estado = 'ACTIVA')").fetchone()

print(f"Total usuarios en qolqe.db: {u_total}")
print(f"Usuarios activos: {u_activos}")
print(f"Saldos en centimos: count={saldos[0]}, min={saldos[1]}, max={saldos[2]}")
print(f"Saldos en soles: S/ {saldos[1]/100:.2f} a S/ {saldos[2]/100:.2f}")
conn.close()
