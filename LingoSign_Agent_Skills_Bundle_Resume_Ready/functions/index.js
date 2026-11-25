const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {may, parseContent} = require('./policy');

initializeApp();
const auth = getAuth();
const db = getFirestore();
const accounts = db.collection('accountAccess');
const audit = db.collection('adminAudit');
const kinds = ['categories', 'signs', 'lessons'];
const content = (kind) => db.collection('admin_' + kind);
const publicContent = (kind) => db.collection('published_' + kind);
const deny = () => new HttpsError('permission-denied', 'Access denied');
const invalid = () => new HttpsError('invalid-argument', 'Invalid data');
const view = (doc) => ({...doc.data(), id: doc.id});

exports.manageLingoSign = onCall({region: 'us-central1'}, async (request) => {
  if (!request.auth) throw deny();
  const actor = request.auth.uid;
  const token = request.rawRequest.get('authorization')?.split(' ')[1];
  try {
    await auth.verifyIdToken(token, true);
  } catch (_) {
    throw deny();
  }
  const {action, kind, id, cursor, item, role, locked, revision, email,
    previousRole, previousLocked} = request.data ?? {};
  const actorRef = accounts.doc(actor);
  if (!may((await actorRef.get()).data(), action)) throw deny();

  if (action === 'users') {
    let page;
    if (typeof email === 'string' && email.trim()) {
      try {
        page = {users: [await auth.getUserByEmail(email.trim())]};
      } catch (error) {
        if (error.code === 'auth/user-not-found') return {items: []};
        throw error;
      }
    } else {
      page = await auth.listUsers(30, typeof cursor === 'string' ? cursor : undefined);
    }
    const refs = page.users.map(user => accounts.doc(user.uid));
    const policies = refs.length ? await db.getAll(...refs) : [];
    return {
      cursor: page.pageToken ?? null,
      items: page.users.map((user, i) => ({
        id: user.uid, email: user.email ?? '', label: user.displayName ?? '',
        role: policies[i].data()?.role ?? 'learner',
        locked: policies[i].data()?.locked === true || user.disabled,
        disabled: user.disabled,
      })),
    };
  }

  if (action === 'overview') {
    const result = {};
    for (const type of kinds) {
      result[type] = (await publicContent(type).where('state', '==', 'published')
        .count().get()).data().count;
    }
    result.pending = (await Promise.all(kinds.map(type =>
      content(type).where('state', '==', 'draft').count().get())))
      .reduce((count, snapshot) => count + snapshot.data().count, 0);
    return result;
  }

  if (action === 'audit') {
    let query = audit.orderBy('at', 'desc').limit(30);
    if (typeof cursor === 'string') {
      const after = await audit.doc(cursor).get();
      if (after.exists) query = query.startAfter(after);
    }
    const page = await query.get();
    return {
      items: page.docs.map(doc => ({...view(doc), at: doc.get('at')?.toDate().toISOString()})),
      cursor: page.size === 30 ? page.docs.at(-1).id : null,
    };
  }

  if (action === 'content') {
    if (!kinds.includes(kind)) throw invalid();
    let query = content(kind).orderBy('__name__').limit(50);
    if (typeof cursor === 'string') query = query.startAfter(cursor);
    const page = await query.get();
    return {items: page.docs.map(view), cursor: page.size === 50 ? page.docs.at(-1).id : null};
  }

  if (action === 'account') {
    if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(id) ||
        !['learner', 'manager', 'admin'].includes(role) || typeof locked !== 'boolean' ||
        (locked && role === 'admin') || id === actor) throw invalid();
    await auth.getUser(id);
    const target = accounts.doc(id);
    await db.runTransaction(async tx => {
      if (!may((await tx.get(actorRef)).data(), action)) throw deny();
      const before = (await tx.get(target)).data() ?? {};
      if (before.role === 'admin') throw deny();
      if ((before.role ?? 'learner') !== previousRole ||
          (before.locked ?? false) !== previousLocked) {
        throw new HttpsError('aborted', 'Account changed');
      }
      if ((before.role ?? 'learner') === role && (before.locked ?? false) === locked) return;
      tx.set(target, {role, locked});
      tx.create(audit.doc(), {
        actor, action, target: id, role, locked,
        previousRole: before.role ?? 'learner', previousLocked: before.locked ?? false,
        at: FieldValue.serverTimestamp(),
      });
    });
    return {};
  }

  if (!kinds.includes(kind) || !Number.isSafeInteger(revision) || revision < 0) throw invalid();
  let clean;
  try {
    clean = parseContent(action === 'hide' ? 'categories' : kind, id, item);
  } catch (_) {
    throw invalid();
  }
  const ref = content(kind).doc(id);
  const published = publicContent(kind).doc(id);
  await db.runTransaction(async tx => {
    if (!may((await tx.get(actorRef)).data(), action)) throw deny();
    const before = (await tx.get(ref)).data();
    if ((before?.revision ?? 0) !== revision) {
      throw new HttpsError('aborted', 'Content changed');
    }
    if (action === 'hide' && !before && kind !== 'signs') throw invalid();
    const state = {save: 'draft', publish: 'published', hide: 'hidden'}[action];
    const next = {...(action === 'hide' ? before ?? clean : clean), state, revision: revision + 1};
    if (action === 'publish' && kind === 'signs' && clean.categoryId) {
      const category = await tx.get(publicContent('categories').doc(clean.categoryId));
      if (category.get('state') !== 'published') {
        throw new HttpsError('failed-precondition', 'Category is not published');
      }
    }
    tx.set(ref, next);
    if (action === 'publish') tx.set(published, next);
    if (action === 'hide') tx.set(published, {state: 'hidden'});
    tx.create(audit.doc(), {actor, action, kind, target: id, label: next.label,
      at: FieldValue.serverTimestamp()});
  });
  return {};
});

