import { defineRouteMiddleware } from '@astrojs/starlight/route-data';

function flattenSingleChildGroups(entries) {
  return entries.map((entry) => {
    if (entry.type !== 'group') return entry;
    const children = flattenSingleChildGroups(entry.entries);
    if (children.length === 1 && children[0].type === 'link') return children[0];
    return { ...entry, entries: children };
  });
}

function middlewareComponent(pathname) {
  const parts = String(pathname).split('/').filter(Boolean);
  return parts[0] === 'middleware' && parts[1] ? parts[1] : null;
}

function markComponentCurrent(entries, pathname) {
  const current = middlewareComponent(pathname);
  if (!current) return;
  for (const entry of entries) {
    if (entry.type === 'group') markComponentCurrent(entry.entries, pathname);
    else if (entry.type === 'link' && middlewareComponent(entry.href) === current) {
      entry.isCurrent = true;
    }
  }
}

export const onRequest = defineRouteMiddleware((context) => {
  const route = context.locals.starlightRoute ?? context.starlightRoute;
  if (!route?.sidebar) return;
  const sidebar = flattenSingleChildGroups(route.sidebar);
  markComponentCurrent(sidebar, route.id || context.url.pathname);
  route.sidebar = sidebar;
});
