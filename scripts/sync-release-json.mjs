#!/usr/bin/env node
/**
 * Sync README.md middleware / ops tables → astro/src/data/releases/release.json
 *
 * README owns: component list, version rows, image refs, ports, notes, labels.
 * release.json keeps: catalog.status, catalog.order, catalog.section, and the
 * default `version` when that id still exists after sync.
 *
 * Usage:
 *   node scripts/sync-release-json.mjs           # write JSON
 *   node scripts/sync-release-json.mjs --check   # exit 1 if drift
 *   node scripts/sync-release-json.mjs --dry-run # print JSON only
 */

import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, utimesSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const readmePath = join(root, 'README.md');
const releasePath = join(root, 'astro/src/data/releases/release.json');
const catalogPagePath = join(root, 'astro/docs/middleware.md');

const args = new Set(process.argv.slice(2));
const checkOnly = args.has('--check');
const dryRun = args.has('--dry-run');

function splitCells(line) {
  const trimmed = line.trim().replace(/^\|/, '').replace(/\|$/, '');
  return trimmed.split('|').map((cell) => cell.trim());
}

function isSeparator(line) {
  return /^\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)+\|?\s*$/.test(line.trim());
}

function extractTables(markdown) {
  const lines = markdown.split(/\r?\n/);
  const tables = [];
  let section = 'middleware';
  let i = 0;
  while (i < lines.length) {
    const heading = lines[i].match(/^#\s+\**(.+?)\**\s*$/);
    if (heading) {
      const title = heading[1].replace(/\*/g, '').trim();
      if (/运维/.test(title)) section = 'ops';
      else if (/中间件/.test(title)) section = 'middleware';
    }
    if (lines[i].includes('|') && i + 1 < lines.length && isSeparator(lines[i + 1])) {
      const header = splitCells(lines[i]).map((h) => h.replace(/\*/g, '').trim());
      i += 2;
      const rows = [];
      while (i < lines.length && lines[i].includes('|') && !isSeparator(lines[i])) {
        if (!lines[i].trim().startsWith('|')) break;
        rows.push(splitCells(lines[i]));
        i += 1;
      }
      tables.push({ section, header, rows });
      continue;
    }
    i += 1;
  }
  return tables;
}

function columnIndex(header, names) {
  for (const name of names) {
    const exact = header.findIndex((h) => h === name);
    if (exact >= 0) return exact;
  }
  for (const name of names) {
    // Avoid matching 「说明」 against 「镜像说明」.
    const fuzzy = header.findIndex((h) => h !== name && h.includes(name) && !(name === '说明' && h.includes('镜像')));
    if (fuzzy >= 0) return fuzzy;
  }
  return -1;
}

function cleanNote(value) {
  const note = String(value ?? '').trim();
  if (!note) return undefined;
  if (/^(amd64|arm64|官方镜像)$/i.test(note)) return undefined;
  return note;
}

function splitTokens(value) {
  return String(value ?? '')
    .split(/\s+/)
    .map((part) => part.trim())
    .filter(Boolean);
}

function splitPorts(value) {
  return splitTokens(value);
}

function architectureOf(archCell, reference) {
  const cell = String(archCell ?? '').toLowerCase();
  if (cell.includes('arm64')) return 'arm64';
  if (cell.includes('amd64')) return 'amd64';
  if (/:.*arm64(?:$|-)/i.test(reference) || /-arm64(?:$|:)/i.test(reference)) return 'arm64';
  return 'amd64';
}

function componentKey(name) {
  return String(name).trim().toLowerCase().replace(/\s+/g, '-');
}

function imageTag(reference) {
  const slash = reference.lastIndexOf('/');
  const name = slash >= 0 ? reference.slice(slash + 1) : reference;
  const colon = name.indexOf(':');
  return colon >= 0 ? name.slice(colon + 1) : name;
}

function imageRepoName(reference) {
  const slash = reference.lastIndexOf('/');
  const name = slash >= 0 ? reference.slice(slash + 1) : reference;
  const colon = name.indexOf(':');
  return colon >= 0 ? name.slice(0, colon) : name;
}

function apolloServiceKey(reference) {
  const repo = imageRepoName(reference).replace(/^apollo-?/, '');
  if (repo.includes('portal')) return 'portal';
  if (repo.includes('config')) return 'configservice';
  if (repo.includes('admin')) return 'adminservice';
  return repo || 'service';
}

function buildArchImages(component, references) {
  if (component === 'apollo') {
    const images = {};
    for (const reference of references) {
      images[apolloServiceKey(reference)] = { reference };
    }
    return images;
  }
  if (references.length === 1) return { reference: references[0] };
  if (references.length === 0) return undefined;
  return { reference: references[0], extras: references.slice(1) };
}

function normalizeVersionId(component, versionCell, amd64Refs) {
  const cell = String(versionCell ?? '').trim();
  const primary = amd64Refs[0];

  if (component === 'geoserver' && primary) {
    return {
      id: imageTag(primary).replace(/^geoserver=/i, '') || imageTag(primary),
      label: cell && cell !== imageTag(primary) ? cell : undefined,
    };
  }

  if (component === 'nacos') {
    const cleaned = cell.replace(/\s+/g, '');
    if (primary && imageTag(primary)) return { id: imageTag(primary) };
    return { id: cleaned };
  }

  if (component === 'mongo') {
    if (primary) return { id: primary.includes(':') ? primary : `mongo:${primary}` };
    return { id: cell };
  }

  if (primary && cell && !/^\d/.test(cell) && cell.includes('=') === false && cell.includes(' ') === false) {
    // e.g. openjdk v11_0_23-jdk-ubi9-x86 — keep README version when it matches amd64 tag shape
    if (cell === imageTag(primary) || cell === primary) return { id: cell };
  }

  if (primary && (/geoserver=/i.test(cell) || /\s/.test(cell) && /tomcat/i.test(cell))) {
    return { id: imageTag(primary), label: cell };
  }

  return { id: cell || (primary ? imageTag(primary) : 'unknown') };
}

function expandMysqlStyleVersions(versionCell, imageCell, ports, note) {
  const versions = splitTokens(versionCell);
  const images = splitTokens(imageCell);
  if (versions.length <= 1 || images.length <= 1) return null;
  if (versions.length !== images.length) {
    throw new Error(`mysql-style row mismatch: versions=${versions.join(',')} images=${images.join(',')}`);
  }
  return versions.map((id, index) => ({
    id,
    ports: splitPorts(ports),
    note: note || undefined,
    images: {
      amd64: { reference: images[index] },
      arm64: { reference: images[index] },
    },
  }));
}

function parseReadme(markdown) {
  const warnings = [];
  const components = new Map();
  let order = 0;

  for (const table of extractTables(markdown)) {
    const { header, rows, section } = table;
    const iName = columnIndex(header, ['软件']);
    const iVersion = columnIndex(header, ['版本']);
    const iArch = columnIndex(header, ['镜像说明']);
    const iImage = columnIndex(header, ['镜像地址']);
    const iPorts = columnIndex(header, ['端口']);
    const iNote = columnIndex(header, ['说明']);
    if (iName < 0 || iVersion < 0 || iImage < 0) {
      warnings.push(`skip table with unexpected header: ${header.join(' | ')}`);
      continue;
    }

    let currentKey = null;
    let currentLabel = null;

    for (const row of rows) {
      const nameCell = row[iName] ?? '';
      const versionCell = row[iVersion] ?? '';
      const archCell = row[iArch] ?? '';
      const imageCell = row[iImage] ?? '';
      const portsCell = row[iPorts] ?? '';
      const noteCell = cleanNote(row[iNote] ?? '');

      if (nameCell) {
        currentKey = componentKey(nameCell);
        currentLabel = nameCell.trim();
        if (!components.has(currentKey)) {
          order += 1;
          components.set(currentKey, {
            key: currentKey,
            label: currentLabel,
            section: section === 'ops' ? 'ops' : undefined,
            order,
            versionBlocks: [],
          });
        }
      }
      if (!currentKey) continue;

      const refs = splitTokens(imageCell);
      if (!refs.length && !versionCell) continue;

      const expanded = expandMysqlStyleVersions(versionCell, imageCell, portsCell, noteCell);
      if (expanded) {
        const entry = components.get(currentKey);
        for (const item of expanded) {
          if (!item.note) delete item.note;
          entry.versionBlocks.push(item);
        }
        continue;
      }

      const entry = components.get(currentKey);
      const arch = architectureOf(archCell, refs[0] ?? '');
      let block = entry.versionBlocks[entry.versionBlocks.length - 1];
      const startsVersion = Boolean(versionCell);

      if (startsVersion || !block) {
        const amd64Guess = arch === 'amd64' ? refs : [];
        const { id, label } = normalizeVersionId(currentKey, versionCell || block?.id, amd64Guess.length ? amd64Guess : refs);
        block = {
          id,
          label,
          ports: splitPorts(portsCell),
          note: noteCell,
          images: { amd64: undefined, arm64: undefined },
        };
        entry.versionBlocks.push(block);
      } else {
        if (portsCell && !block.ports.length) block.ports = splitPorts(portsCell);
        if (noteCell && !block.note) block.note = noteCell;
      }

      if (!refs.length) continue;
      const packed = buildArchImages(currentKey, refs);
      if (arch === 'arm64') block.images.arm64 = packed;
      else block.images.amd64 = packed;

      // Official single-arch row: mirror to arm64 when only one official image listed.
      if (/官方/.test(archCell) && block.images.amd64 && !block.images.arm64) {
        block.images.arm64 = structuredClone(block.images.amd64);
      }

      // Recompute id once amd64 image is known (geoserver / nacos).
      if (block.images.amd64) {
        const refsForId = currentKey === 'apollo'
          ? Object.values(block.images.amd64).map((item) => item.reference)
          : [block.images.amd64.reference];
        const normalized = normalizeVersionId(currentKey, versionCell || block.label || block.id, refsForId);
        if (normalized.id) block.id = normalized.id;
        if (normalized.label) block.label = normalized.label;
      }
    }
  }

  return { components, warnings };
}

function finalizeVersion(block) {
  const images = {};
  if (block.images.amd64) images.amd64 = block.images.amd64;
  if (block.images.arm64) images.arm64 = block.images.arm64;
  const entry = { id: block.id };
  if (block.label) entry.label = block.label;
  entry.ports = block.ports ?? [];
  if (block.note) entry.note = block.note;
  entry.images = images;
  return entry;
}

function sameImages(left, right) {
  return JSON.stringify(left ?? null) === JSON.stringify(right ?? null);
}

function pickDefaultVersion(prev, versions) {
  if (versions.some((item) => item.id === prev.version)) return prev.version;
  if (prev.version && versions.some((item) => sameImages(item.images, prev.images))) return prev.version;
  return versions.at(-1).id;
}

function mergeReleases(parsed, existing) {
  const next = {};
  let maxOrder = Math.max(0, ...Object.values(existing).map((item) => item.catalog?.order ?? 0));

  for (const component of parsed.components.values()) {
    const prev = existing[component.key] ?? {};
    const versions = component.versionBlocks.map(finalizeVersion);
    if (!versions.length) continue;

    const defaultVersion = pickDefaultVersion(prev, versions);
    const defaultEntry = versions.find((item) => item.id === defaultVersion)
      ?? versions.find((item) => sameImages(item.images, prev.images))
      ?? versions.at(-1);

    const order = prev.catalog?.order ?? (++maxOrder);
    const status = prev.catalog?.status ?? 'pending';
    const catalog = {
      label: component.label,
      order,
      ports: defaultEntry.ports ?? [],
    };
    if (component.section === 'ops' || prev.catalog?.section === 'ops') catalog.section = 'ops';
    catalog.status = status;

    next[component.key] = {
      version: defaultVersion,
      catalog,
      images: structuredClone(defaultEntry.images),
      versions,
    };
  }

  return next;
}

function stableStringify(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

/** Force Starlight to recompile middleware.md so the catalog table picks up release.json. */
function bustCatalogPage(releaseText) {
  const hash = createHash('sha1').update(releaseText).digest('hex').slice(0, 12);
  const marker = `<!-- middleware-catalog bust=${hash} -->`;
  let page = readFileSync(catalogPagePath, 'utf8');
  if (page.includes(marker)) {
    const now = new Date();
    utimesSync(catalogPagePath, now, now);
    return;
  }
  if (/<!-- middleware-catalog(?:\s+bust=[a-f0-9]+)? -->/.test(page)) {
    page = page.replace(/<!-- middleware-catalog(?:\s+bust=[a-f0-9]+)? -->/, marker);
  } else {
    page = `${page.trimEnd()}\n\n${marker}\n`;
  }
  writeFileSync(catalogPagePath, page);
}

function main() {
  const markdown = readFileSync(readmePath, 'utf8');
  const existing = JSON.parse(readFileSync(releasePath, 'utf8'));
  const parsed = parseReadme(markdown);
  for (const warning of parsed.warnings) console.warn(`warn: ${warning}`);

  const next = mergeReleases(parsed, existing);
  const nextText = stableStringify(next);
  const changed = JSON.stringify(existing) !== JSON.stringify(next);

  if (checkOnly) {
    if (!changed) {
      console.log('release.json is in sync with README.md');
      return;
    }
    console.error('release.json is out of sync with README.md');
    console.error('Run: npm run sync:releases');
    const prevKeys = new Set(Object.keys(existing));
    const nextKeys = new Set(Object.keys(next));
    for (const key of nextKeys) {
      if (!prevKeys.has(key)) console.error(`  + ${key}`);
      else if (JSON.stringify(existing[key]) !== JSON.stringify(next[key])) console.error(`  ~ ${key}`);
    }
    for (const key of prevKeys) {
      if (!nextKeys.has(key)) console.error(`  - ${key}`);
    }
    process.exit(1);
  }

  if (dryRun) {
    process.stdout.write(nextText);
    return;
  }

  if (!changed && readFileSync(releasePath, 'utf8') === nextText) {
    console.log('release.json already up to date');
    bustCatalogPage(nextText);
    return;
  }

  writeFileSync(releasePath, nextText);
  bustCatalogPage(nextText);
  console.log(`wrote ${releasePath}`);
  console.log(`components: ${Object.keys(next).length}`);
}

main();
