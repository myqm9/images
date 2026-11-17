import releases from '../data/releases/release.json';

export function loadReleases() {
  return releases;
}

export function parseMiddlewareDocPath(filePath) {
  const normalized = String(filePath ?? '').replaceAll('\\', '/');
  const matched = normalized.match(/\/docs\/middleware\/([^/]+)(?:\/([^/]+))?\.md$/);
  if (!matched) return null;
  return { component: matched[1], versionId: matched[2] ?? null };
}

export function parseMiddlewareRouteId(routeId, allReleases = releases) {
  const parts = String(routeId ?? '').split('/').filter(Boolean);
  if (parts[0] !== 'middleware' || !parts[1]) return null;
  const component = parts[1];
  const release = allReleases[component];
  if (!release) return null;
  return {
    component,
    versionId: parts[2] ?? release.version,
    release,
  };
}

export function versionPageUrl(component, versionId, { nested = false, allReleases = releases } = {}) {
  if (nested) {
    return `/middleware/${encodeURIComponent(component)}/${encodeURIComponent(versionId)}/`;
  }
  const release = allReleases[component];
  if (!release || versionId === release.version) {
    return `/middleware/${encodeURIComponent(component)}/`;
  }
  return `/middleware/${encodeURIComponent(component)}/${encodeURIComponent(versionId)}/`;
}

export function switchableVersions(component, hasPage, allReleases = releases) {
  const release = allReleases[component];
  const versions = Array.isArray(release?.versions) ? release.versions : [];
  const available = versions.filter((entry) => hasPage(component, entry.id));
  return available.length > 1 ? available : [];
}
