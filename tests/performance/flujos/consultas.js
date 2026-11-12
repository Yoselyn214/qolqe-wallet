import http from 'k6/http';
import { check } from 'k6';
import { BASE_URL } from '../config.js';

function headersConAuth(token) {
  return {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/json',
    },
  };
}

/**
 * Consulta de cuenta: Saldo y perfil del usuario autenticado (Núcleo Común)
 */
export function consultarSaldoYPerfil(token) {
  const paramsPerfil = Object.assign({}, headersConAuth(token), {
    tags: { tipo: 'consulta', operacion: 'perfil' },
  });
  const resPerfil = http.get(`${BASE_URL}/api/cuentas/me`, paramsPerfil);

  const paramsSaldo = Object.assign({}, headersConAuth(token), {
    tags: { tipo: 'consulta', operacion: 'saldo' },
  });
  const resSaldo = http.get(`${BASE_URL}/api/cuentas/me/saldo`, paramsSaldo);

  check(resPerfil, { 'perfil status 200': (r) => r.status === 200 });
  check(resSaldo, { 'saldo status 200': (r) => r.status === 200 });
}

/**
 * Historial general: Consultar movimientos paginados (Núcleo Común)
 */
export function consultarMovimientos(token) {
  const params = Object.assign({}, headersConAuth(token), {
    tags: { tipo: 'consulta', operacion: 'movimientos' },
  });
  const res = http.get(`${BASE_URL}/api/movimientos?pagina=1&por_pagina=10`, params);

  check(res, { 'movimientos status 200': (r) => r.status === 200 });
}
