#!/usr/bin/env node
/** Remove Astro content cache so build never reuses a stale catalog table. */
import { rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const cacheDir = join(root, 'astro/.astro');
rmSync(cacheDir, { recursive: true, force: true });
console.log('cleared astro/.astro');
