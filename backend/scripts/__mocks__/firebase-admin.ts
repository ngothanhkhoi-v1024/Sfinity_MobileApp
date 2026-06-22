/**
 * Mock Firebase Admin SDK for testing purposes.
 * This module mocks the Firestore functionality without requiring real Firebase credentials.
 */

// In-memory storage for mock data
const mockCollections: Map<string, Map<string, Record<string, any>>> = new Map();

function getCollectionPath(path: string): { collection: string; docId?: string } {
  const parts = path.split('/');
  if (parts.length % 2 === 0) {
    // Even number of parts means last part is docId
    const docId = parts.pop();
    return { collection: parts.join('/'), docId };
  }
  return { collection: path };
}

class MockDocumentReference {
  private path: string;
  private collectionPath: string;
  private docId: string;

  constructor(path: string) {
    this.path = path;
    const { collection, docId } = getCollectionPath(path);
    this.collectionPath = collection;
    this.docId = docId || '';
  }

  get id(): string {
    return this.docId;
  }

  get path(): string {
    return this.path;
  }

  async get(): Promise<MockDocumentSnapshot> {
    const colData = mockCollections.get(this.collectionPath);
    const docData = colData?.get(this.docId);
    return new MockDocumentSnapshot(this.docId, docData || null);
  }

  async set(data: Record<string, any>): Promise<void> {
    let colData = mockCollections.get(this.collectionPath);
    if (!colData) {
      colData = new Map();
      mockCollections.set(this.collectionPath, colData);
    }
    colData.set(this.docId, { ...data });
  }

  async update(data: Record<string, any>): Promise<void> {
    const colData = mockCollections.get(this.collectionPath);
    const existing = colData?.get(this.docId);
    if (!existing) {
      throw new Error(`Document not found: ${this.path}`);
    }
    colData!.set(this.docId, { ...existing, ...data });
  }

  async delete(): Promise<void> {
    const colData = mockCollections.get(this.collectionPath);
    colData?.delete(this.docId);
  }

  collection(path: string): MockCollectionReference {
    return new MockCollectionReference(`${this.path}/${path}`);
  }
}

class MockDocumentSnapshot {
  exists: boolean;
  id: string;
  private data_: Record<string, any> | null;

  constructor(id: string, data: Record<string, any> | null) {
    this.id = id;
    this.exists = data !== null;
    this.data_ = data;
  }

  data(): Record<string, any> | undefined {
    return this.data_;
  }
}

class MockCollectionReference {
  private path: string;

  constructor(path: string) {
    this.path = path;
  }

  doc(id?: string): MockDocumentReference {
    return new MockDocumentReference(`${this.path}/${id || 'auto_' + Date.now()}`);
  }

  add(data: Record<string, any>): Promise<MockDocumentReference> {
    const id = 'auto_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8);
    const ref = this.doc(id);
    return ref.set(data).then(() => ref);
  }

  async get(): Promise<MockQuerySnapshot> {
    const colData = mockCollections.get(this.path);
    const docs: MockDocumentSnapshot[] = [];
    if (colData) {
      for (const [id, data] of colData) {
        docs.push(new MockDocumentSnapshot(id, data));
      }
    }
    return new MockQuerySnapshot(docs);
  }

  where(): MockQuery {
    return new MockQuery(this.path);
  }
}

class MockQuerySnapshot {
  docs: MockDocumentSnapshot[];
  empty: boolean;

  constructor(docs: MockDocumentSnapshot[]) {
    this.docs = docs;
    this.empty = docs.length === 0;
  }
}

class MockQuery {
  private path: string;

  constructor(path: string) {
    this.path = path;
  }

  async get(): Promise<MockQuerySnapshot> {
    const colData = mockCollections.get(this.path);
    const docs: MockDocumentSnapshot[] = [];
    if (colData) {
      for (const [id, data] of colData) {
        docs.push(new MockDocumentSnapshot(id, data));
      }
    }
    return new MockQuerySnapshot(docs);
  }
}

class MockBatch {
  private writes: Array<{ ref: MockDocumentReference; data: Record<string, any>; type: 'set' | 'update' }> = [];

  set(ref: MockDocumentReference, data: Record<string, any>): MockBatch {
    this.writes.push({ ref, data, type: 'set' });
    return this;
  }

  update(ref: MockDocumentReference, data: Record<string, any>): MockBatch {
    this.writes.push({ ref, data, type: 'update' });
    return this;
  }

  delete(): MockBatch {
    return this;
  }

  async commit(): Promise<void> {
    for (const write of this.writes) {
      if (write.type === 'set') {
        await write.ref.set(write.data);
      } else {
        await write.ref.update(write.data);
      }
    }
  }
}

class MockFirestore {
  collection(path: string): MockCollectionReference {
    return new MockCollectionReference(path);
  }

  batch(): MockBatch {
    return new MockBatch();
  }

  doc(path: string): MockDocumentReference {
    return new MockDocumentReference(path);
  }
}

// Create a singleton mock Firestore instance
const mockDb = new MockFirestore();

// Mock firebase-admin module exports
export const getApps = () => [];
export const getApp = () => null as any;
export const initializeApp = () => null as any;
export const cert = () => null as any;
export const getAuth = () => ({} as any);
export const getFirestore = () => mockDb;
export const getDb = () => mockDb;

export default {
  getApps,
  getApp: () => null,
  initializeApp: () => null,
  cert: () => null,
  getAuth: () => ({}),
  getFirestore: () => mockDb,
};

/**
 * Utility function to clear all mock data between tests.
 * Call this to reset the in-memory database.
 */
export function clearMockData(): void {
  mockCollections.clear();
}

/**
 * Utility function to set mock data directly (useful for test setup).
 * @param collectionPath - e.g., 'users' or 'payment_transactions'
 * @param docId - document ID
 * @param data - document data
 */
export function setMockData(collectionPath: string, docId: string, data: Record<string, any>): void {
  let colData = mockCollections.get(collectionPath);
  if (!colData) {
    colData = new Map();
    mockCollections.set(collectionPath, colData);
  }
  colData.set(docId, data);
}

/**
 * Utility function to get mock data directly.
 */
export function getMockData(collectionPath: string, docId: string): Record<string, any> | undefined {
  return mockCollections.get(collectionPath)?.get(docId);
}
