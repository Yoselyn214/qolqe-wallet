import http from 'k6/http';
import { check } from 'k6';
import { BASE_URL } from '../config.js';

/**
 * Operación transaccional de dinero: Recargar un celular (Módulo G1)
 * Aplica RN-02, montos permitidos (5, 10, 20, 30, 50, 100) y bonos (> S/ 30 -> 5%).
 * Se asigna un celular destino independiente por VU para evitar superar el tope de 5 recargas/día al mismo número.
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
