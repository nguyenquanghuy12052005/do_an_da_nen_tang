const assert = require('node:assert/strict');
const test = require('node:test');
const {may, parseContent} = require('./policy');

test('only active staff may manage content and only admins may publish or manage users', () => {
  for (const action of ['overview', 'content', 'save', 'publish', 'hide', 'users', 'account', 'audit']) {
    assert.equal(may(undefined, action), false);
    assert.equal(may({role: 'learner', locked: false}, action), false);
    assert.equal(may({role: 'admin', locked: true}, action), false);
    assert.equal(may({role: 'admin', locked: false}, action), true);
    assert.equal(may({role: 'manager', locked: false}, action), ['overview', 'content', 'save'].includes(action));
  }
  assert.equal(may({role: 'admin'}, 'constructor'), false);
});

test('practice preserves ordering and rejects labels the camera does not grade', () => {
  assert.deepEqual(parseContent('lessons', 'alphabet', {
    label: 'Alphabet', targets: ['B', 'A', 'B'], state: 'published',
  }), {label: 'Alphabet', targets: ['B', 'A', 'B'], description: ''});
  for (const targets of [[], ['nothing'], ['1'], Array(31).fill('A')]) {
    assert.throws(() => parseContent('lessons', 'alphabet', {label: 'Alphabet', targets}));
  }
});

test('dictionary media is restricted to bundled paths and sources require HTTPS', () => {
  const item = {label: 'Chữ A', signSystem: 'ASL', sourceUrl: 'https://example.org/chart',
    licenseName: 'CC BY 4.0', imageAsset: 'assets/dictionary/signs/A.png'};
  assert.equal(parseContent('signs', 'a', item).imageAsset, item.imageAsset);
  assert.throws(() => parseContent('signs', 'a', {...item, imageAsset: 'assets/dictionary/../private.png'}));
  assert.throws(() => parseContent('signs', 'a', {...item, sourceUrl: 'http://example.org'}));
  assert.throws(() => parseContent('signs', '../a', item));
});
