import sqlite3
from pathlib import Path

# Paths
base_dir = Path("D:/workspace/PVS/Proyecto/qolqe-wallet")
db_paths = [
    base_dir / "datos" / "qolqe.db",
    base_dir / "datos" / "plantilla_carga.db"
]

saldo_target_cent = 3000 * 100 # 3000 soles = 300,000 centimos

for path in db_paths:
    if not path.exists():
        print(f"No existe: {path}")
        continue
    conn = sqlite3.connect(path)
    cur = conn.cursor()
    # Actualizar cuentas de usuarios que no esten CERRADA
    cur.execute("""
        UPDATE cuentas 
        SET saldo_cent = ?
        WHERE usuario_id IN (
            SELECT id FROM usuarios WHERE estado != 'CERRADA'
        )
    """, (saldo_target_cent,))
    conn.commit()
    
    # Comprobar resultado
    cur.execute("""
        SELECT u.id, u.nombres, u.celular, u.estado, c.saldo_cent
        FROM usuarios u
        JOIN cuentas c ON u.id = c.usuario_id
        WHERE u.estado != 'CERRADA'
    """)
    filas = cur.fetchall()
    total_activos = len(filas)
    con_saldo_correcto = sum(1 for f in filas if f[4] == saldo_target_cent)
    print(f"[{path.name}] Total activos: {total_activos}, con saldo S/ 3000 ({saldo_target_cent} cent): {con_saldo_correcto}")
    
    # Comprobar usuario cerrada (Fabian)
    cur.execute("""
        SELECT u.id, u.nombres, u.estado, c.saldo_cent
        FROM usuarios u
        JOIN cuentas c ON u.id = c.usuario_id
        WHERE u.estado = 'CERRADA'
    """)
    cerradas = cur.fetchall()
    print(f"[{path.name}] Cuentas cerradas: {cerradas}")
    conn.close()
