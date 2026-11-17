import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { basename, extname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { visit } from 'unist-util-visit';
import { parseMiddlewareDocPath, versionPageUrl } from '../lib/middleware-versions.mjs';
import releasesFingerprint from '../data/releases/release.json';

const metadataPath = fileURLToPath(new URL('../data/releases/release.json', import.meta.url));
const docsMiddleware = fileURLToPath(new URL('../../docs/middleware', import.meta.url));
const referencePattern = /harbor\.tsingyun\.net\/tsingyun-middleware\/[\w.-]+:[\w.-]+/g;
const variablePattern = /{{\s*([A-Za-z][\w]*(?:\.[A-Za-z0-9_][\w]*)*)\s*}}/g;

// Imported JSON + markup revision keep Vite/Starlight content cache in sync
// when release data or catalog HTML structure changes (e.g. copy UX).
const CATALOG_MARKUP_REVISION = 'detail-inline-copy-v2-known-refs';
const harborReferenceExact = /^harbor\.tsingyun\.net\/tsingyun-middleware\/[\w.-]+:[\w.-]+$/;
void releasesFingerprint;
export const CATALOG_RENDER_VERSION = createHash('sha1')
  .update(CATALOG_MARKUP_REVISION)
  .update(JSON.stringify(releasesFingerprint))
  .digest('hex')
  .slice(0, 12);

function referencesIn(value, result = []) {
  if (!value || typeof value !== 'object') return result;
  if (typeof value.reference === 'string') result.push(value.reference);
  else Object.values(value).forEach((entry) => referencesIn(entry, result));
  return result;
}

function architectureOf(reference) {
  return /(?:^|[:-])arm64(?:$|-)/.test(reference.slice(reference.lastIndexOf('/') + 1)) ? 'arm64' : 'amd64';
}

function repositoryImageName(reference) {
  const image = reference.slice(reference.lastIndexOf('/') + 1);
  return image.slice(0, image.indexOf(':'));
}

function allReleaseReferences(release) {
  const result = [];
  if (!release) return result;
  referencesIn(release.images?.amd64, result);
  referencesIn(release.images?.arm64, result);
  for (const entry of versionEntries(release)) {
    referencesIn(entry.images?.amd64, result);
    referencesIn(entry.images?.arm64, result);
  }
  return result;
}

/**
 * Keep hardcoded Harbor refs on a detail page in sync with the page's current
 * version. Only rewrite addresses that already belong to this component's
 * release history — same repo name with a different tag (e.g. influxdb3-ui
 * living under the influxdb repository) must not be rewritten.
 */
function rewriteToCurrentImages(value, currentImages, knownReferences = []) {
  if (!currentImages) return value;
  const known = new Set(knownReferences);
  const byArchAndName = new Map();
  for (const architecture of ['amd64', 'arm64']) {
    for (const reference of referencesIn(currentImages[architecture])) {
      byArchAndName.set(`${architecture}:${repositoryImageName(reference)}`, reference);
    }
  }
  return value.replace(referencePattern, (reference) => {
    if (!known.has(reference)) return reference;
    return byArchAndName.get(`${architectureOf(reference)}:${repositoryImageName(reference)}`) ?? reference;
  });
}

function versionKey(id) {
  return String(id).replace(/[.-]/g, '_');
}

function versionEntries(release) {
  return Array.isArray(release?.versions) && release.versions.length ? release.versions : [];
}

function catalogVersionRows(release) {
  const entries = versionEntries(release);
  if (entries.length) return entries;
  return [{
    id: release.version,
    ports: release.catalog?.ports ?? [],
    note: release.catalog?.description,
    images: release.images,
  }];
}

function catalogRowDescription(entry) {
  return entry.note ? escapeHtml(entry.note) : '';
}

function applyCurrentVersion(release, versionId, variables) {
  const entries = versionEntries(release);
  const currentId = versionId ?? release.version;
  const entry = entries.find((item) => item.id === currentId) ?? {
    id: currentId,
    images: release.images,
    ports: release.catalog?.ports ?? [],
  };
  variables.version = entry.id;
  variables['release.version'] = entry.id;
  if (entry.images) {
    Object.assign(variables, flatten(entry.images, 'images'));
    Object.assign(variables, flatten(entry.images, 'image'));
  }
  if (Array.isArray(entry.ports)) {
    variables.ports = entry.ports.join(' ');
    variables['release.ports'] = variables.ports;
  }
}

function renderVersionCell(componentKey, release, entry) {
  const text = String(entry.label || entry.id);
  const coded = `<code>${escapeHtml(text)}</code>`;
  if (release.catalog.status !== 'managed' || !versionPageExists(componentKey, release, entry.id)) return coded;
  return `<a href="${versionPageUrl(componentKey, entry.id, { nested: componentUsesVersionDir(componentKey) })}">${coded}</a>`;
}

function versionPageExists(component, release, versionId) {
  if (existsSync(join(docsMiddleware, component, `${versionId}.md`))) return true;
  return versionId === release.version && existsSync(join(docsMiddleware, `${component}.md`));
}

function componentUsesVersionDir(component) {
  return existsSync(join(docsMiddleware, component));
}

function flatten(value, prefix = '', result = {}) {
  for (const [key, item] of Object.entries(value ?? {})) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (typeof item === 'string') result[path] = item;
    else if (item && typeof item === 'object' && !Array.isArray(item)) flatten(item, path, result);
  }
  return result;
}

