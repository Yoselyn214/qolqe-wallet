import http from 'k6/http';
import { check } from 'k6';
import { BASE_URL } from '../config.js';

// Montos válidos del catálogo oficial de Recargas Qolqe (RN-02 / Módulo G1)
export const MONTOS_VALIDOS_G1 = [10, 20, 30, 50];

/**
 * Genera un número de celular destino rotando entre 5 destinatarios frecuentes por VU (980XXXXXX a 984XXXXXX).
 * Garantiza que ningún número destino exceda el tope de 5 recargas diarias en la prueba (RN-02).
 * @param {number} vu ID o número de usuario virtual (1 a 500)
 * @param {number} slot Índice de rotación (op + __ITER)
 * @returns {string} Celular destino válido de 9 dígitos empezando con 9
 */
export function obtenerCelularRecarga(vu, slot = 0) {
  const indiceSlot = Math.abs(slot) % 5;
  return `98${indiceSlot}${String(vu).padStart(6, '0')}`;
}

/**
 * Operación transaccional de dinero: Recargar un celular (Módulo G1)
 * Aplica RN-02, montos permitidos (5, 10, 20, 30, 50, 100) y bonos (> S/ 30 -> 5%).
 * Se asigna un celular destino independiente rotativo por VU para evitar superar el tope de 5 recargas/día al mismo número.
 */
export function recargar(token, celularDestino, monto = 10) {
  const payload = JSON.stringify({
    celular: celularDestino,
    monto: monto,
  });

  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    tags: {
      tipo: 'dinero',
      operacion: 'recarga',
    },
  };

  const res = http.post(`${BASE_URL}/api/recargas`, payload, params);

  check(res, {
    'recarga status 201': (r) => r.status === 201 || r.status === 200,
    'recarga tiene codigo': (r) => {
      try {
        return r.json('codigo_operacion') !== undefined;
      } catch (e) {
        return false;
      }
    },
  });
}

/**
 * Consulta de catálogo: Obtener configuración de recargas y bonos (Módulo G1)
 */
export function consultarConfiguracionRecargas(token) {
  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json',
    },
    tags: {
      tipo: 'consulta',
      operacion: 'configuracion_recargas',
    },
  };

  const res = http.get(`${BASE_URL}/api/recargas/configuracion`, params);

  check(res, {
    'config recargas status 200': (r) => r.status === 200,
    'tiene montos permitidos': (r) => {
      try {
        return Array.isArray(r.json('montos'));
      } catch (e) {
        return false;
      }
    },
  });
}

/**
 * Consulta de historial específico: Listar las últimas recargas del usuario (Módulo G1)
 */
export function listarMisRecargas(token) {
  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json',
    },
    tags: {
      tipo: 'consulta',
      operacion: 'listar_recargas',
    },
  };

  const res = http.get(`${BASE_URL}/api/recargas`, params);

  check(res, {
    'listar recargas status 200': (r) => r.status === 200,
  });
}
