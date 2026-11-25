const path = require('node:path');

async function main() {
  const [cliRoot, project] = process.argv.slice(2);
  if (!cliRoot || !/^[a-z0-9-]+$/.test(project ?? '')) {
    throw new Error('Usage: node sync-auth-users.cjs <firebase-tools directory> <project-id>');
  }
  const auth = require(path.join(cliRoot, 'lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Run firebase login first');
  const tokens = await auth.getAccessToken(account.tokens.refresh_token,
    ['https://www.googleapis.com/auth/cloud-platform']);
  const headers = {Authorization: 'Bearer ' + tokens.access_token, 'Content-Type': 'application/json'};
  const database = 'https://firestore.googleapis.com/v1/projects/' + project + '/databases/(default)/documents/users/';
  let next;
  let total = 0;
  let added = 0;
  do {
    const url = new URL('https://identitytoolkit.googleapis.com/v1/projects/' + project + '/accounts:batchGet');
    url.searchParams.set('maxResults', '1000');
    url.searchParams.set('fields', 'users(localId,email,displayName,disabled),nextPageToken');
    if (next) url.searchParams.set('nextPageToken', next);
    const response = await fetch(url, {headers});
    if (!response.ok) throw new Error('Cannot list Authentication users: HTTP ' + response.status);
    const page = await response.json();
    for (const user of page.users ?? []) {
      total++;
      const endpoint = database + encodeURIComponent(user.localId);
      const existing = await fetch(endpoint, {headers});
      if (existing.ok) continue;
      if (existing.status !== 404) throw new Error('Cannot read user profile: HTTP ' + existing.status);
      const created = await fetch(endpoint + '?currentDocument.exists=false', {
        method: 'PATCH', headers,
        body: JSON.stringify({fields: {
          email: {stringValue: user.email ?? ''},
          label: {stringValue: user.displayName ?? ''},
          authDisabled: {booleanValue: user.disabled === true},
        }}),
      });
      if (!created.ok && created.status !== 409) {
        throw new Error('Cannot create user profile: HTTP ' + created.status);
      }
      if (created.ok) added++;
    }
    next = page.nextPageToken;
  } while (next);
  console.log('Authentication accounts: ' + total + '. New Firestore profiles: ' + added + '.');
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
