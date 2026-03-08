'use strict';

/**
 * Trust System Notification Scheduler — Unit Tests
 *
 * Covers:
 *   scheduleJob        — task creation, tracking doc write, jobId return
 *   cancelJob          — PENDING cancel, idempotent no-op, NOT_FOUND swallow, error rethrow
 *   cancelGameJobs     — empty result, multi-cancel, count, NOT_FOUND swallow
 *   processScheduledTrustNotificationHandler
 *                      — 400 on bad body, NOT_FOUND doc, CANCELLED skip,
 *                        host_not_checked_in condition (met/not met),
 *                        always condition, routeNotification call, EXECUTED write
 *
 * Run: npx jest test/scheduler.test.js --verbose
 */

// ── Shared mock state ─────────────────────────────────────────────────────────

let mockDb;

// Shared spies reassigned in makeMockDb; exposed for assertion
let docSetSpy;
let docUpdateSpy;
let docGetSpy;
let colQueryGetSpy;

// ── Mock: @google-cloud/tasks ─────────────────────────────────────────────────

let mockCreateTask;
let mockDeleteTask;
let mockQueuePath;

jest.mock('@google-cloud/tasks', () => {
  mockCreateTask = jest.fn();
  mockDeleteTask = jest.fn();
  mockQueuePath  = jest.fn((project, location, queue) =>
    `projects/${project}/locations/${location}/queues/${queue}`,
  );

  function MockCloudTasksClient() {}
  MockCloudTasksClient.prototype.createTask  = (...args) => mockCreateTask(...args);
  MockCloudTasksClient.prototype.deleteTask  = (...args) => mockDeleteTask(...args);
  MockCloudTasksClient.prototype.queuePath   = (...args) => mockQueuePath(...args);

  return { CloudTasksClient: MockCloudTasksClient };
});

// ── Mock: firebase-admin ──────────────────────────────────────────────────────

jest.mock('firebase-admin', () => {
  const serverTimestamp = jest.fn(() => ({ _sentinel: 'SERVER_TIMESTAMP' }));
  const fromDate        = jest.fn((d) => ({ _ts: d.toISOString() }));
  const FieldValue      = { serverTimestamp };
  const Timestamp       = { fromDate };

  function mockFirestoreFn() { return mockDb; }
  mockFirestoreFn.FieldValue = FieldValue;
  mockFirestoreFn.Timestamp  = Timestamp;

  return { firestore: mockFirestoreFn };
});

// ── Mock: router ──────────────────────────────────────────────────────────────

jest.mock('../notifications/trust/router', () => ({
  routeNotification: jest.fn(),
}));

// ── Module under test ─────────────────────────────────────────────────────────

const {
  scheduleJob,
  cancelJob,
  cancelGameJobs,
  processScheduledTrustNotificationHandler,
  _resetTasksClient,
} = require('../notifications/trust/scheduler');

const { routeNotification } = require('../notifications/trust/router');

// ── Fixtures ──────────────────────────────────────────────────────────────────

const FUTURE_ISO  = '2026-03-01T14:00:00.000Z';
const FUTURE_SECS = Math.floor(new Date(FUTURE_ISO).getTime() / 1000);

function makeEvent(overrides = {}) {
  return Object.assign({
    eventId:         'evt_sched_001',
    eventType:       'host_checkin_due',
    recipientUserId: 'user_abc',
    sourceId:        'game_g1',
    data:            { course_name: 'Pebble Beach', hours_remaining: '2' },
    scheduleTime:    FUTURE_ISO,
    conditionCheck:  'always',
    isReminder:      false,
    quietHoursBypass: false,
  }, overrides);
}

const MOCK_TASK_NAME = 'projects/find-my-fourth/locations/us-west2/queues/trust-notification-scheduler/tasks/task_001';

// ── Mock DB builder ───────────────────────────────────────────────────────────

/**
 * Builds a minimal Firestore mock that covers every access pattern in scheduler.js:
 *
 *   scheduledNotifications collection:
 *     .doc()               → auto-ID doc ref (for scheduleJob)
 *     .doc(id)             → specific doc ref (for cancelJob / receiver)
 *     .where().where().get → query for cancelGameJobs
 *
 *   games collection:
 *     .doc(id).get()       → game doc (for conditionCheck in receiver)
 */
