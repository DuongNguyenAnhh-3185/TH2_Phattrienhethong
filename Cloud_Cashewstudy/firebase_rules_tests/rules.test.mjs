import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { serverTimestamp } from 'firebase/firestore';

const projectId = 'demo-study-doc-manager';
const documentPath = 'documents/document-1';
const storagePath = 'documents/owner-1/document-1/notes.pdf';
let testEnvironment;

before(async () => {
  const [firestoreRules, storageRules] = await Promise.all([
    readFile(new URL('../firestore.rules', import.meta.url), 'utf8'),
    readFile(new URL('../storage.rules', import.meta.url), 'utf8'),
  ]);

  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: { host: '127.0.0.1', port: 8180, rules: firestoreRules },
    storage: { host: '127.0.0.1', port: 9299, rules: storageRules },
  });
});

after(async () => {
  await testEnvironment?.cleanup();
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(documentPath).set({
      ownerId: 'owner-1',
      uploadedBy: 'owner-1',
      uploadStatus: 'ready',
    });

    for (const status of ['pending', 'approved', 'rejected']) {
      await context
          .firestore()
          .doc(`${documentPath}/borrowRequests/${status}-user`)
          .set({
            requesterId: `${status}-user`,
            status,
          });
    }

    await context.storage().ref(storagePath).putString('test document');
  });
});

test('owner and approved borrower can read the private file only', async () => {
  await assertSucceeds(
    testEnvironment.authenticatedContext('owner-1').storage().ref(storagePath).getDownloadURL(),
  );
  await assertSucceeds(
    testEnvironment.authenticatedContext('approved-user').storage().ref(storagePath).getDownloadURL(),
  );
  await assertFails(
    testEnvironment.authenticatedContext('pending-user').storage().ref(storagePath).getDownloadURL(),
  );
  await assertFails(
    testEnvironment.authenticatedContext('rejected-user').storage().ref(storagePath).getDownloadURL(),
  );
  await assertFails(
    testEnvironment.authenticatedContext('unrelated-user').storage().ref(storagePath).getDownloadURL(),
  );
});

test('a user can create only their own pending borrow request', async () => {
  const borrower = testEnvironment.authenticatedContext('new-borrower').firestore();

  await assertSucceeds(
    borrower.doc(`${documentPath}/borrowRequests/new-borrower`).set({
      requesterId: 'new-borrower',
      status: 'pending',
      createdAt: serverTimestamp(),
    }),
  );

  await assertFails(
    borrower.doc(`${documentPath}/borrowRequests/impersonated-user`).set({
      requesterId: 'impersonated-user',
      status: 'pending',
      createdAt: serverTimestamp(),
    }),
  );
});

test('owner can review a pending request, but requester cannot approve themselves', async () => {
  const owner = testEnvironment.authenticatedContext('owner-1').firestore();
  const requester = testEnvironment.authenticatedContext('pending-user').firestore();
  const requestRef = owner.doc(`${documentPath}/borrowRequests/pending-user`);

  await assertSucceeds(
    requestRef.update({
      status: 'approved',
      reviewedAt: serverTimestamp(),
    }),
  );

  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await context
        .firestore()
        .doc(`${documentPath}/borrowRequests/pending-user`)
        .set({ requesterId: 'pending-user', status: 'pending' });
  });

  await assertFails(
    requester.doc(`${documentPath}/borrowRequests/pending-user`).update({
      status: 'approved',
      reviewedAt: serverTimestamp(),
    }),
  );
});