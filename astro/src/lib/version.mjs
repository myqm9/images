import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const versionFile = fileURLToPath(new URL('../../../VERSION.md', import.meta.url));

function parseItems(body) {
  return body
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => line.replace(/^\d+[、.]\s*/, ''))
    .filter(Boolean);
}

function normalizeVersion(value) {
  return String(value ?? '').trim().toLowerCase();
}

function compareEntries(a, b) {
  const dateCmp = b.date.localeCompare(a.date);
  if (dateCmp !== 0) return dateCmp;
  return b.order - a.order;
}

/** @param {string} source */
export function parseVersionMarkdown(source) {
  const versionMatch = source.match(/^latest_version\s*=\s*(\S+)\s*$/m);
  const version = versionMatch?.[1]?.trim() ?? '';

  /** @type {{ date: string, version: string, items: string[], order: number }[]} */
  const entries = [];
  const blockPattern = /^>\s*(\d{4}-\d{2}-\d{2})\s+(\S+)\s*\r?\n```[^\n]*\r?\n([\s\S]*?)```/gm;

  for (const match of source.matchAll(blockPattern)) {
    entries.push({
      date: match[1],
      version: match[2].trim(),
      items: parseItems(match[3]),
      order: entries.length,
    });
  }

  entries.sort(compareEntries);
  const latestDate = entries[0]?.date ?? '';

  return {
    version,
    entries,
    batchCount: entries.length,
    latestDate,
  };
}

export function isCurrentVersion(entryVersion, currentVersion) {
  return normalizeVersion(entryVersion) === normalizeVersion(currentVersion);
}

export function loadVersionInfo() {
  const source = readFileSync(versionFile, 'utf8');
  return parseVersionMarkdown(source);
}
