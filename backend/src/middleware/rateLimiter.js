/**
 * In-memory sliding window rate limiter middleware for sensitive operations.
 * Protects auth, OTP dispatch, and payment endpoints against brute-force and rapid replay.
 */

const hitMap = new Map();

/**
 * Creates an in-memory rate limiting middleware
 * @param {Object} options
 * @param {number} options.windowMs - Time window in milliseconds
 * @param {number} options.max - Max allowed requests within window
 * @param {string} options.message - Error message when rate limit exceeded
 * @param {Function} [options.keyGenerator] - Custom key extractor (defaults to IP)
 */
function createRateLimiter(options) {
  const {
    windowMs = 60 * 1000,
    max = 60,
    message = 'Too many requests. Please try again later.',
    keyGenerator = (req) => req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown',
  } = options;

  return (req, res, next) => {
    // In development or test environments, bypass rate limiting unless in production or explicitly testing
    if (process.env.NODE_ENV !== 'production' && !req.headers['x-test-rate-limit']) {
      return next();
    }

    const key = keyGenerator(req);
    const now = Date.now();
    const cutoff = now - windowMs;

    let timestamps = hitMap.get(key) || [];
    // Discard entries older than window
    timestamps = timestamps.filter((t) => t > cutoff);

    if (timestamps.length >= max) {
      const oldestHit = timestamps[0];
      const retryAfterSec = Math.ceil((oldestHit + windowMs - now) / 1000);
      res.setHeader('Retry-After', String(Math.max(1, retryAfterSec)));
      return res.status(429).json({
        success: false,
        message,
        retryAfterSeconds: Math.max(1, retryAfterSec),
      });
    }

    timestamps.push(now);
    hitMap.set(key, timestamps);

    next();
  };
}

// Auth endpoints limiter (10 attempts per minute)
const authLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 10,
  message: 'Too many authentication attempts. Please wait 1 minute before retrying.',
});

// Payment endpoints limiter (25 attempts per minute per user/IP)
const paymentLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 25,
  message: 'Too many payment requests. Please wait a moment before trying again.',
  keyGenerator: (req) => {
    const userId = req.user ? (req.user._id || req.user.id) : null;
    return userId ? `pay_user_${userId}` : `pay_ip_${req.ip || 'anon'}`;
  },
});

// OTP endpoints limiter (5 attempts per 10 minutes per phone/IP)
const otpLimiter = createRateLimiter({
  windowMs: 10 * 60 * 1000,
  max: 5,
  message: 'Too many OTP requests. Please wait 10 minutes before requesting a new code.',
  keyGenerator: (req) => {
    const phone = req.body?.phone;
    return phone ? `otp_phone_${phone}` : `otp_ip_${req.ip || 'anon'}`;
  },
});

module.exports = {
  createRateLimiter,
  authLimiter,
  paymentLimiter,
  otpLimiter,
};
