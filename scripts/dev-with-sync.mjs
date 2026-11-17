#!/usr/bin/env node
/**
 * Start Astro dev after syncing README → release.json.
 *
 * README 用「目录监听 + 轮询」双保险：编辑器原子保存（先写临时文件再 rename）
 * 时，只 watch 单个文件经常丢事件，所以有时改 README 不会触发 sync。
 */
import { createHash } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, watch, watchFile, unwatchFile } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const readmePath = join(root, 'README.md');
const releasePath = join(root, 'astro/src/data/releases/release.json');
const catalogPagePath = join(root, 'astro/docs/middleware.md');
const syncScript = join(root, 'scripts/sync-release-json.mjs');

let readmeTimer = null;
let releaseTimer = null;
let syncing = false;
/** sync 自己会写 release.json，避免再当成「外部修改」处理一次 */
let ignoreReleaseBursts = 0;

function syncNow(label = 'sync') {
  ignoreReleaseBursts += 1;
  const result = spawnSync(process.execPath, [syncScript], { cwd: root, stdio: 'inherit' });
  if (result.status !== 0) {
    console.error(`[releases] ${label}: sync:releases failed`);
    return false;
  }
  return true;
}

function bustCatalogPage() {
  const releaseText = readFileSync(releasePath, 'utf8');
  const hash = createHash('sha1').update(releaseText).digest('hex').slice(0, 12);
  const marker = `<!-- middleware-catalog bust=${hash} -->`;
  let page = readFileSync(catalogPagePath, 'utf8');
  if (page.includes(marker)) return;
  if (/<!-- middleware-catalog(?:\s+bust=[^\s>]+)? -->/.test(page)) {
    page = page.replace(/<!-- middleware-catalog(?:\s+bust=[^\s>]+)? -->/, marker);
  } else {
    page = `${page.trimEnd()}\n\n${marker}\n`;
  }
  writeFileSync(catalogPagePath, page);
  console.log(`[releases] catalog cache bust=${hash}`);
}

function scheduleReadmeSync(reason) {
  if (readmeTimer) clearTimeout(readmeTimer);
  readmeTimer = setTimeout(() => {
    if (syncing) return;
    syncing = true;
    console.log(`\n[releases] README.md changed (${reason}) → sync:releases`);
    const ok = syncNow('watch');
    syncing = false;
    if (!ok) console.error('[releases] sync failed; fix README and save again');
  }, 300);
}

function scheduleReleaseRefresh(reason) {
  if (releaseTimer) clearTimeout(releaseTimer);
  releaseTimer = setTimeout(() => {
    if (ignoreReleaseBursts > 0) {
      ignoreReleaseBursts -= 1;
      return;
    }
    if (syncing) return;
    console.log(`\n[releases] release.json changed (${reason}) → refresh catalog page`);
    bustCatalogPage();
  }, 300);
}

if (!syncNow('startup')) process.exit(1);

const astroArgs = process.argv.slice(2);
const child = spawn('npm', ['--prefix', 'astro', 'run', 'dev', '--', ...astroArgs], {
  cwd: root,
  stdio: 'inherit',
  shell: process.platform === 'win32',
});

// 1) 监听仓库根目录：原子保存 rename 后仍能收到 README.md 事件
watch(root, { persistent: true }, (_event, filename) => {
  if (!filename) return;
  if (basename(filename) !== 'README.md') return;
  scheduleReadmeSync('dir-watch');
});

// 2) 轮询备份：部分编辑器/文件系统下 watch 仍可能漏事件
watchFile(readmePath, { interval: 800, persistent: true }, (curr, prev) => {
  if (curr.mtimeMs === prev.mtimeMs && curr.size === prev.size) return;
  scheduleReadmeSync('poll');
});

watch(dirname(releasePath), { persistent: true }, (_event, filename) => {
  if (!filename) return;
  if (basename(filename) !== 'release.json') return;
  scheduleReleaseRefresh('dir-watch');
});

watchFile(releasePath, { interval: 1000, persistent: true }, (curr, prev) => {
  if (curr.mtimeMs === prev.mtimeMs && curr.size === prev.size) return;
  scheduleReleaseRefresh('poll');
});

child.on('exit', (code, signal) => {
  if (readmeTimer) clearTimeout(readmeTimer);
  if (releaseTimer) clearTimeout(releaseTimer);
  unwatchFile(readmePath);
  unwatchFile(releasePath);
  process.exit(code ?? (signal ? 1 : 0));
});
