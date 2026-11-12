// Escenario 1: Prueba de Carga - Hora Punta (100 VUs)
// Alcance: Núcleo Común + Módulo de Recargas (G1)
// Simula 3,000 sesiones por hora (Ley de Little: 100 VUs concurrentes con sesiones de 2 min)

import { htmlReport } from '../k6-reporter.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';
import { BASE_URL, THRESHOLDS, pensar } from '../config.js';
import { login } from '../flujos/auth.js';
import { consultarSaldoYPerfil, consultarMovimientos } from '../flujos/consultas.js';
import { transferir } from '../flujos/transferencias.js';
import { recargar, consultarConfiguracionRecargas, listarMisRecargas } from '../flujos/recargas.js';

// Pool de usuarios de prueba
const usuarios = JSON.parse(open('../data/usuarios.json'));

export const options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp-up a 100 VUs
    { duration: '6m', target: 100 },  // Tráfico sostenido de hora punta (100 VUs)
    { duration: '1m', target: 0 },    // Ramp-down
  ],
  thresholds: THRESHOLDS,
};

export default function () {
  // Asignación determinista de usuario por VU
  const vuIndex = (__VU - 1) % usuarios.length;
  const user = usuarios[vuIndex];

  // Identificadores aislados para evitar colisiones
  const destIndex = (vuIndex + 1) % usuarios.length;
  const destCelular = usuarios[destIndex].celular;
  const recargaCelular = `988${String(user.vu).padStart(6, '0')}`;

  // 1. Inicio de sesión (Núcleo Común)
  const token = login(user.celular, user.pin);
  if (!token) {
    pensar(5, 10);
    return;
  }

  // 2. Realizar 6 operaciones por sesión con think time (10 a 25 s, media 18 s)
  // Distribución enfocada exclusivamente en Núcleo Común + Recargas (G1)
  for (let op = 0; op < 6; op++) {
    pensar(10, 25);

    const suerte = Math.random() * 100;

    if (suerte < 35) {
      // 35%: Consultar saldo y perfil (Núcleo Común)
      consultarSaldoYPerfil(token);
    } else if (suerte < 55) {
      // 20%: Consultar movimientos generales (Núcleo Común)
      consultarMovimientos(token);
    } else if (suerte < 75) {
      // 20%: Transferencia a otro usuario Qolqe (Núcleo Común)
      transferir(token, destCelular, 5.0);
    } else if (suerte < 95) {
      // 20%: Recargar celular (Módulo G1 - Recargas)
      recargar(token, recargaCelular, 10);
    } else {
      // 5%: Catálogo de recargas e historial de recargas (Módulo G1)
      consultarConfiguracionRecargas(token);
      listarMisRecargas(token);
    }
  }

  // Pausa final antes de que la sesión expire o comience una nueva
  pensar(5, 15);
}

export function handleSummary(data) {
  return {
    'tests/performance/resultados/reporte_carga.html': htmlReport(data, {
      title: 'Qolqe Wallet - Reporte de Carga (Núcleo + Recargas G1 | 100 VUs)',
    }),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
