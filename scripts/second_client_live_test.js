import { initializeApp } from 'firebase/app';
import { createUserWithEmailAndPassword, getAuth } from 'firebase/auth';
import { doc, getFirestore, serverTimestamp, setDoc } from 'firebase/firestore';

const app = initializeApp({
  apiKey: 'AIzaSyCU76_tI4MUja9qz_94HYNjAww8_or5yT0',
  appId: '1:957859267659:android:fd5ba41f0ca1d1dfa639ce',
  messagingSenderId: '957859267659',
  projectId: 'message-board-vault-mustufa-26',
});
const suffix = Date.now();
const auth = getAuth(app);
const credential = await createUserWithEmailAndPassword(
  auth,
  `live.client.${suffix}@example.com`,
  `DemoOnly${suffix}!`,
);
const operationId = `live-client-${suffix}`;
await setDoc(doc(getFirestore(app), 'messages', operationId), {
  authorUid: credential.user.uid,
  authorName: 'Independent Client B',
  text: 'Live update from independent client B',
  createdAt: serverTimestamp(),
  updatedAt: null,
  schemaVersion: 2,
});
console.log(JSON.stringify({ operationId, uid: credential.user.uid }));
process.exit(0);
