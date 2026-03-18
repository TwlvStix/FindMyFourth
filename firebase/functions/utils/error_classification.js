'use strict';

const TRANSIENT_CODES = new Set([
  'resource-exhausted', 'unavailable', 'deadline-exceeded', 'internal', 'aborted',
]);

function isTransientError(error) {
  if (!error) return false;
  const code = error.code;
  if (typeof code === 'string' && TRANSIENT_CODES.has(code)) return true;
  if (typeof code === 'number' && [4, 8, 10, 13, 14].includes(code)) return true;
  const msg = (error.message || '').toLowerCase();
  if (msg.includes('econnreset') || msg.includes('econnrefused') ||
      msg.includes('etimedout') || msg.includes('socket hang up')) return true;
  return false;
}

function classifyErrorStatus(error) {
  return isTransientError(error) ? 500 : 400;
}

module.exports = { isTransientError, classifyErrorStatus };
