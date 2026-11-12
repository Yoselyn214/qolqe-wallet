// Escenario de Humo (Smoke Test) / Validación Rápida
// Alcance: Núcleo Común + Módulo de Recargas (G1)
// Verifica que todos los flujos funcionen correctamente con 2 VUs antes de pruebas de larga duración.

import { htmlReport } from '../k6-reporter.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';
import { BASE_URL, THRESHOLDS, pensarRapido } from '../config.js';
import { login } from '../flujos/auth.js';
import { consultarSaldoYPerfil, consultarMovimientos } from '../flujos/consultas.js';
import { transferir } from '../flujos/transferencias.js';
import { recargar, consultarConfiguracionRecargas, listarMisRecargas } from '../flujos/recargas.js';

const usuarios = JSON.parse(open('../data/usuarios.json'));

export const options = {
  vus: 2,
  duration: '15s',
  thresholds: THRESHOLDS,
};

export default function () {
  const vuIndex = (__VU - 1) % usuarios.length;
  const user = usuarios[vuIndex];

  const destIndex = (vuIndex + 1) % usuarios.length;
  const destCelular = usuarios[destIndex].celular;
  const recargaCelular = `988${String(user.vu).padStart(6, '0')}`;

  // 1. Login (Núcleo Común)
  const token = login(user.celular, user.pin);
  if (!token) return;

  pensarRapido(0.5, 1);

  // 2. Consultas de Núcleo Común
  consultarSaldoYPerfil(token);
  pensarRapido(0.5, 1);

  consultarMovimientos(token);
  pensarRapido(0.5, 1);

  // 3. Operación transaccional Núcleo Común (Transferencia)
  transferir(token, destCelular, 5.0);
  pensarRapido(0.5, 1);

  // 4. Operaciones del Módulo de Recargas (G1)
  consultarConfiguracionRecargas(token);
  pensarRapido(0.5, 1);

  recargar(token, recargaCelular, 10);
  pensarRapido(0.5, 1);

  listarMisRecargas(token);
  pensarRapido(0.5, 1);
}

export function handleSummary(data) {
  return {
    'tests/performance/resultados/reporte_humo.html': htmlReport(data, {
      title: 'Qolqe Wallet - Validación de Humo (Núcleo + Recargas G1)',
    }),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
