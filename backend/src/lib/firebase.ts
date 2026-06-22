import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import type { Auth } from 'firebase-admin/auth';
import { getAuth } from 'firebase-admin/auth';
import type { Firestore } from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import type { Storage } from 'firebase-admin/storage';
import { getStorage } from 'firebase-admin/storage';

import { config } from './config';

function isFirebaseConfigured(): boolean {
  return Boolean(
    config.firebaseProjectId &&
      config.firebaseClientEmail &&
      config.firebasePrivateKey,
  );
}

function getFirebaseApp(): App {
  if (!isFirebaseConfigured()) {
    throw new Error(
      'Firebase chưa cấu hình. Điền FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY trong backend/.env',
    );
  }

  return (
    getApps()[0] ??
    initializeApp({
      credential: cert({
        projectId: config.firebaseProjectId!,
        clientEmail: config.firebaseClientEmail!,
        privateKey: config.firebasePrivateKey!.replace(/\\n/g, '\n'),
      }),
    })
  );
}

let firebaseAuthInstance: Auth | null = null;
let firestoreInstance: Firestore | null = null;
let storageInstance: Storage | null = null;

/** Firebase Admin — chỉ khởi tạo khi đã cấu hình biến môi trường (Google/Facebook login). */
export function getFirebaseAuth(): Auth {
  if (firebaseAuthInstance) return firebaseAuthInstance;
  firebaseAuthInstance = getAuth(getFirebaseApp());
  return firebaseAuthInstance;
}

export function getDb(): Firestore {
  if (firestoreInstance) return firestoreInstance;
  firestoreInstance = getFirestore(getFirebaseApp());
  return firestoreInstance;
}

export function getFirebaseStorage(): Storage {
  if (storageInstance) return storageInstance;
  storageInstance = getStorage(getFirebaseApp());
  return storageInstance;
}

export function isFirebaseReady(): boolean {
  return isFirebaseConfigured();
}
