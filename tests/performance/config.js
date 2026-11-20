// Configuración global para pruebas de rendimiento con k6
import { sleep } from 'k6';

export const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8000';

// Umbrales (SLAs / SLOs) definidos según el requerimiento de negocio:
// 1. Consultas e inicio de sesión: 95% < 800 ms
// 2. Operaciones de dinero: 95% < 1.5 s
// 3. Tasa de error global en hora punta: <= 1%
export const THRESHOLDS = {
  'http_req_duration{tipo:consulta}': ['p(95)<800'],
  'http_req_duration{tipo:dinero}': ['p(95)<1500'],
  'http_req_failed': ['rate<=0.01'],
};

// Genera pausas realistas (think time) entre 10 y 25 segundos (media 17.5 - 18 s)
export function pensar(min = 10, max = 25) {
  const duracion = Math.floor(Math.random() * (max - min + 1)) + min;
  sleep(duracion);
}

// Pausa reducida opcional para pruebas rápidas de validación de scripts
export function pensarRapido(min = 1, max = 2) {
  const duracion = Math.random() * (max - min) + min;
  sleep(duracion);
}
