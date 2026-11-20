import { readFileSync } from 'node:fs';
import { after, afterEach, before, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'demo-vault-board';
const ownerUid = 'owner-uid';
const attackerUid = 'attacker-uid';
let testEnv;

function message(overrides = {}) {
  return {
    authorUid: ownerUid,
    authorName: 'Muhammad Mustufa',
    text: 'Rules test message',
    createdAt: serverTimestamp(),
    updatedAt: null,
    schemaVersion: 2,
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

afterEach(() => testEnv.clearFirestore());
after(() => testEnv.cleanup());

describe('message ownership rules', () => {
  test('signed-out reads are denied', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'messages/message-1')));
  });

  test('a forged authorUid create is denied', async () => {
    const db = testEnv.authenticatedContext(attackerUid).firestore();
    await assertFails(setDoc(doc(db, 'messages/message-1'), message()));
  });

  test('cross-user update and delete are denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'messages/message-1'), {
        ...message(),
        createdAt: new Date('2026-11-19T20:00:00-05:00'),
      });
    });
    const attackerDb = testEnv.authenticatedContext(attackerUid).firestore();
    const ref = doc(attackerDb, 'messages/message-1');
    await assertFails(updateDoc(ref, { text: 'Stolen edit' }));
    await assertFails(deleteDoc(ref));
  });

  test('the correct author can create, read, update, and delete', async () => {
    const db = testEnv.authenticatedContext(ownerUid).firestore();
    const ref = doc(db, 'messages/message-1');
    await assertSucceeds(setDoc(ref, message()));
    assert.equal((await assertSucceeds(getDoc(ref))).data().text, 'Rules test message');
    await assertSucceeds(updateDoc(ref, {
      text: 'Owner edit',
      updatedAt: serverTimestamp(),
      schemaVersion: 2,
    }));
    await assertSucceeds(deleteDoc(ref));
  });
});