function assignVersionVariables(release, variables) {
  for (const entry of versionEntries(release)) {
    const key = versionKey(entry.id);
    Object.assign(variables, flatten(entry, `version.${key}`));
    if (entry.images) Object.assign(variables, flatten(entry.images, `version.${key}.image`));
    if (Array.isArray(entry.ports)) variables[`version.${key}.ports`] = entry.ports.join(' ');
  }
}

function escapeHtml(value) {
  return String(value).replace(/[&<>'"]/g, (character) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;',
  })[character]);
}

function renderCopyableReference(value) {
  const text = escapeHtml(value);
  return `<button type="button" class="catalog-copy" data-copy="${text}" title="点击复制" aria-label="复制镜像地址 ${text}"><code>${text}</code></button>`;
}

function renderLines(values, copyable = false) {
  const lines = values.length ? values : ['—'];
  return lines.map((value) => {
    if (!copyable || value === '—') return `<code>${escapeHtml(value)}</code>`;
    return renderCopyableReference(value);
  }).join('<br />');
}

function renderCatalog(releases) {
  const entries = Object.entries(releases)
    .filter(([, release]) => release.catalog)
    .sort(([, left], [, right]) => left.catalog.order - right.catalog.order);
  const renderRows = (predicate) => entries.filter(([, release]) => predicate(release)).flatMap(([key, release]) => {
    const label = escapeHtml(release.catalog.label);
    const name = release.catalog.status === 'managed' ? `<a href="/middleware/${encodeURIComponent(key)}/">${label}</a>` : label;
    const rows = catalogVersionRows(release);
    return rows.map((entry, index) => {
      const grouped = rows.length > 1;
      const classes = grouped ? ` class="${index === 0 ? 'catalog-row--group-start' : 'catalog-row--group-cont'}"` : '';
      const component = index === 0
        ? `<td class="catalog-cell--name"${rows.length > 1 ? ` rowspan="${rows.length}"` : ''}>${name}</td>`
        : '';
      return `<tr${classes}>${component}<td class="catalog-cell--version">${renderVersionCell(key, release, entry)}</td><td class="catalog-cell--amd64">${renderLines(referencesIn(entry.images?.amd64), true)}</td><td class="catalog-cell--arm64">${renderLines(referencesIn(entry.images?.arm64), true)}</td><td class="catalog-cell--port">${renderLines(entry.ports ?? [])}</td><td class="catalog-cell--note">${catalogRowDescription(entry)}</td></tr>`;
    });
  }).join('');
  const table = (rows, className = '') => `<div class="catalog-table-wrap${className ? ` ${className}` : ''}"><table class="catalog-table catalog-table--copyable"><thead><tr><th>组件</th><th>版本</th><th>AMD64 镜像</th><th>ARM64 镜像</th><th>端口</th><th>说明</th></tr></thead><tbody>${rows}</tbody></table></div>`;
  return `<h2>中间件</h2>${table(renderRows((release) => release.catalog.section !== 'ops'))}<h2>运维工具</h2>${table(renderRows((release) => release.catalog.section === 'ops'))}<p class="catalog-footnote">镜像清单来源：项目根目录 <code>README.md</code>。说明字段与 README 原文一致；未填写则留空。</p>`;
}

