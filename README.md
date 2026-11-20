# Vault Board — CSC 4360 Homework 02

Vault Board is a Flutter/Android message board backed by Firebase Authentication and Cloud Firestore. It provides email/password identity, a private five-field user record, real-time message reads, owner-only CRUD, deterministic once-only creates, schema versioning, and automated security-rules tests.

## Architecture

Widgets render state and collect input; Firebase calls remain in services.

```text
VaultApp → Firebase initialization → AuthGate
                                  ├─ signed out → AuthScreen → AuthService
                                  └─ signed in  → BoardScreen → BoardService
                                                              → messages snapshots
```

- `AuthService` owns registration, sign-in, sign-out, the current-user getter, the auth-state stream, and creation of `users/{uid}`.
- `BoardService` owns all message creates, live reads, updates, and deletes.
- `AuthGate` uses `authStateChanges()` for navigation. This is convenience and state routing, not authorization.
- `firestore.rules` is the independent authorization boundary. Hiding another author's menu is UX; rules reject the raw write.
- `StreamBuilder` owns the query subscription lifecycle, so disposal of the board removes its listener.

## Data model and field writers

| Path/field | Writer | Placement and trade-off |
|---|---|---|
| `users/{uid}.uid` | Client at registration; must equal authenticated UID | Private identity key; duplicated inside the document to meet the specification. |
| `firstName`, `lastName`, `role` | Owning client at registration | Private profile data. `role` is descriptive and never grants privileges because the client writes it. |
| `registeredAt` | Firestore server timestamp | Avoids trusting the device clock. |
| `messages/{operationId}` | Signed-in author | A deterministic operation ID makes retries converge on one document. |
| `text` | Author | Public to signed-in members, limited to 500 characters. |
| `authorUid` | Author at create, immutable afterward | Ownership source used by rules. |
| `authorName` | Author at create, immutable afterward | Deliberately denormalized so rendering does not require one profile read per post. The trade-off is that old posts retain the old display name. |
| `createdAt`, `updatedAt` | Firestore server timestamp | Stable ordering and edit history without trusting local time. |
| `schemaVersion` | Service/migration | Current value is `2`; enables explicit, testable migrations. |

No message text, profile, password, or notification token is stored by application code in local preferences. Firebase persists its native authentication session on the device; clearing app data removes that local session but not cloud records.

## Security

Rules require authentication for message reads, bind creates to `request.auth.uid`, preserve immutable ownership/creation fields on update, and allow only the owner to update or delete. Each user document is accessible only to its UID. Automated emulator tests cover:

- signed-out read denied;
- forged `authorUid` denied;
- cross-UID update and delete denied;
- correct-author create/read/update/delete allowed.

## Robustness and offline behavior

- The send button is disabled synchronously while a request is active.
- A UUID is generated once per submit attempt and used as the Firestore document ID. A transaction first checks that ID, so a retry cannot create a second document.
- A rapid double-tap on the installed release APK produced exactly one `Release duplicate test` message.
- Firestore listeners may show latency-compensated local changes before server acknowledgement. Transactions require connectivity and fail offline, so the UI retains the draft on failure and presents a safe retry message.
- Loading, empty-board, permission/error, confirmation, and initialization-retry states are intentional.

## Schema migration

`scripts/migrate_messages_v1_to_v2.js` converts realistic v1 fields (`body`, `authorId`, `author`, `timestamp`) to v2 (`text`, `authorUid`, `authorName`, `createdAt`, `updatedAt`, `schemaVersion`). It validates required legacy values, removes obsolete fields only after constructing the replacement, and is safe to rerun. The integration test proves the first run migrates one document without loss and the second migrates zero.

## Setup and run

1. Install Flutter, Java 21, Node, and Firebase CLI.
2. Create a Firebase project, enable Email/Password Authentication, and create Firestore.
3. Run `flutterfire configure --platforms=android`; do not hand-write `firebase_options.dart`.
4. Deploy rules with `firebase deploy --only firestore:rules`.
5. Connect an Android device and run `flutter run`.

The checked-in configuration targets the dedicated course project `message-board-vault-mustufa-26`. Do not commit service-account keys or signing secrets.

## Test commands

```powershell
flutter analyze
flutter test
npm.cmd install
npm.cmd run test:firebase
flutter build apk --release
```

The combined Firebase command uses the `demo-vault-board` project ID. Firebase CLI treats `demo-*` IDs as emulator-only and blocks accidental access to non-emulated services, proving production data is untouched.

## Release artifact

The submission APK is `submission/app-release.apk`. It was installed and launched on a Samsung SM-S731U1 running Android 17/API 37. Internet permission is declared in the main manifest. Device evidence is under `evidence/screenshots/`.

## Scaling decision

The current live query deliberately caps the board at 100 newest messages. At 100,000 messages, a single ever-growing live query would increase initial reads, memory, and listener cost. The next production change would be cursor pagination for historical pages plus a small live query for recent posts. A shared repository-level stream would be considered if multiple simultaneous screens need the same feed.

## References

- [Firebase setup for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Firebase Authentication for Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Cloud Firestore real-time listeners](https://firebase.google.com/docs/firestore/query-data/listen)
- [Firestore transactions and batched writes](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Flutter TextEditingController lifecycle](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html)
