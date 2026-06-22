/**
 * MoMo Payment Integration Test Script
 * 
 * Tests the backend MoMo payment endpoints with mocked Firebase.
 * 
 * Run with: cd backend && npx ts-node scripts/test-momo.ts
 * 
 * Requirements:
 * - Backend server must be running on port 3000
 * - MoMo credentials must be configured in .env (or test will skip real MoMo calls)
 */

import axios, { AxiosInstance } from 'axios';
import { createHmac } from 'crypto';
import jwt from 'jsonwebtoken';

// ============================================================================
// MOCK FIREBASE BEFORE ANY IMPORTS
// ============================================================================
// We need to mock Firebase before importing any services that use it

const mockCollections: Map<string, Map<string, Record<string, any>>> = new Map();

function getCollectionPath(path: string): { collection: string; docId?: string } {
  const parts = path.split('/');
  if (parts.length % 2 === 0) {
    const docId = parts.pop();
    return { collection: parts.join('/'), docId };
  }
  return { collection: path };
}

class MockDocumentReference {
  private _path: string;
  private collectionPath: string;
  private docId: string;

  constructor(path: string) {
    this._path = path;
    const { collection, docId } = getCollectionPath(path);
    this.collectionPath = collection;
    this.docId = docId || '';
  }

  get id(): string {
    return this.docId;
  }

