import { cert, getApps, initializeApp } from 'firebase-admin/app';
import type { Auth } from 'firebase-admin/auth';
import { getAuth } from 'firebase-admin/auth';
import type { Firestore } from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

import { config } from './config';

function isFirebaseConfigured(): boolean {
  return Boolean(
    config.firebaseProjectId &&
      config.firebaseClientEmail &&
      config.firebasePrivateKey,
  );
}

let firebaseAuthInstance: Auth | null = null;
let firestoreInstance: Firestore | null = null;

/** Firebase Admin — chỉ khởi tạo khi đã cấu hình biến môi trường (Google/Facebook login). */
export function getFirebaseAuth(): Auth {
  if (!isFirebaseConfigured()) {
    throw new Error(
      'Firebase chưa cấu hình. Điền FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY trong backend/.env',
    );
  }

  if (firebaseAuthInstance) return firebaseAuthInstance;

  const firebaseApp =
    getApps()[0] ??
    initializeApp({
      credential: cert({
        projectId: config.firebaseProjectId!,
        clientEmail: config.firebaseClientEmail!,
        privateKey: config.firebasePrivateKey!.replace(/\\n/g, '\n'),
      }),
    });

  firebaseAuthInstance = getAuth(firebaseApp);
  return firebaseAuthInstance;
}

export function getDb(): Firestore {
  if (!isFirebaseConfigured()) {
    throw new Error(
      'Firebase chưa cấu hình. Điền FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY trong backend/.env',
    );
  }

  if (firestoreInstance) return firestoreInstance;

  const firebaseApp =
    getApps()[0] ??
    initializeApp({
      credential: cert({
        projectId: config.firebaseProjectId!,
        clientEmail: config.firebaseClientEmail!,
        privateKey: config.firebasePrivateKey!.replace(/\\n/g, '\n'),
      }),
    });

  firestoreInstance = getFirestore(firebaseApp);
  return firestoreInstance;
}

export function isFirebaseReady(): boolean {
  return isFirebaseConfigured();
}

export function getStorageBucket() {
  if (!isFirebaseConfigured()) {
    throw new Error(
      'Firebase chưa cấu hình. Điền FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY trong backend/.env',
    );
  }

  const firebaseApp =
    getApps()[0] ??
    initializeApp({
      credential: cert({
        projectId: config.firebaseProjectId!,
        clientEmail: config.firebaseClientEmail!,
        privateKey: config.firebasePrivateKey!.replace(/\\n/g, '\n'),
      }),
    });

  const bucketName = `${config.firebaseProjectId}.firebasestorage.app`;
  return getStorage(firebaseApp).bucket(bucketName);
}