function makeMockDb({
  // scheduledNotifications .doc(id) snap
  schedDocData  = null,          // null → !snap.exists
  schedDocStatus = 'PENDING',    // status field in the snap
  schedDocTaskName = MOCK_TASK_NAME,

  // query result for cancelGameJobs
  queryDocs     = [],

  // games .doc(id) snap
  gameDocData   = null,          // null → !snap.exists
} = {}) {
  docSetSpy    = jest.fn().mockResolvedValue(undefined);
  docUpdateSpy = jest.fn().mockResolvedValue(undefined);
  docGetSpy    = jest.fn();
  colQueryGetSpy = jest.fn();

  // Auto-ID doc ref (scheduleJob uses .doc() with no arg)
  const autoIdDocRef = {
    id:     'auto_job_id_001',
    set:    docSetSpy,
    update: docUpdateSpy,
    get:    docGetSpy,
  };

  // Named doc ref (cancelJob / receiver use .doc(jobId))
  function makeNamedDocRef(id) {
    const data = schedDocData !== null
      ? Object.assign({ status: schedDocStatus, taskName: schedDocTaskName }, schedDocData)
      : null;

    const snap = {
      exists: data !== null,
      data:   () => data || {},
    };
    docGetSpy.mockResolvedValue(snap);

    return {
      id,
      set:    docSetSpy,
      update: docUpdateSpy,
      get:    docGetSpy,
    };
  }

  // Query result docs for cancelGameJobs
  const querySnapDocs = queryDocs.map((d) => ({
    data:   () => d,
    ref:    { update: jest.fn().mockResolvedValue(undefined) },
  }));

  colQueryGetSpy.mockResolvedValue({
    empty: querySnapDocs.length === 0,
    docs:  querySnapDocs,
  });

  // Game doc for conditionCheck
  const gameDocSnap = {
    exists: gameDocData !== null,
    data:   () => gameDocData || {},
  };

  const db = {
    collection: (colName) => {
      if (colName === 'scheduledNotifications') {
        return {
          // .doc() — no arg → auto-ID ref
          // .doc(id) — named ref
          doc: (id) => {
            if (id === undefined) return autoIdDocRef;
            return makeNamedDocRef(id);
          },
          where: () => ({
            where: () => ({
              get: colQueryGetSpy,
            }),
          }),
        };
      }
      if (colName === 'games') {
        return {
          doc: () => ({
            get: jest.fn().mockResolvedValue(gameDocSnap),
          }),
        };
      }
      throw new Error(`Unexpected collection: ${colName}`);
    },
  };

  return db;
}

// ── Shared setup ──────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  _resetTasksClient();

  // Restore mock implementations after clearAllMocks
  mockCreateTask = jest.fn().mockResolvedValue([{ name: MOCK_TASK_NAME }]);
  mockDeleteTask = jest.fn().mockResolvedValue([{}]);
  mockQueuePath  = jest.fn((project, location, queue) =>
    `projects/${project}/locations/${location}/queues/${queue}`,
  );

  // Re-wire the prototype methods since clearAllMocks resets everything
  const { CloudTasksClient } = require('@google-cloud/tasks');
  CloudTasksClient.prototype.createTask = (...args) => mockCreateTask(...args);
  CloudTasksClient.prototype.deleteTask = (...args) => mockDeleteTask(...args);
  CloudTasksClient.prototype.queuePath  = (...args) => mockQueuePath(...args);

  routeNotification.mockResolvedValue({ result: 'sent', sentCount: 1 });

  mockDb = makeMockDb({ schedDocData: { taskName: MOCK_TASK_NAME } });
});

// ════════════════════════════════════════════════════════════════════════════
// scheduleJob
// ════════════════════════════════════════════════════════════════════════════