  get path(): string {
    return this._path;
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
    return new MockCollectionReference(`${this._path}/${path}`);
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

const mockDb = new MockFirestore();

// Clear all mock data
function clearMockData(): void {
  mockCollections.clear();
}

// Set mock user data
function setMockUser(userId: string, userData: Record<string, any>): void {
  let colData = mockCollections.get('users');
  if (!colData) {
    colData = new Map();
    mockCollections.set('users', colData);
  }
  colData.set(userId, userData);
}

// ============================================================================
// LOAD ENVIRONMENT & CONFIG (needs to happen after mock setup)
// ============================================================================

process.env.NODE_ENV = 'test';
process.env.PORT = '3000';
process.env.JWT_SECRET = 'test-jwt-secret-for-testing';
process.env.MOMO_IPN_URL = 'https://test-webhook.example.com/momo/ipn';
process.env.MOMO_PARTNER_CODE = 'MOMOTEST1';
process.env.MOMO_ACCESS_KEY = 'test-access-key';
process.env.MOMO_SECRET_KEY = 'test-secret-key-for-hmac';
process.env.MOMO_REDIRECT_URL = 'sfinity://payment-callback';
process.env.MOMO_BASE_URL = 'https://test-payment.momo.vn';
process.env.API_BASE_URL = 'http://localhost:3000';

// Mock Firebase module before any imports
jest.mock('../src/lib/firebase', () => ({
  getDb: () => mockDb,
  getFirebaseAuth: () => ({}),
  isFirebaseReady: () => true,
  getApps: () => [],
  getApp: () => null,
  initializeApp: () => null,
  cert: () => null,
  getAuth: () => ({}),
  getFirestore: () => mockDb,
}));

// Now import the modules that depend on firebase
import { config } from '../src/lib/config';
import { buildRawSignature, signWithSecret, verifySignature, newMomoOrderId } from '../src/lib/momo';

// ============================================================================
// TEST CONFIGURATION
// ============================================================================

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';
const TEST_USER_ID = 'test-user-001';
const TEST_USER_EMAIL = 'test@example.com';

// Test results tracking
interface TestResult {
  name: string;
  passed: boolean;
  error?: string;
  duration: number;
  details?: any;
}

const testResults: TestResult[] = [];

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function log(message: string, type: 'info' | 'success' | 'error' | 'warn' | 'test' = 'info'): void {
  const prefix = {
    info: '📝',
    success: '✅',
    error: '❌',
    warn: '⚠️',
    test: '🔄',
  }[type];
  console.log(`${prefix} ${message}`);
}

function generateTestJwt(userId: string, email: string): string {
  return jwt.sign({ sub: userId, email }, config.jwtSecret, { expiresIn: '1h' });
}

function generateMoMoSignature(params: Record<string, string | number>): string {
  const rawSignature = buildRawSignature(params as Record<string, string>);
  return signWithSecret(rawSignature);
}

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ============================================================================
// TEST FUNCTIONS
// ============================================================================

async function testMoMoSignatureGeneration(): Promise<void> {
  const startTime = Date.now();
  log('Testing MoMo signature generation (HMAC-SHA256)...', 'test');

  try {
    // Test parameters as per MoMo API documentation
    const params: Record<string, string> = {
      accessKey: 'test-access-key',
      amount: '49000',
      extraData: '',
      ipnUrl: 'https://test.example.com/ipn',
      orderId: 'sfvip_123456_abc123',
      orderInfo: 'Thanh toan goi Pro - 1 thang - Sfinity',
      partnerCode: 'MOMOTEST1',
      redirectUrl: 'sfinity://payment-callback',
      requestId: 'req_123456_xyz789',
      requestType: 'captureWallet',
    };

    // Generate signature
    const rawSignature = buildRawSignature(params);
    const expectedRawSignature =
      'accessKey=test-access-key&amount=49000&extraData=&ipnUrl=https://test.example.com/ipn&orderId=sfvip_123456_abc123&orderInfo=Thanh toan goi Pro - 1 thang - Sfinity&partnerCode=MOMOTEST1&redirectUrl=sfinity://payment-callback&requestId=req_123456_xyz789&requestType=captureWallet';

    // Verify raw signature format (keys are sorted alphabetically)
    if (rawSignature !== expectedRawSignature) {
      throw new Error(
        `Raw signature mismatch.\nExpected: ${expectedRawSignature}\nGot: ${rawSignature}`,
      );
    }

    // Verify HMAC-SHA256 signature
    const signature = signWithSecret(rawSignature);
    if (!signature || signature.length !== 64) {
      throw new Error(`Invalid signature length: ${signature.length}. Expected 64 hex characters.`);
    }

    // Verify signature matches expected HMAC-SHA256 output
    const expectedSignature = createHmac('sha256', config.momoSecretKey)
      .update(rawSignature)
      .digest('hex');
    if (signature !== expectedSignature) {
      throw new Error(
        `Signature mismatch.\nExpected: ${expectedSignature}\nGot: ${signature}`,
      );
    }

    // Test signature verification
    const paramsWithSignature = { ...params, signature };
    const isValid = verifySignature(paramsWithSignature, signature);
    if (!isValid) {
      throw new Error('Signature verification failed');
    }

    // Test invalid signature rejection
    const invalidSig = 'a'.repeat(64);
    const isInvalid = verifySignature(params, invalidSig);
    if (isInvalid) {
      throw new Error('Invalid signature was incorrectly accepted');
    }

    // Test newMomoOrderId generation
    const orderId = newMomoOrderId('sfvip');
    if (!orderId.startsWith('sfvip_')) {
      throw new Error(`Invalid orderId format: ${orderId}`);
    }

    const parts = orderId.split('_');
    if (parts.length !== 3) {
      throw new Error(`OrderId should have 3 parts: ${orderId}`);
    }

    const duration = Date.now() - startTime;
    testResults.push({
      name: 'MoMo Signature Generation (HMAC-SHA256)',
      passed: true,
      duration,
      details: { signatureLength: signature.length, orderId },
    });
    log(`Signature generation test PASSED (${duration}ms)`, 'success');
  } catch (error: any) {
    const duration = Date.now() - startTime;
    testResults.push({
      name: 'MoMo Signature Generation (HMAC-SHA256)',
      passed: false,
      error: error.message,
      duration,
    });
    log(`Signature generation test FAILED: ${error.message}`, 'error');
  }
}

async function testPaymentCreationEndpoint(api: AxiosInstance, jwtToken: string): Promise<{ orderId?: string; requestId?: string }> {
  const startTime = Date.now();
  log('Testing payment creation endpoint (POST /api/payments/momo/create)...', 'test');

  try {
    const response = await api.post('/api/payments/momo/create', {
      planId: 'pro',
      cycle: 'monthly',
    }, {
      headers: {
        Authorization: `Bearer ${jwtToken}`,
        'Content-Type': 'application/json',
      },
    });

    const duration = Date.now() - startTime;

    if (response.status !== 200) {
      throw new Error(`Expected status 200, got ${response.status}: ${JSON.stringify(response.data)}`);
    }

    const { orderId, requestId, amount, payUrl, deeplink, qrCodeUrl } = response.data;

    if (!orderId || !requestId) {
      throw new Error(`Missing orderId or requestId in response: ${JSON.stringify(response.data)}`);
    }

    if (amount !== 49000) {
      throw new Error(`Expected amount 49000 (Pro monthly), got ${amount}`);
    }

    // Check if payUrl exists (might be empty in sandbox mode without proper credentials)
    if (!payUrl && !deeplink && !qrCodeUrl) {
      log('Note: No payment URLs returned - MoMo sandbox may not be fully configured', 'warn');
    }

    // Verify transaction was created in mock Firestore
    const txData = mockCollections.get('payment_transactions')?.get(orderId);
    if (!txData) {
      throw new Error(`Transaction not found in mock Firestore for orderId: ${orderId}`);
    }

    if (txData.status !== 'PENDING') {
      throw new Error(`Expected PENDING status, got ${txData.status}`);
    }

    testResults.push({
      name: 'Payment Creation Endpoint (POST /api/payments/momo/create)',
      passed: true,
      duration,
      details: { orderId, requestId, amount, status: txData.status },
    });
    log(`Payment creation test PASSED (${duration}ms) - OrderId: ${orderId}`, 'success');

    return { orderId, requestId };
  } catch (error: any) {
    const duration = Date.now() - startTime;
    const errorMsg = error.response?.data?.message || error.message;
    testResults.push({
      name: 'Payment Creation Endpoint (POST /api/payments/momo/create)',
      passed: false,
      error: errorMsg,
      duration,
    });
    log(`Payment creation test FAILED: ${errorMsg}`, 'error');
    if (error.response) {
      log(`Response data: ${JSON.stringify(error.response.data)}`, 'error');
    }
    return {};
  }
}

async function testIpnEndpoint(api: AxiosInstance): Promise<{ successIpn?: boolean; failedIpn?: boolean }> {
  log('Testing IPN endpoint (POST /api/payments/momo/ipn)...', 'test');

  // Test 1: Successful payment IPN
  try {
    const startTime = Date.now();
    
    // Get a pending transaction to use for IPN testing
    const txColData = mockCollections.get('payment_transactions');
    const pendingTx = txColData ? Array.from(txColData.values()).find((tx: any) => tx.status === 'PENDING') : null;

    if (!pendingTx) {
      log('No pending transaction found for IPN test - creating one first', 'warn');
      // Create a transaction manually for IPN testing
      const testOrderId = newMomoOrderId('ipntest');
      await mockDb.collection('payment_transactions').doc(testOrderId).set({
        orderId: testOrderId,
        requestId: newMomoOrderId('req'),
        userId: TEST_USER_ID,
        planId: 'pro',
        cycle: 'monthly',
        amount: 49000,
        orderInfo: 'Thanh toan goi Pro - 1 thang - Sfinity',
        status: 'PENDING',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }

    const txToTest = pendingTx || mockCollections.get('payment_transactions')?.values().next().value;
    const orderId = txToTest?.orderId;

    if (!orderId) {
      throw new Error('No transaction available for IPN testing');
    }

    // Build valid IPN payload with signature
    const ipnParams: Record<string, string> = {
      partnerCode: config.momoPartnerCode,
      orderId: orderId,
      requestId: txToTest.requestId,
      amount: String(txToTest.amount),
      orderInfo: txToTest.orderInfo,
      orderType: 'captureWallet',
      transId: '1234567890',
      resultCode: '0', // Success
      message: 'Thanh toan thanh cong',
      payType: 'app',
      responseTime: String(Date.now()),
      extraData: '',
    };

    const ipnSignature = generateMoMoSignature(ipnParams);
    const ipnPayload = { ...ipnParams, signature: ipnSignature };

    const response = await api.post('/api/payments/momo/ipn', ipnPayload, {
      headers: { 'Content-Type': 'application/json' },
    });

    const duration = Date.now() - startTime;

    if (response.status !== 200) {
      throw new Error(`Expected status 200, got ${response.status}`);
    }

    const { resultCode, message } = response.data;
    if (resultCode !== 0) {
      throw new Error(`Expected resultCode 0, got ${resultCode}: ${message}`);
    }

    // Verify transaction was updated in Firestore
    const txData = mockCollections.get('payment_transactions')?.get(orderId);
    if (txData?.status !== 'SUCCESS') {
      throw new Error(`Transaction status not updated to SUCCESS. Current: ${txData?.status}`);
    }

    testResults.push({
      name: 'IPN Endpoint - Success Payment (POST /api/payments/momo/ipn)',
      passed: true,
      duration,
      details: { orderId, resultCode, message },
    });
    log(`Success IPN test PASSED (${duration}ms) - OrderId: ${orderId}`, 'success');

    // Test 2: Failed payment IPN
    await testFailedPaymentIpn(api, orderId);

    return { successIpn: true, failedIpn: true };
  } catch (error: any) {
    const duration = Date.now() - startTime;
    const errorMsg = error.response?.data?.message || error.message;
    testResults.push({
      name: 'IPN Endpoint - Success Payment (POST /api/payments/momo/ipn)',
      passed: false,
      error: errorMsg,
      duration,
    });
    log(`Success IPN test FAILED: ${errorMsg}`, 'error');
    return {};
  }
}

async function testFailedPaymentIpn(api: AxiosInstance, existingOrderId: string): Promise<void> {
  const startTime = Date.now();
  log('Testing IPN endpoint - Failed payment...', 'test');

  try {
    // Create a new pending transaction for failed IPN test
    const failedOrderId = newMomoOrderId('failedtest');
    await mockDb.collection('payment_transactions').doc(failedOrderId).set({
      orderId: failedOrderId,
      requestId: newMomoOrderId('req'),
      userId: TEST_USER_ID,
      planId: 'pro',
      cycle: 'monthly',
      amount: 49000,
      orderInfo: 'Thanh toan goi Pro - 1 thang - Sfinity',
      status: 'PENDING',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    // Build failed IPN payload
    const ipnParams: Record<string, string> = {
      partnerCode: config.momoPartnerCode,
      orderId: failedOrderId,
      requestId: newMomoOrderId('req'),
      amount: '49000',
      orderInfo: 'Thanh toan goi Pro - 1 thang - Sfinity',
      orderType: 'captureWallet',
      transId: '0',
      resultCode: '1006', // User cancel
      message: 'Khach hang huy giao dich',
      payType: 'app',
      responseTime: String(Date.now()),
      extraData: '',
    };

    const ipnSignature = generateMoMoSignature(ipnParams);
    const ipnPayload = { ...ipnParams, signature: ipnSignature };

    const response = await api.post('/api/payments/momo/ipn', ipnPayload, {
      headers: { 'Content-Type': 'application/json' },
    });

    const duration = Date.now() - startTime;

    if (response.status !== 200) {
      throw new Error(`Expected status 200, got ${response.status}`);
    }

    // Verify transaction was updated to FAILED
    const txData = mockCollections.get('payment_transactions')?.get(failedOrderId);
    if (txData?.status !== 'FAILED') {
      throw new Error(`Transaction status not updated to FAILED. Current: ${txData?.status}`);
    }

    testResults.push({
      name: 'IPN Endpoint - Failed Payment (POST /api/payments/momo/ipn)',
      passed: true,
      duration,
      details: { orderId: failedOrderId, resultCode: '1006' },
    });
    log(`Failed IPN test PASSED (${duration}ms)`, 'success');
  } catch (error: any) {
    const duration = Date.now() - startTime;
    const errorMsg = error.response?.data?.message || error.message;
    testResults.push({
      name: 'IPN Endpoint - Failed Payment (POST /api/payments/momo/ipn)',
      passed: false,
      error: errorMsg,
      duration,
    });
    log(`Failed IPN test FAILED: ${errorMsg}`, 'error');
  }
}

async function testTransactionStatusEndpoint(api: AxiosInstance, jwtToken: string, orderId?: string): Promise<void> {
  const startTime = Date.now();
  log('Testing transaction status endpoint (GET /api/payments/momo/status/:orderId)...', 'test');

  try {
    // Find a transaction to test with
    let testOrderId = orderId;
    if (!testOrderId) {
      const txColData = mockCollections.get('payment_transactions');
      if (txColData && txColData.size > 0) {
        testOrderId = Array.from(txColData.keys())[0];
      }
    }

    if (!testOrderId) {
      throw new Error('No transaction available for status check');
    }

    const response = await api.get(`/api/payments/momo/status/${testOrderId}`, {
      headers: { Authorization: `Bearer ${jwtToken}` },
    });

    const duration = Date.now() - startTime;

    if (response.status !== 200) {
      throw new Error(`Expected status 200, got ${response.status}`);
    }

    const { orderId: respOrderId, status, resultCode, amount, planId, cycle } = response.data;

    if (respOrderId !== testOrderId) {
      throw new Error(`Order ID mismatch. Expected ${testOrderId}, got ${respOrderId}`);
    }

    if (!['PENDING', 'SUCCESS', 'FAILED', 'CANCELED'].includes(status)) {
      throw new Error(`Invalid status: ${status}`);
    }

    testResults.push({
      name: 'Transaction Status Endpoint (GET /api/payments/momo/status/:orderId)',
      passed: true,
      duration,
      details: { orderId: testOrderId, status, resultCode, amount, planId, cycle },
    });
    log(`Transaction status test PASSED (${duration}ms) - Status: ${status}`, 'success');
  } catch (error: any) {
    const duration = Date.now() - startTime;
    const errorMsg = error.response?.data?.message || error.message;
    testResults.push({
      name: 'Transaction Status Endpoint (GET /api/payments/momo/status/:orderId)',
      passed: false,
      error: errorMsg,
      duration,
    });
    log(`Transaction status test FAILED: ${errorMsg}`, 'error');
  }
}

async function testSubscriptionStatusEndpoint(api: AxiosInstance, jwtToken: string): Promise<void> {
  const startTime = Date.now();
  log('Testing subscription status endpoint (GET /api/payments/subscription/me)...', 'test');

  try {
    // First, set up VIP status for the test user (simulate successful payment)
    await mockDb.collection('users').doc(TEST_USER_ID).set({
      email: TEST_USER_EMAIL,
      isVip: true,
      vipPlanId: 'pro',
      vipCycle: 'monthly',
      vipExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
      vipSource: 'momo',
      status: 'ACTIVE',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const response = await api.get('/api/payments/subscription/me', {
      headers: { Authorization: `Bearer ${jwtToken}` },
    });

    const duration = Date.now() - startTime;

    if (response.status !== 200) {
      throw new Error(`Expected status 200, got ${response.status}`);
    }

    const { isVip, cycle, planId, expiresAt, source } = response.data;

    if (typeof isVip !== 'boolean') {
      throw new Error(`Invalid isVip value: ${isVip}`);
    }

    if (isVip) {
      if (cycle !== 'monthly') {
        throw new Error(`Expected cycle 'monthly', got '${cycle}'`);
      }
      if (planId !== 'pro') {
        throw new Error(`Expected planId 'pro', got '${planId}'`);
      }
      if (source !== 'momo') {
        throw new Error(`Expected source 'momo', got '${source}'`);
      }
      if (!expiresAt) {
        throw new Error('Expected expiresAt to be present for VIP user');
      }
    }

    testResults.push({
      name: 'Subscription Status Endpoint (GET /api/payments/subscription/me)',
      passed: true,
      duration,
      details: { isVip, cycle, planId, source },
    });
    log(`Subscription status test PASSED (${duration}ms) - VIP: ${isVip}`, 'success');

    // Test non-VIP user
    await testNonVipSubscriptionStatus(api, jwtToken);
  } catch (error: any) {
    const duration = Date.now() - startTime;
    const errorMsg = error.response?.data?.message || error.message;
    testResults.push({
      name: 'Subscription Status Endpoint (GET /api/payments/subscription/me)',
      passed: false,
      error: errorMsg,
      duration,
    });
    log(`Subscription status test FAILED: ${errorMsg}`, 'error');
  }
}

async function testNonVipSubscriptionStatus(api: AxiosInstance, jwtToken: string): Promise<void> {
  const startTime = Date.now();
  log('Testing subscription status endpoint - Non-VIP user...', 'test');

  try {
    // Set up non-VIP user
    await mockDb.collection('users').doc(TEST_USER_ID).set({
      email: TEST_USER_EMAIL,
      isVip: false,
      status: 'ACTIVE',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const response = await api.get('/api/payments/subscription/me', {
      headers: { Authorization: `Bearer ${jwtToken}` },
    });

    const duration = Date.now() - startTime;

    if (response.status !== 200) {
      throw new Error(`Expected status 200, got ${response.status}`);
    }

    const { isVip } = response.data;

    if (isVip !== false) {
      throw new Error(`Expected isVip to be false for non-VIP user, got ${isVip}`);
    }

    testResults.push({
      name: 'Subscription Status Endpoint - Non-VIP (GET /api/payments/subscription/me)',
      passed: true,
      duration,
      details: { isVip: false },
    });
    log(`Non-VIP subscription status test PASSED (${duration}ms)`, 'success');
  } catch (error: any) {
    const duration = Date.now() - startTime;
    const errorMsg = error.response?.data?.message || error.message;
    testResults.push({
      name: 'Subscription Status Endpoint - Non-VIP (GET /api/payments/subscription/me)',
      passed: false,
      error: errorMsg,
      duration,
    });
    log(`Non-VIP subscription status test FAILED: ${errorMsg}`, 'error');
  }
}

async function testAuthenticationRequirements(api: AxiosInstance): Promise<void> {
  log('Testing authentication requirements...', 'test');

  // Test 1: Payment creation without JWT
  try {
    const startTime = Date.now();
    const response = await api.post('/api/payments/momo/create', {
      planId: 'pro',
      cycle: 'monthly',
    }).catch((e) => e.response);

    const duration = Date.now() - startTime;

    if (response?.status !== 401) {
      throw new Error(`Expected status 401, got ${response?.status}`);
    }

    testResults.push({
      name: 'Auth - Payment Creation Without JWT',
      passed: true,
      duration,
    });
    log(`Auth test (payment without JWT) PASSED - correctly rejected`, 'success');
  } catch (error: any) {
    testResults.push({
      name: 'Auth - Payment Creation Without JWT',
      passed: false,
      error: error.message,
      duration: 0,
    });
    log(`Auth test FAILED: ${error.message}`, 'error');
  }

  // Test 2: Payment creation with invalid JWT
  try {
    const startTime = Date.now();
    const response = await api.post('/api/payments/momo/create', {
      planId: 'pro',
      cycle: 'monthly',
    }, {
      headers: { Authorization: 'Bearer invalid-token' },
    }).catch((e) => e.response);

    const duration = Date.now() - startTime;

    if (response?.status !== 401) {
      throw new Error(`Expected status 401, got ${response?.status}`);
    }

    testResults.push({
      name: 'Auth - Payment Creation With Invalid JWT',
      passed: true,
      duration,
    });
    log(`Auth test (payment with invalid JWT) PASSED - correctly rejected`, 'success');
  } catch (error: any) {
    testResults.push({
      name: 'Auth - Payment Creation With Invalid JWT',
      passed: false,
      error: error.message,
      duration: 0,
    });
    log(`Auth test FAILED: ${error.message}`, 'error');
  }

  // Test 3: IPN without signature (should still return 200, but with error)
  try {
    const startTime = Date.now();
    const response = await api.post('/api/payments/momo/ipn', {
      partnerCode: 'TEST',
      orderId: 'test',
      resultCode: '0',
    }).catch((e) => e.response);

    const duration = Date.now() - startTime;

    if (response?.status !== 200) {
      throw new Error(`Expected status 200 (IPN always returns 200), got ${response?.status}`);
    }

    const { resultCode } = response?.data || {};
    if (resultCode !== 97) {
      throw new Error(`Expected resultCode 97 (invalid signature), got ${resultCode}`);
    }

    testResults.push({
      name: 'Auth - IPN Without Valid Signature',
      passed: true,
      duration,
    });
    log(`IPN signature validation test PASSED - correctly returned error code 97`, 'success');
  } catch (error: any) {
    testResults.push({
      name: 'Auth - IPN Without Valid Signature',
      passed: false,
      error: error.message,
      duration: 0,
    });
    log(`IPN signature validation test FAILED: ${error.message}`, 'error');
  }
}

// ============================================================================
// MAIN TEST RUNNER
// ============================================================================

async function runTests(): Promise<void> {
  console.log('\n' + '='.repeat(70));
  console.log('   MoMo Payment Integration Test Suite');
  console.log('   MoMo Thanh Toan Integration Test Suite');
  console.log('='.repeat(70) + '\n');

  log(`API Base URL: ${API_BASE_URL}`);
  log(`Test User ID: ${TEST_USER_ID}`);
  log(`MoMo Environment: ${config.momoEnv}`);
  log(`MoMo Partner Code: ${config.momoPartnerCode || '(not set)'}`);
  log('');

  // Initialize mock data
  clearMockData();
  setMockUser(TEST_USER_ID, {
    email: TEST_USER_EMAIL,
    status: 'ACTIVE',
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  // Create HTTP client
  const api = axios.create({
    baseURL: API_BASE_URL,
    timeout: 30000,
    validateStatus: () => true, // Don't throw on any status
  });

  // Generate test JWT
  const jwtToken = generateTestJwt(TEST_USER_ID, TEST_USER_EMAIL);
  log(`Generated test JWT token: ${jwtToken.substring(0, 20)}...`);
  log('');

  // Run tests sequentially
  try {
    // Test 1: MoMo Signature Generation
    await testMoMoSignatureGeneration();
    console.log('');

    // Test 2: Payment Creation
    const { orderId } = await testPaymentCreationEndpoint(api, jwtToken);
    console.log('');

    // Test 3: IPN Endpoint
    await testIpnEndpoint(api);
    console.log('');

    // Test 4: Transaction Status
    await testTransactionStatusEndpoint(api, jwtToken, orderId);
    console.log('');

    // Test 5: Subscription Status
    await testSubscriptionStatusEndpoint(api, jwtToken);
    console.log('');

    // Test 6: Authentication Requirements
    await testAuthenticationRequirements(api);
    console.log('');

  } catch (error: any) {
    log(`Fatal error during tests: ${error.message}`, 'error');
    console.error(error);
  }

  // Print summary
  printSummary();
}

function printSummary(): void {
  console.log('\n' + '='.repeat(70));
  console.log('   TEST SUMMARY / TOM TAT KET QUA');
  console.log('='.repeat(70));

  const passed = testResults.filter((r) => r.passed).length;
  const failed = testResults.filter((r) => !r.passed).length;
  const total = testResults.length;
  const totalDuration = testResults.reduce((sum, r) => sum + r.duration, 0);

  console.log(`\nTotal Tests: ${total} | Passed: ${passed} | Failed: ${failed}`);
  console.log(`Total Duration: ${totalDuration}ms`);
  console.log('');

  console.log('Details:');
  console.log('-'.repeat(70));

  for (const result of testResults) {
    const status = result.passed ? '✅ PASS' : '❌ FAIL';
    const duration = `${result.duration}ms`;
    console.log(`${status.padEnd(10)} ${result.name}`);
    console.log(`           Duration: ${duration.padEnd(10)}`);
    if (!result.passed && result.error) {
      console.log(`           Error: ${result.error}`);
    }
    if (result.details) {
      console.log(`           Details: ${JSON.stringify(result.details)}`);
    }
    console.log('');
  }

  console.log('='.repeat(70));
  if (failed === 0) {
    console.log('🎉 ALL TESTS PASSED! / TAT CA CAC BAI KIEM TRA DA THANH CONG!');
  } else {
    console.log(`⚠️  ${failed} test(s) failed. Please review the errors above.`);
    console.log(`Luu y: ${failed} bai kiem tra that bai. Vui long kiem tra loi o tren.`);
  }
  console.log('='.repeat(70) + '\n');
}

// Run the tests
runTests().catch((error) => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
