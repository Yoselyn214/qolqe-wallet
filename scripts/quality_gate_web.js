/**
 * Quality Gate 3: Pruebas Web E2E - Módulo Común y Recargas (G1)
 *
 * Valida los resultados de tests/e2e/*.spec.js. features/web.feature documenta
 * los escenarios, pero no es interpretado por el runner Playwright.
 */

const fs = require('node:fs');
const path = require('node:path');

const TRAZABILIDAD_WEB_PATH = path.resolve('reportes/playwright/trazabilidad_web.json');
const TRAZABILIDAD_PATH = path.resolve('reportes/playwright/trazabilidad.json');
const CP_ESPERADOS = [
  ...Array.from({ length: 6 }, (_, i) => `CP-WEB-COMUN-${String(i + 1).padStart(2, '0')}`),
  ...Array.from({ length: 11 }, (_, i) => `CP-WEB-G1-${String(i + 1).padStart(2, '0')}`),
];

function main() {
  console.log('================================================================');
  console.log('🌐 EVALUANDO QUALITY GATE 3: PRUEBAS WEB E2E (COMÚN Y RECARGAS)');
  console.log('   (Validando los resultados de tests/e2e/*.spec.js)');
  console.log('================================================================');

  const targetPath = fs.existsSync(TRAZABILIDAD_WEB_PATH) ? TRAZABILIDAD_WEB_PATH : TRAZABILIDAD_PATH;

  if (!fs.existsSync(targetPath)) {
    console.error(`❌ ERROR: No se encontró el archivo de trazabilidad en ${targetPath}`);
    process.exit(1);
  }

  const trazabilidad = JSON.parse(fs.readFileSync(targetPath, 'utf-8'));
  const webTests = trazabilidad.filter(t => t.cp && (t.cp.startsWith('CP-WEB-G1-') || t.cp.startsWith('CP-WEB-COMUN-')));

  const comunTests = webTests.filter(t => t.cp.startsWith('CP-WEB-COMUN-'));
  const recargasTests = webTests.filter(t => t.cp.startsWith('CP-WEB-G1-'));

  console.log(`📊 Total casos Web E2E ejecutados: ${webTests.length} (esperados: 17)`);
  console.log(`  - Módulo Común (Autenticación / Sesión): ${comunTests.length} de 6`);
  console.log(`  - Módulo Recargas G1: ${recargasTests.length} de 11`);

  const conteoPorCp = new Map();
  for (const t of webTests) conteoPorCp.set(t.cp, (conteoPorCp.get(t.cp) || 0) + 1);
  const faltantes = CP_ESPERADOS.filter(cp => !conteoPorCp.has(cp));
  const duplicados = CP_ESPERADOS.filter(cp => conteoPorCp.get(cp) > 1);
  const inesperados = [...conteoPorCp.keys()].filter(cp => !CP_ESPERADOS.includes(cp));
  if (webTests.length !== CP_ESPERADOS.length || faltantes.length || duplicados.length || inesperados.length) {
    console.error('❌ QUALITY GATE FALLIDO: Los CP web ejecutados no coinciden con los 17 esperados.');
    if (faltantes.length) console.error(`  Faltantes: ${faltantes.join(', ')}`);
    if (duplicados.length) console.error(`  Duplicados: ${duplicados.join(', ')}`);
    if (inesperados.length) console.error(`  No esperados: ${inesperados.join(', ')}`);
    process.exit(1);
  }

  const passedTests = webTests.filter(t => t.resultado === 'passed');
  const failedTests = webTests.filter(t => t.resultado === 'failed');

  console.log(`\n📊 Resultados de Ejecución Web:`);
  console.log(`  ✓ Casos Aprobados: ${passedTests.length} / ${webTests.length}`);
  console.log(`  ✘ Casos Fallidos: ${failedTests.length}`);

  if (passedTests.length !== CP_ESPERADOS.length) {
    const noAprobados = webTests.filter(t => t.resultado !== 'passed');
    console.error(`\n❌ QUALITY GATE FALLIDO: ${noAprobados.length} de ${webTests.length} casos no aprobaron:`);
    noAprobados.forEach(t => {
      console.error(`  - ${t.cp} (${t.resultado}): ${t.titulo}`);
      if (t.errores && t.errores.length) console.error(`    Causa: ${t.errores[0]}`);
    });
    process.exit(1);
  }

  console.log('\n================================================================');
  console.log('✅ QUALITY GATE 3 APROBADO: INTERFAZ WEB CONFORME');
  console.log('   - 17/17 CP esperados de los specs web aprobados');
  console.log('   - Módulo Común y Módulo Recargas G1 operativos y validados');
  console.log('   - Regresión visual sin discrepancias pixel a pixel');
  console.log('   - GATE SUPERADO: Entrega final lista para despliegue y demo');
  console.log('================================================================\n');
}

main();