describe('scheduleJob', () => {

  test('creates a Cloud Task with correct scheduleTime.seconds', async () => {
    mockDb = makeMockDb({});
    await scheduleJob(makeEvent(), mockDb);

    expect(mockCreateTask).toHaveBeenCalledTimes(1);
    const callArg = mockCreateTask.mock.calls[0][0];
    expect(callArg.task.scheduleTime.seconds).toBe(FUTURE_SECS);
  });

  test('creates task targeting the correct queue path', async () => {
    mockDb = makeMockDb({});
    await scheduleJob(makeEvent(), mockDb);

    const callArg = mockCreateTask.mock.calls[0][0];
    expect(callArg.parent).toBe(
      'projects/find-my-fourth/locations/us-west2/queues/trust-notification-scheduler',
    );
  });

  test('task body contains jobId and event as base64 JSON', async () => {
    mockDb = makeMockDb({});
    const jobId = await scheduleJob(makeEvent(), mockDb);

    const callArg = mockCreateTask.mock.calls[0][0];
    const decoded = JSON.parse(Buffer.from(callArg.task.httpRequest.body, 'base64').toString());
    expect(decoded.jobId).toBe(jobId);
    expect(decoded.event.eventType).toBe('host_checkin_due');
  });

  test('task uses OIDC auth with correct service account email', async () => {
    mockDb = makeMockDb({});
    await scheduleJob(makeEvent(), mockDb);

    const callArg = mockCreateTask.mock.calls[0][0];
    expect(callArg.task.httpRequest.oidcToken.serviceAccountEmail).toBe(
      'find-my-fourth@appspot.gserviceaccount.com',
    );
  });

  test('writes tracking doc to scheduledNotifications with PENDING status', async () => {
    mockDb = makeMockDb({});
    await scheduleJob(makeEvent(), mockDb);

    expect(docSetSpy).toHaveBeenCalledTimes(1);
    const docData = docSetSpy.mock.calls[0][0];
    expect(docData.status).toBe('PENDING');
    expect(docData.taskName).toBe(MOCK_TASK_NAME);
    expect(docData.eventType).toBe('host_checkin_due');
    expect(docData.recipientUserId).toBe('user_abc');
    expect(docData.gameId).toBe('game_g1');
    expect(docData.sourceId).toBe('game_g1');
  });

  test('tracking doc includes the full event object', async () => {
    mockDb = makeMockDb({});
    const event = makeEvent();
    await scheduleJob(event, mockDb);

    const docData = docSetSpy.mock.calls[0][0];
    expect(docData.event).toMatchObject({
      eventType:       'host_checkin_due',
      recipientUserId: 'user_abc',
      sourceId:        'game_g1',
    });
  });

  test('returns the eventId as the jobId (deterministic doc ID)', async () => {
    mockDb = makeMockDb({});
    const jobId = await scheduleJob(makeEvent(), mockDb);
    expect(jobId).toBe('evt_sched_001');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// cancelJob
// ════════════════════════════════════════════════════════════════════════════

describe('cancelJob', () => {

  test('PENDING job: deletes task, updates doc to CANCELLED, returns { cancelled: true }', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'PENDING', schedDocTaskName: MOCK_TASK_NAME });

    const result = await cancelJob('some_job_id', mockDb);

    expect(mockDeleteTask).toHaveBeenCalledTimes(1);
    expect(mockDeleteTask.mock.calls[0][0].name).toBe(MOCK_TASK_NAME);
    expect(docUpdateSpy).toHaveBeenCalledTimes(1);
    expect(docUpdateSpy.mock.calls[0][0].status).toBe('CANCELLED');
    expect(result).toEqual({ cancelled: true });
  });

  test('already CANCELLED job: returns { cancelled: false }, no deleteTask call', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'CANCELLED' });

    const result = await cancelJob('some_job_id', mockDb);

    expect(mockDeleteTask).not.toHaveBeenCalled();
    expect(docUpdateSpy).not.toHaveBeenCalled();
    expect(result).toEqual({ cancelled: false });
  });

  test('EXECUTED job: returns { cancelled: false }, no deleteTask call', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'EXECUTED' });

    const result = await cancelJob('some_job_id', mockDb);

    expect(mockDeleteTask).not.toHaveBeenCalled();
    expect(result).toEqual({ cancelled: false });
  });

  test('doc does not exist: returns { cancelled: false }', async () => {
    mockDb = makeMockDb({ schedDocData: null });

    const result = await cancelJob('nonexistent_id', mockDb);

    expect(mockDeleteTask).not.toHaveBeenCalled();
    expect(result).toEqual({ cancelled: false });
  });

  test('deleteTask throws NOT_FOUND (code 5): swallowed, doc still updated to CANCELLED', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'PENDING' });
    const notFoundErr = Object.assign(new Error('NOT_FOUND'), { code: 5 });
    mockDeleteTask.mockRejectedValue(notFoundErr);

    const result = await cancelJob('some_job_id', mockDb);

    expect(docUpdateSpy).toHaveBeenCalledTimes(1);
    expect(docUpdateSpy.mock.calls[0][0].status).toBe('CANCELLED');
    expect(result).toEqual({ cancelled: true });
  });

  test('deleteTask throws non-NOT_FOUND error: error is rethrown', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'PENDING' });
    const internalErr = Object.assign(new Error('INTERNAL'), { code: 13 });
    mockDeleteTask.mockRejectedValue(internalErr);

    await expect(cancelJob('some_job_id', mockDb)).rejects.toThrow('INTERNAL');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// cancelGameJobs
