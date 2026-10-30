const fs = require('node:fs');
class TrazabilidadReporter {
  constructor() { this.results = []; }
  onTestEnd(test, result) {
    this.results.push({
      proyecto: test.parent.project()?.name,
      cp: test.title.match(/CP-WEB-G1-\d+|CP-G1-\d+|CP-AUTH-\d+|CP-SALUD-\d+/)?.[0],
      titulo: test.title,
      hu: test.title.match(/@HU-G1-\d+(?![\d-])/g) || [],
      reglas: test.title.match(/@R-G1-\d+/g) || [],
      resultado: result.status,
      duracionMs: result.duration,
      errores: result.errors.map(error => error.message),
      pipeline: process.env.GITHUB_RUN_ID ? `${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID}` : null,
    });
  }
  onEnd() {
    fs.mkdirSync('reportes/playwright', { recursive: true });
    fs.writeFileSync('reportes/playwright/trazabilidad.json', JSON.stringify(this.results, null, 2));
  }
}
module.exports = TrazabilidadReporter;
