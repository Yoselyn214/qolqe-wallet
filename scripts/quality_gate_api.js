/**
 * Quality Gate para Pruebas de API de Qolqe Wallet
 * 
 * Evalúa los resultados generados en reportes/playwright/trazabilidad.json:
 * 1. Cobertura completa de casos técnicos y funcionales de API (76 casos esperados).
 * 2. Casos técnicos: Salud (@smoke), Autenticación (@auth), Control de acceso (@seguridad-recargas).
 * 3. Casos funcionales: Historias de usuario (HU-G1-01 a HU-G1-07), Reglas de negocio (R-G1-01 a R-G1-05).
 * 4. Verificación de defectos conocidos: los únicos casos fallidos permitidos son los 8 defectos documentados
 *    en docs/defectos.md (DEF-02, DEF-03, DEF-04, DEF-05).
 * 5. Cero regresiones no identificadas.
 */

const fs = require('node:fs');
const path = require('node:path');

const TRAZABILIDAD_PATH = path.resolve('reportes/playwright/trazabilidad.json');

const DEFECTOS_CONOCIDOS = {
  'CP-AUTH-04': { defecto: 'DEF-02', desc: 'Logout no invalida token de acceso' },
  'CP-G1-19': { defecto: 'DEF-03', desc: 'Bono para S/ 30 exactos no se aplica' },
  'CP-G1-58': { defecto: 'DEF-03', desc: 'Bono para S/ 30 exactos en programada' },
  'CP-G1-22': { defecto: 'DEF-04', desc: 'Sexta recarga manual aceptada' },
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
  console.log('🔍 EVALUANDO QUALITY GATE: PRUEBAS DE API (FUNCIONALES Y TÉCNICAS)');
  console.log('================================================================');

  if (!fs.existsSync(TRAZABILIDAD_PATH)) {
    console.error(`❌ ERROR: No se encontró el archivo de trazabilidad en ${TRAZABILIDAD_PATH}`);
    process.exit(1);
  }

  const trazabilidad = JSON.parse(fs.readFileSync(TRAZABILIDAD_PATH, 'utf-8'));
  const apiTests = trazabilidad.filter(t => t.proyecto === 'api' || !t.proyecto);

  console.log(`📊 Total casos de API ejecutados: ${apiTests.length}`);

  if (apiTests.length < 76) {
    console.error(`❌ QUALITY GATE FALLIDO: Se esperaban 76 casos de API, pero se ejecutaron ${apiTests.length}`);
    process.exit(1);
  }

  // Cobertura técnica y funcional
  const hus = new Set();
  const reglas = new Set();
  let smokeCount = 0;
  let authCount = 0;
  let seguridadCount = 0;

  for (const t of apiTests) {
    (t.hu || []).forEach(h => hus.add(h));
    (t.reglas || []).forEach(r => reglas.add(r));
    if (t.titulo.includes('@smoke')) smokeCount++;
    if (t.titulo.includes('@auth')) authCount++;
    if (t.titulo.includes('@seguridad-recargas')) seguridadCount++;
  }

  console.log(`\n📋 Cobertura Técnica:`);
  console.log(`  ✓ Salud de API (@smoke): ${smokeCount} caso(s)`);
  console.log(`  ✓ Autenticación (@auth): ${authCount} caso(s)`);
  console.log(`  ✓ Seguridad y Control de Acceso (@seguridad-recargas): ${seguridadCount} caso(s)`);

  console.log(`\n📋 Cobertura Funcional:`);
  console.log(`  ✓ Historias de Usuario: ${Array.from(hus).sort().join(', ')}`);
  console.log(`  ✓ Reglas de Negocio: ${Array.from(reglas).sort().join(', ')}`);

  // Validar presencia de todas las HUs y reglas requeridas
  for (const hu of HUS_REQUERIDAS) {
    if (!hus.has(hu)) {
      console.error(`❌ QUALITY GATE FALLIDO: Falta cobertura para ${hu}`);
      process.exit(1);
    }
  }

  for (const regla of REGLAS_REQUERIDAS) {
    if (!reglas.has(regla)) {
      console.error(`❌ QUALITY GATE FALLIDO: Falta cobertura para ${regla}`);
      process.exit(1);
    }
  }

  const passedTests = apiTests.filter(t => t.resultado === 'passed');
  const failedTests = apiTests.filter(t => t.resultado === 'failed');

  console.log(`\n📊 Resultados de Ejecución:`);
  console.log(`  ✓ Casos Aprobados: ${passedTests.length}`);
  console.log(`  ! Casos Fallidos: ${failedTests.length}`);

  // Validar fallos contra matriz de defectos conocidos
  const regresiones = [];
  const defectosEncontrados = [];

  for (const failed of failedTests) {
    const cp = failed.cp;
    if (DEFECTOS_CONOCIDOS[cp]) {
      defectosEncontrados.push({
        cp,
        defecto: DEFECTOS_CONOCIDOS[cp].defecto,
        desc: DEFECTOS_CONOCIDOS[cp].desc,
      });
    } else {
      regresiones.push(failed);
    }
  }

  console.log(`\n🔍 Verificación de Defectos Conocidos (docs/defectos.md):`);
  defectosEncontrados.forEach(d => {
    console.log(`  ⚠️ [${d.defecto}] ${d.cp}: ${d.desc}`);
  });

  if (regresiones.length > 0) {
    console.error(`\n❌ QUALITY GATE FALLIDO: Se detectaron ${regresiones.length} regresiones inesperadas:`);
    regresiones.forEach(r => {
      console.error(`  - ${r.cp}: ${r.titulo}`);
      if (r.errores && r.errores.length) {
        console.error(`    Causa: ${r.errores[0]}`);
      }
    });
    process.exit(1);
  }

  if (passedTests.length < 68) {
    console.error(`\n❌ QUALITY GATE FALLIDO: Aprobados (${passedTests.length}) menor al umbral de 68`);
    process.exit(1);
  }

  console.log('\n================================================================');
  console.log('✅ QUALITY GATE APROBADO: SUITE DE APIS CONFORME');
  console.log('   - Cobertura completa de casos funcionales y técnicos (76/76)');
  console.log(`   - ${passedTests.length} casos aprobados según especificación`);
  console.log(`   - ${defectosEncontrados.length} defectos conocidos verificados sin regresiones`);
  console.log('   - GATE SUPERADO: Autorizada la ejecución de Pruebas Web E2E');
  console.log('================================================================\n');
}

main();
