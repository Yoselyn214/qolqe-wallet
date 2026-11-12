import json
from pathlib import Path

data_dir = Path("D:/workspace/PVS/Proyecto/qolqe-wallet/tests/performance/data")
data_dir.mkdir(parents=True, exist_ok=True)

usuarios = []
for n in range(1, 501):
    usuarios.append({
        "id": 6 + n,
        "vu": n,
        "celular": f"9{n:08d}",
        "pin": "2580",
        "dni": f"7{n:07d}",
        "nombres": f"Usuario Carga {n:03d}"
    })

out_file = data_dir / "usuarios.json"
with open(out_file, "w", encoding="utf-8") as f:
    json.dump(usuarios, f, indent=2, ensure_ascii=False)

print(f"Generado {out_file} con {len(usuarios)} usuarios.")
