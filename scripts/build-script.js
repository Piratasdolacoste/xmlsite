const fs = require('fs');
const path = require('path');

const dir = 'constructions';
fs.mkdirSync(dir, { recursive: true });

const allFiles = fs.readdirSync(dir);

// 1) Concatena todos os .lua das construções
const luaFiles = allFiles.filter(f => f.endsWith('.lua')).sort();
const constructionsCode = luaFiles
  .map(f => fs.readFileSync(path.join(dir, f), 'utf8'))
  .join('\n');

const base = fs.readFileSync('script-base.lua', 'utf8');
const final = base.replace('-- CONSTRUCTIONS_HERE --', constructionsCode);
fs.writeFileSync('script-completo.lua', final);

// 2) Gera o index.json com os metadados de cada construção (pra galeria)
const jsonFiles = allFiles.filter(f => f.endsWith('.json') && f !== 'index.json').sort();
const indice = jsonFiles.map(f => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')));
fs.writeFileSync(path.join(dir, 'index.json'), JSON.stringify(indice, null, 2));

console.log(`Script final gerado com ${luaFiles.length} construção(ões).`);