// ════════════════════════════════════════════════════════════════════════════

describe('cancelGameJobs', () => {

  test('no pending jobs for gameId: returns { count: 0 }, no deletes', async () => {
    mockDb = makeMockDb({ queryDocs: [] });

    const result = await cancelGameJobs('game_g1', mockDb);

    expect(mockDeleteTask).not.toHaveBeenCalled();
    expect(result).toEqual({ count: 0 });
  });

  test('two pending jobs: deletes both tasks, updates both docs, returns { count: 2 }', async () => {
    const jobs = [
      { taskName: 'task_name_1', status: 'PENDING' },
      { taskName: 'task_name_2', status: 'PENDING' },
    ];
    mockDb = makeMockDb({ queryDocs: jobs });

    const result = await cancelGameJobs('game_g1', mockDb);

    expect(mockDeleteTask).toHaveBeenCalledTimes(2);
    expect(result).toEqual({ count: 2 });
  });

  test('each matched doc is updated to CANCELLED', async () => {
    const jobs = [{ taskName: 'task_name_1', status: 'PENDING' }];
    mockDb = makeMockDb({ queryDocs: jobs });

    // Access the doc ref's update spy for query results
    const querySnap = await mockDb.collection('scheduledNotifications')
      .where().where().get();
    await cancelGameJobs('game_g1', mockDb);

    const docRef = querySnap.docs[0].ref;
    expect(docRef.update).toHaveBeenCalledWith(
      expect.objectContaining({ status: 'CANCELLED' }),
    );
  });

  test('deleteTask throws NOT_FOUND (code 5): swallowed, still updates doc', async () => {
    const jobs = [{ taskName: 'task_name_1', status: 'PENDING' }];
    mockDb = makeMockDb({ queryDocs: jobs });
    const notFoundErr = Object.assign(new Error('NOT_FOUND'), { code: 5 });
    mockDeleteTask.mockRejectedValue(notFoundErr);

    // Should not throw
    const result = await cancelGameJobs('game_g1', mockDb);
    expect(result).toEqual({ count: 1 });
  });

  test('deleteTask throws non-NOT_FOUND error: error is rethrown', async () => {
    const jobs = [{ taskName: 'task_name_1', status: 'PENDING' }];
    mockDb = makeMockDb({ queryDocs: jobs });
    const internalErr = Object.assign(new Error('INTERNAL'), { code: 13 });
    mockDeleteTask.mockRejectedValue(internalErr);

    await expect(cancelGameJobs('game_g1', mockDb)).rejects.toThrow('INTERNAL');
  });

});

// ════════════════════════════════════════════════════════════════════════════
// processScheduledTrustNotificationHandler
// ════════════════════════════════════════════════════════════════════════════

/** Builds a minimal Express-like req/res pair for testing the HTTP handler. */
function makeReqRes(body = {}) {
  const res = {
    _status: null,
    _body:   null,
    status:  function(s) { this._status = s; return this; },
    send:    function(b) { this._body   = b; return this; },
  };
  const req = { body };
  return { req, res };
}

