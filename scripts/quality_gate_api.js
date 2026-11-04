/**
 * Quality Gate 2: Pruebas de API - Módulo Recargas (G1)
 * 
 * Basado estrictamente en los 71 escenarios de features/api.feature:
 * 1. Cobertura completa del módulo Recargas: 71 casos ejecutados (CP-G1-01 a CP-G1-71).
 * 2. Historias de Usuario: HU-G1-01 a HU-G1-07.
 * 3. Reglas de Negocio: R-G1-01 a R-G1-05.
 * 4. Seguridad en Recargas: @seguridad-recargas (CP-G1-64 a CP-G1-71).
 * 5. Casos aprobados según especificación: 64 casos.
 * 6. Defectos conocidos de Recargas: los únicos 7 fallos permitidos corresponden
 *    a DEF-03, DEF-04 y DEF-05 (documentados en docs/defectos.md).
 * 7. Cero regresiones no documentadas.
 */

const fs = require('node:fs');
const path = require('node:path');

const TRAZABILIDAD_API_PATH = path.resolve('reportes/playwright/trazabilidad_api.json');
const TRAZABILIDAD_PATH = path.resolve('reportes/playwright/trazabilidad.json');

const DEFECTOS_RECARGAS = {
  'CP-G1-19': { defecto: 'DEF-03', desc: 'Bono para S/ 30 exactos no se aplica (manual)' },
  'CP-G1-58': { defecto: 'DEF-03', desc: 'Bono para S/ 30 exactos en programada' },
  'CP-G1-22': { defecto: 'DEF-04', desc: 'Sexta recarga manual al mismo número aceptada' },
  'CP-G1-23': { defecto: 'DEF-04', desc: 'Sexta recarga combinada (programada + manuales) aceptada' },
  'CP-G1-33': { defecto: 'DEF-04', desc: 'Límite alcanzado bloquea/afecta indebidamente' },
  'CP-G1-34': { defecto: 'DEF-04', desc: 'Programada supera cinco recargas manuales' },
  'CP-G1-26': { defecto: 'DEF-05', desc: 'Reanudar programada permite superar el tope de 3 activas' },
};

const HUS_REQUERIDAS = [
  '@HU-G1-01', '@HU-G1-02', '@HU-G1-03', '@HU-G1-04',
  '@HU-G1-05', '@HU-G1-06', '@HU-G1-07',
];

const REGLAS_REQUERIDAS = [
  '@R-G1-01', '@R-G1-02', '@R-G1-03', '@R-G1-04', '@R-G1-05',
];

function main() {
  console.log('================================================================');
  console.log('🔍 EVALUANDO QUALITY GATE 2: PRUEBAS DE API - MÓDULO RECARGAS (G1)');
  console.log('   (Basado en los escenarios de features/api.feature)');
  console.log('================================================================');

  const targetPath = fs.existsSync(TRAZABILIDAD_API_PATH) ? TRAZABILIDAD_API_PATH : TRAZABILIDAD_PATH;

  if (!fs.existsSync(targetPath)) {
    console.error(`❌ ERROR: No se encontró el archivo de trazabilidad en ${targetPath}`);
    process.exit(1);
  }

  const trazabilidad = JSON.parse(fs.readFileSync(targetPath, 'utf-8'));
  // Filtrar exclusivamente los casos del módulo de Recargas (CP-G1-*)
  const recargasTests = trazabilidad.filter(t => t.cp && t.cp.startsWith('CP-G1-'));

  console.log(`📊 Total casos de Recargas (G1) ejecutados: ${recargasTests.length} de 71`);

  if (recargasTests.length < 71) {
    console.error(`❌ QUALITY GATE FALLIDO: Se esperaban 71 casos de Recargas de api.feature, pero se ejecutaron ${recargasTests.length}`);
    process.exit(1);
  }

  // Cobertura de Historias de Usuario y Reglas de Negocio
  const hus = new Set();
  const reglas = new Set();
  let seguridadCount = 0;

  for (const t of recargasTests) {
    (t.hu || []).forEach(h => hus.add(h));
    (t.reglas || []).forEach(r => reglas.add(r));
    if (t.titulo && t.titulo.includes('@seguridad-recargas')) seguridadCount++;
  }

  console.log(`\n📋 Cobertura del Módulo Recargas:`);
  console.log(`  ✓ Historias de Usuario: ${Array.from(hus).sort().join(', ')}`);
  console.log(`  ✓ Reglas de Negocio: ${Array.from(reglas).sort().join(', ')}`);
  console.log(`  ✓ Seguridad y Control de Acceso: ${seguridadCount} casos (@seguridad-recargas)`);

  for (const hu of HUS_REQUERIDAS) {
    if (!hus.has(hu)) {
      console.error(`❌ QUALITY GATE FALLIDO: Falta cobertura para la historia de usuario ${hu}`);
      process.exit(1);
    }
  }

  for (const regla of REGLAS_REQUERIDAS) {
    if (!reglas.has(regla)) {
      console.error(`❌ QUALITY GATE FALLIDO: Falta cobertura para la regla de negocio ${regla}`);
      process.exit(1);
    }
  }

  const passedTests = recargasTests.filter(t => t.resultado === 'passed');
  const failedTests = recargasTests.filter(t => t.resultado === 'failed');

  console.log(`\n📊 Resultados de Ejecución de Recargas:`);
  console.log(`  ✓ Casos Aprobados: ${passedTests.length} (esperados: 64)`);
  console.log(`  ! Casos con Defecto: ${failedTests.length} (esperados: 7)`);

  // Validar fallos contra defectos conocidos de recargas
  const regresiones = [];
  const defectosEncontrados = [];

  for (const failed of failedTests) {
    const cp = failed.cp;
    if (DEFECTOS_RECARGAS[cp]) {
      defectosEncontrados.push({
        cp,
        defecto: DEFECTOS_RECARGAS[cp].defecto,
        desc: DEFECTOS_RECARGAS[cp].desc,
      });
    } else {
      regresiones.push(failed);
    }
  }

  console.log(`\n🔍 Verificación de Defectos Conocidos de Recargas (docs/defectos.md):`);
  defectosEncontrados.forEach(d => {
    console.log(`  ⚠️ [${d.defecto}] ${d.cp}: ${d.desc}`);
  });

  if (regresiones.length > 0) {
    console.error(`\n❌ QUALITY GATE FALLIDO: Se detectaron ${regresiones.length} regresiones inesperadas en Recargas:`);
    regresiones.forEach(r => {
      console.error(`  - ${r.cp}: ${r.titulo}`);
      if (r.errores && r.errores.length) {
        console.error(`    Causa: ${r.errores[0]}`);
      }
    });
    process.exit(1);
  }

  if (passedTests.length < 64) {
    console.error(`\n❌ QUALITY GATE FALLIDO: Casos aprobados (${passedTests.length}) menor al umbral de 64`);
    process.exit(1);
  }

  console.log('\n================================================================');
  console.log('✅ QUALITY GATE 2 APROBADO: MÓDULO RECARGAS (API) CONFORME');
  console.log('   - 71/71 casos de features/api.feature verificados');
  console.log('   - 100% Cobertura de HUs (HU-G1-01 a 07) y Reglas (R-G1-01 a 05)');
  console.log(`   - ${passedTests.length} casos aprobados según especificación`);
  console.log(`   - ${defectosEncontrados.length} defectos conocidos verificados sin regresiones`);
  console.log('   - GATE SUPERADO: Autorizada la ejecución de Pruebas Web E2E (features/web.feature)');
  console.log('================================================================\n');
}

main();
