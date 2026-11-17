import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import replaceImageReferences, { rehypeCopyableImageRefs } from './src/plugins/replace-image-references.mjs';
import releases from './src/data/releases/release.json';

const middlewareDocs = fileURLToPath(new URL('./docs/middleware', import.meta.url));
const redirects = Object.fromEntries(
  Object.entries(releases).flatMap(([component, release]) => {
    const version = release.version;
    if (!version || !existsSync(`${middlewareDocs}/${component}/${version}.md`)) return [];
    const target = `/middleware/${component}/${version}/`;
    return [[`/middleware/${component}`, target]];
  }),
);

// Catalog tables, copy buttons, and {{ image.* }} variables are expanded while Markdown compiles.
export default defineConfig({
  redirects,
  markdown: {
    remarkPlugins: [replaceImageReferences],
    rehypePlugins: [rehypeCopyableImageRefs],
  },
  integrations: [
    starlight({
      title: 'TDP',
      description: 'Middleware 与 SRE 组件的部署、发布与交付文档。',
      favicon: '/favicon.png',
      customCss: ['./src/styles/custom.css'],
      routeMiddleware: './src/starlight-route-data.mjs',
      head: [
        {
          tag: 'link',
          attrs: {
            rel: 'icon',
            href: '/favicon-32.png',
            sizes: '32x32',
            type: 'image/png',
          },
        },
        {
          tag: 'link',
          attrs: {
            rel: 'apple-touch-icon',
            href: '/favicon.png',
          },
        },
      ],
      components: {
        Header: './src/components/Header.astro',
        Hero: './src/components/Hero.astro',
        Footer: './src/components/Footer.astro',
        PageSidebar: './src/components/PageSidebar.astro',
        PageTitle: './src/components/PageTitle.astro',
        ThemeProvider: './src/components/LightThemeProvider.astro',
        ThemeSelect: './src/components/NoThemeSelect.astro',
      },
      sidebar: [
        { label: '开始使用', items: [{ label: '文档首页', link: '/' }, { label: '更新日志', link: '/changelog/' }] },
        { label: '部署前准备', autogenerate: { directory: 'prerequisites' } },
        { label: 'Middleware', autogenerate: { directory: 'middleware' } },
        { label: 'SRE', items: [{ label: '组件目录', link: '/sre/' }] },
      ],
    }),
  ],
});