describe('processScheduledTrustNotificationHandler', () => {

  test('missing jobId in body: returns 400', async () => {
    const { req, res } = makeReqRes({ event: makeEvent() });
    mockDb = makeMockDb({});
    await processScheduledTrustNotificationHandler(req, res);
    expect(res._status).toBe(400);
    expect(routeNotification).not.toHaveBeenCalled();
  });

  test('missing event in body: returns 400', async () => {
    const { req, res } = makeReqRes({ jobId: 'job_1' });
    mockDb = makeMockDb({});
    await processScheduledTrustNotificationHandler(req, res);
    expect(res._status).toBe(400);
    expect(routeNotification).not.toHaveBeenCalled();
  });

  test('empty body: returns 400', async () => {
    const { req, res } = makeReqRes({});
    mockDb = makeMockDb({});
    await processScheduledTrustNotificationHandler(req, res);
    expect(res._status).toBe(400);
  });

  test('job doc not found: returns 200 NOT_FOUND, routeNotification not called', async () => {
    mockDb = makeMockDb({ schedDocData: null });
    const { req, res } = makeReqRes({ jobId: 'job_1', event: makeEvent() });

    await processScheduledTrustNotificationHandler(req, res);

    expect(res._status).toBe(200);
    expect(res._body).toBe('NOT_FOUND');
    expect(routeNotification).not.toHaveBeenCalled();
  });

  test('job status CANCELLED: returns 200 CANCELLED, routeNotification not called', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'CANCELLED' });
    const { req, res } = makeReqRes({ jobId: 'job_1', event: makeEvent() });

    await processScheduledTrustNotificationHandler(req, res);

    expect(res._status).toBe(200);
    expect(res._body).toBe('CANCELLED');
    expect(routeNotification).not.toHaveBeenCalled();
    expect(docUpdateSpy).not.toHaveBeenCalled();
  });

  test('conditionCheck=always: calls routeNotification, updates to EXECUTED, returns 200 OK', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'PENDING' });
    const event = makeEvent({ conditionCheck: 'always' });
    const { req, res } = makeReqRes({ jobId: 'job_1', event });

    await processScheduledTrustNotificationHandler(req, res);

    expect(routeNotification).toHaveBeenCalledTimes(1);
    expect(routeNotification).toHaveBeenCalledWith(event, expect.anything());
    expect(docUpdateSpy).toHaveBeenCalledWith(expect.objectContaining({ status: 'EXECUTED' }));
    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');
  });

  test('conditionCheck missing (defaults to always): calls routeNotification', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'PENDING' });
    const event = makeEvent();
    delete event.conditionCheck;
    const { req, res } = makeReqRes({ jobId: 'job_1', event });

    await processScheduledTrustNotificationHandler(req, res);

    expect(routeNotification).toHaveBeenCalledTimes(1);
    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');
  });

  test('conditionCheck=host_not_checked_in, host has checked in: CONDITION_NOT_MET, doc CANCELLED, no routeNotification', async () => {
    mockDb = makeMockDb({
      schedDocData:  {},
      schedDocStatus: 'PENDING',
      gameDocData:   { hostCheckedIn: true },
    });
    const event = makeEvent({ conditionCheck: 'host_not_checked_in' });
    const { req, res } = makeReqRes({ jobId: 'job_1', event });

    await processScheduledTrustNotificationHandler(req, res);

    expect(routeNotification).not.toHaveBeenCalled();
    expect(docUpdateSpy).toHaveBeenCalledWith(expect.objectContaining({ status: 'CANCELLED' }));
    expect(res._status).toBe(200);
    expect(res._body).toBe('CONDITION_NOT_MET');
  });

  test('conditionCheck=host_not_checked_in, host has NOT checked in: calls routeNotification, EXECUTED', async () => {
    mockDb = makeMockDb({
      schedDocData:  {},
      schedDocStatus: 'PENDING',
      gameDocData:   { hostCheckedIn: false },
    });
    const event = makeEvent({ conditionCheck: 'host_not_checked_in' });
    const { req, res } = makeReqRes({ jobId: 'job_1', event });

    await processScheduledTrustNotificationHandler(req, res);

    expect(routeNotification).toHaveBeenCalledTimes(1);
    expect(docUpdateSpy).toHaveBeenCalledWith(expect.objectContaining({ status: 'EXECUTED' }));
    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');
  });

  test('conditionCheck=host_not_checked_in, game doc not found: treats as not checked in, proceeds', async () => {
    mockDb = makeMockDb({
      schedDocData:  {},
      schedDocStatus: 'PENDING',
      gameDocData:   null,  // game doc !exists
    });
    const event = makeEvent({ conditionCheck: 'host_not_checked_in' });
    const { req, res } = makeReqRes({ jobId: 'job_1', event });

    await processScheduledTrustNotificationHandler(req, res);

    // Game not found → can't confirm host checked in → proceed with notification
    expect(routeNotification).toHaveBeenCalledTimes(1);
    expect(res._status).toBe(200);
    expect(res._body).toBe('OK');
  });

  test('routeNotification is called with the event from the request body', async () => {
    mockDb = makeMockDb({ schedDocData: {}, schedDocStatus: 'PENDING' });
    const event = makeEvent({ eventType: 'player_rate_due', sourceId: 'game_g99' });
    const { req, res } = makeReqRes({ jobId: 'job_1', event });

    await processScheduledTrustNotificationHandler(req, res);

    expect(routeNotification.mock.calls[0][0]).toMatchObject({
      eventType: 'player_rate_due',
      sourceId:  'game_g99',
    });
  });

});
