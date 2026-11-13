// Escenario: Prueba de Pico (Spike Test) - Campaña "Quincena Qolqe"
// Simula un impacto repentino y masivo de 300 VUs para evaluar resiliencia y recuperación del sistema.

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
    { duration: '45s', target: 20 },   // 1. Línea base normal (20 VUs)
    { duration: '30s', target: 300 },  // 2. Pico súbito y violento a 300 VUs
    { duration: '1m30s', target: 300 },// 3. Meseta de impacto de la campaña (300 VUs sostenidos)
    { duration: '30s', target: 20 },   // 4. Caída súbita del pico a 20 VUs
    { duration: '1m', target: 20 },    // 5. Fase de recuperación (validar vuelta a la normalidad)
    { duration: '15s', target: 0 },    // 6. Cierre
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

  // 2. Operaciones con think time
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
    'tests/performance/resultados/reporte_pico.html': htmlReport(data, {
      title: 'Qolqe Wallet - Reporte de Prueba de Pico (Spike 300 VUs)',
    }),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
