const fs = require('node:fs');
const path = require('node:path');

class TrazabilidadReporter {
  constructor() {
    this.results = [];
  }

  onTestEnd(test, result) {
    if (test.parent.project()?.name === 'setup') return;
    const cp = test.title.match(/CP-WEB-G1-\d+|CP-WEB-COMUN-\d+|CP-G1-\d+|CP-AUTH-\d+|CP-SALUD-\d+/)?.[0];
    this.results.push({
      proyecto: test.parent.project()?.name,
      cp: cp || null,
      titulo: test.title,
      hu: test.title.match(/@HU-G1-\d+(?![\d-])/g) || [],
      reglas: test.title.match(/@R-G1-\d+/g) || [],
      etiquetas: test.title.match(/@[\w-]+/g) || [],
      resultado: result.status,
      duracionMs: result.duration,
      errores: result.errors.map(error => error.message),
      timestamp: new Date().toISOString(),
      pipeline: process.env.GITHUB_RUN_ID
        ? `${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID}`
        : null,
    });
  }

  onEnd() {
    const dir = path.resolve('reportes/playwright');
    fs.mkdirSync(dir, { recursive: true });

    const proyectos = new Set(this.results.map(r => r.proyecto).filter(Boolean));
    if (proyectos.has('api')) {
      fs.writeFileSync(path.join(dir, 'trazabilidad_api.json'), JSON.stringify(this.results, null, 2));
    }
    if (proyectos.has('web')) {
      fs.writeFileSync(path.join(dir, 'trazabilidad_web.json'), JSON.stringify(this.results, null, 2));
    }

    const trazabilidadPath = path.join(dir, 'trazabilidad.json');
    let acumulados = [];
    if (fs.existsSync(trazabilidadPath)) {
      try {
        acumulados = JSON.parse(fs.readFileSync(trazabilidadPath, 'utf-8'));
      } catch {
        acumulados = [];
      }
    }

    // Actualizar o agregar resultados por CP
    const porCp = new Map();
    for (const r of acumulados) {
      if (r.cp) porCp.set(r.cp, r);
    }
    for (const r of this.results) {
      if (r.cp) porCp.set(r.cp, r);
      else porCp.set(r.titulo, r);
    }

    const resultadoFinal = Array.from(porCp.values());
    fs.writeFileSync(trazabilidadPath, JSON.stringify(resultadoFinal, null, 2));

    // Registro en histórico multiejecución
    const historicoPath = path.join(dir, 'trazabilidad_historica.json');
    let historico = [];
    if (fs.existsSync(historicoPath)) {
      try {
        historico = JSON.parse(fs.readFileSync(historicoPath, 'utf-8'));
      } catch {
        historico = [];
      }
    }

    const ejecucion = {
      id: process.env.GITHUB_RUN_ID
        ? `gh-${process.env.GITHUB_RUN_ID}-${process.env.GITHUB_RUN_ATTEMPT || '1'}`
        : `local-${Date.now()}`,
      fecha: new Date().toISOString(),
      commit: process.env.GITHUB_SHA || 'local',
      rama: process.env.GITHUB_REF_NAME || 'actualizacion',
      proyecto: Array.from(proyectos).join(','),
      total: this.results.length,
      pasados: this.results.filter(r => r.resultado === 'passed').length,
      fallados: this.results.filter(r => r.resultado === 'failed').length,
      casos: this.results.map(r => ({ cp: r.cp, titulo: r.titulo, resultado: r.resultado, duracionMs: r.duracionMs })),
    };
    historico.push(ejecucion);
    fs.writeFileSync(historicoPath, JSON.stringify(historico, null, 2));
  }
}

module.exports = TrazabilidadReporter;
