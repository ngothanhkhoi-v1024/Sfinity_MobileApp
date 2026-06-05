const fs = require('fs');
const path = require('path');
const root = path.join(process.cwd(), 'src');
function walk(dir) {
  const arr = [];
  for (const name of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, name.name);
    if (name.isDirectory()) arr.push(...walk(p));
    else if (p.endsWith('.ts') || p.endsWith('.tsx')) arr.push(p);
  }
  return arr;
}
const pattern = /t\('([^']+)'\)/g;
const refs = new Set();
for (const f of walk(root)) {
  const txt = fs.readFileSync(f, 'utf8');
  let m;
  while ((m = pattern.exec(txt))) refs.add(m[1]);
}
const text = fs.readFileSync(path.join(process.cwd(), 'src', 'i18n.ts'), 'utf8');
const keys = new Set([...text.matchAll(/'([^']+)':/g)].map(m => m[1]));
const missing = [...refs].filter(k => !keys.has(k)).sort();
console.log('refs', refs.size);
console.log('keys', keys.size);
console.log('missing', missing.length);
missing.forEach(k => console.log(k));
