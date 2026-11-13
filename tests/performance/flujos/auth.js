import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../config.js';

/**
 * Inicia sesión para un usuario dado y retorna el access_token JWT.
 * Incluye política de reintentos resiliente ante ráfagas de contención concurrente (500 VUs).
 * @param {string} celular Número de celular del usuario (ej: "900000001")
 * @param {string} pin PIN de 4 dígitos (ej: "2580")
 * @returns {string|null} Token JWT o null si falló
 */
export function login(celular, pin) {
  const payload = JSON.stringify({
    celular: celular,
    pin: pin
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    tags: {
      tipo: 'consulta',
      operacion: 'login'
    }
  };

  // Reintento resiliente ante micro-bloqueos transitorios de SQLite / CPU (especialmente en estrés a 500 VUs)
  let res;
  const maxIntentos = 3;
  for (let intento = 0; intento < maxIntentos; intento++) {
    res = http.post(`${BASE_URL}/api/auth/login`, payload, params);
    if (res.status === 200) {
      break;
    }
    sleep(0.1 * (intento + 1));
  }

  const ok = check(res, {
    'login status 200': (r) => r.status === 200,
    'login tiene access_token': (r) => {
      try {
        return r.json('access_token') !== undefined;
      } catch (e) {
        return false;
      }
    }
  });

  if (ok) {
    return res.json('access_token');
  }
  return null;
}
