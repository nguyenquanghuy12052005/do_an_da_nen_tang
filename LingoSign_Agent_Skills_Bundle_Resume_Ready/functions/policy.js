const staff = new Set(['overview', 'content', 'save']);
const admin = new Set(['users', 'account', 'publish', 'hide', 'audit']);

function may(policy, action) {
  if (!policy || policy.locked) return false;
  if (policy.role === 'admin') return staff.has(action) || admin.has(action);
  return policy.role === 'manager' && staff.has(action);
}

const key = /^[A-Za-z0-9_-]{1,64}$/;

function parseContent(kind, id, data) {
  if (typeof id !== 'string' || !key.test(id) || !data || Array.isArray(data)) {
    throw new Error('Invalid content');
  }
  const field = (name, max, required = false) => {
    const raw = data[name] ?? '';
    if (typeof raw !== 'string') throw new Error(name);
    const value = raw.trim();
    if ((required && !value) || value.length > max) throw new Error(name);
    return value;
  };
  const label = field('label', 100, true);
  if (kind === 'categories') return {label};
  if (kind === 'lessons') {
    const targets = data.targets;
    if (!Array.isArray(targets) || !targets.length || targets.length > 30 ||
        targets.some(target => typeof target !== 'string' || !/^[A-Z]$/.test(target))) {
      throw new Error('Invalid practice targets');
    }
    return {label, description: field('description', 1000), targets};
  }
  if (kind !== 'signs') throw new Error('Invalid kind');
  const categoryId = field('categoryId', 64);
  const sourceUrl = field('sourceUrl', 400, true);
  const url = new URL(sourceUrl);
  const modelLabel = field('modelLabel', 1);
  const imageAsset = field('imageAsset', 150);
  const videoAsset = field('videoAsset', 150);
  const bundledMedia = /^assets\/dictionary\/[A-Za-z0-9_-]+(?:\/[A-Za-z0-9_-]+)*\.[A-Za-z0-9]+$/;
  if (url.protocol !== 'https:' || url.username || url.password ||
      (categoryId && !key.test(categoryId)) ||
      (modelLabel && !/^[A-Z]$/.test(modelLabel)) ||
      [imageAsset, videoAsset].some(path => path && !bundledMedia.test(path))) {
    throw new Error('Invalid sign metadata');
  }
  return {label, categoryId, sourceUrl, modelLabel, imageAsset, videoAsset,
    category: field('category', 100), description: field('description', 1000),
    instructions: field('instructions', 2000), signSystem: field('signSystem', 60, true),
    licenseName: field('licenseName', 150, true)};
}

module.exports = {may, parseContent};
