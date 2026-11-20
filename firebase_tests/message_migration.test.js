import { after, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { getApps, initializeApp } from 'firebase-admin/app';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';
import { migrateMessagesV1ToV2 } from '../scripts/migrate_messages_v1_to_v2.js';

let db;
before(() => {
  if (getApps().length === 0) initializeApp({ projectId: 'demo-vault-board' });
  db = getFirestore();
});
after(async () => {
  const snapshot = await db.collection('messages').get();
  await Promise.all(snapshot.docs.map((document) => document.ref.delete()));
});

test('realistic v1 data migrates to v2 without content loss', async () => {
  const timestamp = Timestamp.fromDate(new Date('2025-09-10T14:30:00Z'));
  const ref = db.collection('messages').doc('legacy-message');
  await ref.set({
    body: 'A message written with the old schema',
    authorId: 'legacy-owner',
    author: 'Legacy Student',
    timestamp,
    schemaVersion: 1,
  });

  assert.equal(await migrateMessagesV1ToV2(db), 1);
  assert.equal(await migrateMessagesV1ToV2(db), 0, 'migration is safe to rerun');

  const migrated = (await ref.get()).data();
  assert.deepEqual(migrated, {
    text: 'A message written with the old schema',
    authorUid: 'legacy-owner',
    authorName: 'Legacy Student',
    createdAt: timestamp,
    updatedAt: null,
    schemaVersion: 2,
  });
});
