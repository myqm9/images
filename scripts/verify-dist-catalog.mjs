#!/usr/bin/env node
/**
 * Post-build sanity check: catalog page must be generated from release.json,
 * not left as a raw HTML comment placeholder.
 */
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const htmlPath = join(root, 'astro/dist/middleware/index.html');
const releasePath = join(root, 'astro/src/data/releases/release.json');

if (!existsSync(htmlPath)) {
  console.error('missing', htmlPath);
  process.exit(1);
}

const html = readFileSync(htmlPath, 'utf8');
const releases = JSON.parse(readFileSync(releasePath, 'utf8'));
const note = releases.clickhouse?.versions?.[0]?.note;
const failures = [];

if (!html.includes('catalog-cell--note')) {
  failures.push('catalog table was not rendered (no catalog-cell--note)');
}
if (/<!--\s*middleware-catalog/.test(html)) {
  failures.push('catalog placeholder comment still present in dist HTML');
}
if (note && !html.includes(note)) {
  failures.push(`clickhouse note missing from dist: ${note}`);
}
for (const [component, version] of [
  ['emqx', '5.8.9'],
  ['mysql', '8.0.38'],
  ['influxdb', '3.9.0'],
]) {
  const redirect = join(root, 'astro/dist/middleware', component, 'index.html');
  if (!existsSync(redirect)) failures.push(`missing redirect page /middleware/${component}/`);
  const page = join(root, 'astro/dist/middleware', component, version, 'index.html');
  if (!existsSync(page)) failures.push(`missing version page /middleware/${component}/${version}/`);
}

if (failures.length) {
  console.error('verify-dist-catalog failed:');
  for (const item of failures) console.error(' -', item);
  process.exit(1);
}

console.log('verify-dist-catalog: ok');
