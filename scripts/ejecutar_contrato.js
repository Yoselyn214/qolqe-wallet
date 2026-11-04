const { spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const venvPy = path.resolve('.venv/Scripts/python.exe');
const pythonCmd = process.env.QOLQE_PYTHON || (process.platform === 'win32' && fs.existsSync(venvPy) ? venvPy : 'python');

const scriptPath = path.resolve(__dirname, 'contrato.py');
const child = spawn(pythonCmd, [scriptPath], { stdio: 'inherit' });

child.on('exit', (code) => {
  process.exit(code || 0);
});
