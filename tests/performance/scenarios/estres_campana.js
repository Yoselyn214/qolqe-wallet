// Escenario: Prueba de Estrés y Búsqueda del Breakpoint (Escalamiento 200 -> 300 -> 400 -> 500 VUs)
// Evalúa el límite de capacidad de la plataforma y detecta el punto de degradación o saturación.

import { htmlReport } from '../k6-reporter.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';
import { BASE_URL, THRESHOLDS, pensar } from '../config.js';
import { login } from '../flujos/auth.js';
import { consultarSaldoYPerfil, consultarMovimientos } from '../flujos/consultas.js';
import { transferir } from '../flujos/transferencias.js';
import { recargar, consultarConfiguracionRecargas, listarMisRecargas, obtenerCelularRecarga, MONTOS_VALIDOS_G1 } from '../flujos/recargas.js';

const usuarios = JSON.parse(open('../data/usuarios.json'));

export const options = {
  stages: [
    // Escalón 1: 200 VUs (Doble de hora punta)
    { duration: '1m', target: 200 },
    { duration: '1m', target: 200 },

    // Escalón 2: 300 VUs (Pico oficial de Campaña Quincena Qolqe)
    { duration: '1m', target: 300 },
    { duration: '1m', target: 300 },

    // Escalón 3: 400 VUs (Estrés - 33% por encima de la campaña)
    { duration: '1m', target: 400 },
    { duration: '1m', target: 400 },

    // Escalón 4: 500 VUs (Estrés Máximo - Búsqueda de Breakpoint)
    { duration: '1m', target: 500 },
    { duration: '1m', target: 500 },

    // Recuperación / Cierre
    { duration: '45s', target: 0 },
  ],
  thresholds: THRESHOLDS,
};

export default function () {
  const vuIndex = (__VU - 1) % usuarios.length;
  const user = usuarios[vuIndex];

  const destIndex = (vuIndex + 1) % usuarios.length;
  const destCelular = usuarios[destIndex].celular;

  // 1. Inicio de sesión
  const token = login(user.celular, user.pin);
  if (!token) {
    pensar(5, 10);
    return;
  }

  // 2. Operaciones con think time (10 a 25 s)
  for (let op = 0; op < 6; op++) {
    pensar(10, 25);

    const suerte = Math.random() * 100;

    if (suerte < 35) {
      consultarSaldoYPerfil(token);
    } else if (suerte < 55) {
      consultarMovimientos(token);
    } else if (suerte < 75) {
      transferir(token, destCelular, 5.0);
    } else if (suerte < 95) {
      // Rotación entre 5 destinos frecuentes por VU para no superar 5 recargas/día a ningún número (RN-02)
      const recargaCelular = obtenerCelularRecarga(user.vu, op + __ITER);
      const montoRecarga = MONTOS_VALIDOS_G1[(op + __ITER) % MONTOS_VALIDOS_G1.length];
      recargar(token, recargaCelular, montoRecarga);
    } else {
      consultarConfiguracionRecargas(token);
      listarMisRecargas(token);
    }
  }

  pensar(5, 15);
}

export function handleSummary(data) {
  return {
    'tests/performance/resultados/reporte_estres.html': htmlReport(data, {
      title: 'Qolqe Wallet - Reporte de Estrés (Breakpoint 200-500 VUs)',
    }),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