/**
 * Replaces Harbor image values while Markdown is compiled by Astro.
 * The Markdown files remain human-maintained documents; release.json is the
 * single image-address source and no separate docs rendering command is needed.
 */
export default function replaceImageReferences() {
  return (tree, file) => {
    const releases = JSON.parse(readFileSync(metadataPath, 'utf8'));
    const parsed = parseMiddlewareDocPath(file.path);
    const component = parsed?.component ?? basename(file.path ?? '', extname(file.path ?? ''));
    const release = releases[component];
    const variables = flatten(release);
    if (release) {
      assignVersionVariables(release, variables);
      applyCurrentVersion(release, parsed?.versionId, variables);
    } else {
      if (variables.version) variables['release.version'] = variables.version;
      if (variables['images.amd64.reference']) variables['image.amd64.reference'] = variables['images.amd64.reference'];
      if (variables['images.arm64.reference']) variables['image.arm64.reference'] = variables['images.arm64.reference'];
    }
    const currentImages = release
      ? versionEntries(release).find((entry) => entry.id === (parsed?.versionId ?? release.version))?.images ?? release.images
      : undefined;
    const knownReferences = allReleaseReferences(release);
    const replaceVariables = (value) => value.replace(variablePattern, (_match, variable) => variables[variable] ?? _match);
    const replaceValue = (value) => rewriteToCurrentImages(replaceVariables(value), currentImages, knownReferences);

    visit(tree, 'inlineCode', (node) => {
      node.value = replaceValue(node.value);
    });
    visit(tree, 'code', (node) => {
      node.value = replaceValue(node.value);
    });
    visit(tree, 'text', (node) => {
      node.value = replaceValue(node.value);
    });
    visit(tree, 'html', (node) => {
      node.value = replaceValue(node.value);
      if (/<!--\s*middleware-catalog(?:\s+bust=[^\s>]+)?\s*-->/.test(node.value)) {
        node.value = renderCatalog(releases);
      }
    });
  };
}

/**
 * Wrap Harbor image addresses in detail-page inline <code> with the same
 * click-to-copy control used by the /middleware catalog table.
 * Runs as rehype so the button survives Starlight's HTML pipeline.
 */
export function rehypeCopyableImageRefs() {
  return (tree) => {
    visit(tree, 'element', (node, index, parent) => {
      if (!parent || typeof index !== 'number') return;
      if (node.tagName !== 'code') return;
      if (parent.tagName === 'pre') return;
      if (parent.tagName === 'button') return;

      const text = (node.children ?? [])
        .filter((child) => child.type === 'text')
        .map((child) => child.value)
        .join('')
        .trim();
      if (!harborReferenceExact.test(text)) return;

      parent.children[index] = {
        type: 'element',
        tagName: 'button',
        properties: {
          type: 'button',
          className: ['catalog-copy'],
          dataCopy: text,
          title: '点击复制',
          ariaLabel: `复制镜像地址 ${text}`,
        },
        children: [node],
      };
      return 'skip';
    });
  };
}
