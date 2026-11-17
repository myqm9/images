import { defineCollection } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';
import releases from './data/releases/release.json';
import replaceImageReferences, { CATALOG_RENDER_VERSION, rehypeCopyableImageRefs } from './plugins/replace-image-references.mjs';
import { loadReleases } from './lib/middleware-versions.mjs';
import { loadVersionInfo } from './lib/version.mjs';

// Keep the content cache tied to catalog data and the remark plugin.
void releases;
void replaceImageReferences;
void rehypeCopyableImageRefs;
void CATALOG_RENDER_VERSION;
void loadReleases;
void loadVersionInfo();

export const collections = {
  docs: defineCollection({
    loader: docsLoader({
      generateId: ({ entry }) => {
        const id = entry.replaceAll('\\', '/').replace(/\.[^.]+$/, '');
        return id === 'index' ? 'index' : id.replace(/\/index$/, '');
      },
    }),
    schema: docsSchema(),
  }),
};
