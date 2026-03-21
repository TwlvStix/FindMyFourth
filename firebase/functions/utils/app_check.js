'use strict';
const functions = require('firebase-functions/v1');

// Set to true once attestation providers are confirmed working in Firebase Console.
const APP_CHECK_ENFORCE = true;

function requireAppCheck(context, functionName) {
  if (context.app === undefined) {
    const msg = `[AppCheck] Missing token on ${functionName} (uid=${context.auth?.uid || 'unknown'})`;
    if (APP_CHECK_ENFORCE) {
      console.warn(msg + ' — REJECTED');
      throw new functions.https.HttpsError('failed-precondition', 'App Check token required.');
    } else {
      console.warn(msg + ' — allowed (log-only mode)');
    }
  }
}

module.exports = { requireAppCheck, APP_CHECK_ENFORCE };
