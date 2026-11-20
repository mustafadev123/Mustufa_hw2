import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getApps, initializeApp } from 'firebase-admin/app';

if (getApps().length === 0) initializeApp({ projectId: 'demo-vault-board' });

export async function migrateMessagesV1ToV2(db = getFirestore()) {
  const snapshot = await db.collection('messages').where('schemaVersion', '==', 1).get();
  let migrated = 0;
  for (const document of snapshot.docs) {
    const old = document.data();
    const text = old.text ?? old.body;
    const authorUid = old.authorUid ?? old.authorId;
    const authorName = old.authorName ?? old.author ?? 'Unknown';
    if (typeof text !== 'string' || typeof authorUid !== 'string') {
      throw new Error(`Cannot safely migrate messages/${document.id}`);
    }
    await document.ref.update({
      text,
      authorUid,
      authorName,
      createdAt: old.createdAt ?? old.timestamp,
      updatedAt: old.updatedAt ?? null,
      schemaVersion: 2,
      body: FieldValue.delete(),
      authorId: FieldValue.delete(),
      author: FieldValue.delete(),
      timestamp: FieldValue.delete(),
    });
    migrated++;
  }
  return migrated;
}

if (import.meta.url === `file://${process.argv[1].replaceAll('\\', '/')}`) {
  const count = await migrateMessagesV1ToV2();
  console.log(`Migrated ${count} message(s) from schema v1 to v2.`);
}
