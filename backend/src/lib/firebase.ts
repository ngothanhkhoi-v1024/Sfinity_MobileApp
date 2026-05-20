import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

import { config } from './config';

const firebaseApp =
    getApps()[0] ??
    initializeApp({
        credential: cert({
            projectId: config.firebaseProjectId,
            clientEmail: config.firebaseClientEmail,
            privateKey: config.firebasePrivateKey?.replace(/\\n/g, '\n'),
        }),
    });

export const firebaseAuth = getAuth(firebaseApp);