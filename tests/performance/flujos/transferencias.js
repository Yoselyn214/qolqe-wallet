import http from 'k6/http';
import { check } from 'k6';
import { BASE_URL } from '../config.js';

/**
 * 15% del volumen: Transferir a otro usuario Qolqe
 * @param {string} token JWT del usuario emisor
 * @param {string} celularDestino Celular del destinatario
 * @param {number} monto Monto en soles (por defecto S/ 5.00)
 */
export function transferir(token, celularDestino, monto = 5.0) {
  const payload = JSON.stringify({
    tipo: 'QOLQE',
    celular_destino: celularDestino,
    monto: monto,
    descripcion: 'Prueba de rendimiento k6'
  });

  const params = {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    tags: {
      tipo: 'dinero',
      operacion: 'transferencia'
    }
  };

  const res = http.post(`${BASE_URL}/api/transferencias`, payload, params);

  check(res, {
    'transferencia status 201': (r) => r.status === 201 || r.status === 200,
    'transferencia tiene codigo': (r) => {
      try {
        return r.json('codigo_operacion') !== undefined;
      } catch (e) {
        return false;
      }
    }
  });
}
