const test = require('node:test');
const assert = require('node:assert');
const express = require('express');
const { createRateLimiter } = require('../src/middleware/rateLimiter');

test('Rate Limiter: enforces max limit and returns HTTP 429 with Retry-After header', async () => {
  const app = express();
  app.use(express.json());

  const testLimiter = createRateLimiter({
    windowMs: 5000,
    max: 2,
    message: 'Rate limit test reached',
    keyGenerator: (req) => req.headers['x-client-ip'] || 'test-client',
  });

  app.get('/test-limit', testLimiter, (req, res) => {
    res.status(200).json({ success: true });
  });

  const server = app.listen(0);
  const port = server.address().port;
  const url = `http://localhost:${port}/test-limit`;

  try {
    // Hits 1 & 2 pass
    const res1 = await fetch(url, { headers: { 'x-test-rate-limit': 'true', 'x-client-ip': 'ip-1' } });
    assert.strictEqual(res1.status, 200);

    const res2 = await fetch(url, { headers: { 'x-test-rate-limit': 'true', 'x-client-ip': 'ip-1' } });
    assert.strictEqual(res2.status, 200);

    // Hit 3 exceeds limit -> 429
    const res3 = await fetch(url, { headers: { 'x-test-rate-limit': 'true', 'x-client-ip': 'ip-1' } });
    assert.strictEqual(res3.status, 429);
    const data3 = await res3.json();
    assert.strictEqual(data3.success, false);
    assert.strictEqual(data3.message, 'Rate limit test reached');
    assert.ok(res3.headers.get('retry-after'));

    // Different IP is isolated and succeeds
    const resOther = await fetch(url, { headers: { 'x-test-rate-limit': 'true', 'x-client-ip': 'ip-2' } });
    assert.strictEqual(resOther.status, 200);
  } finally {
    server.close();
  }
});
