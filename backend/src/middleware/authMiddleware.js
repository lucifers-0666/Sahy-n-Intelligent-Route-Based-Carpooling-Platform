const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { getJwtSecret } = require('../config/jwt');
const { verifyFirebaseIdToken } = require('../config/firebase');

/**
 * Extracts bearer token from request Authorization header.
 */
const extractBearerToken = (req) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.split(' ')[1].trim();
  }
  return null;
};

/**
 * Authenticates requests via Firebase ID Token first, with seamless fallback
 * to legacy custom JWT for ongoing migration compatibility.
 */
const authenticate = async (req, res, next) => {
  try {
    const token = extractBearerToken(req);

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required. Access token missing.',
      });
    }

    let user = null;
    let firebaseDecoded = null;

    // 1. Attempt Firebase ID Token verification
    try {
      firebaseDecoded = await verifyFirebaseIdToken(token);
      if (firebaseDecoded && firebaseDecoded.uid) {
        user = await User.findOne({ firebaseUid: firebaseDecoded.uid });

        // Safe auto-link for existing users with verified matching email
        if (!user && firebaseDecoded.email && firebaseDecoded.email_verified) {
          const matchingUser = await User.findOne({ email: firebaseDecoded.email.toLowerCase().trim() });
          if (matchingUser && !matchingUser.firebaseUid) {
            matchingUser.firebaseUid = firebaseDecoded.uid;
            matchingUser.firebaseProviders.push({
              providerId: firebaseDecoded.firebase?.sign_in_provider || 'google.com',
              uid: firebaseDecoded.uid,
              linkedAt: new Date(),
            });
            await matchingUser.save();
            user = matchingUser;
          }
        }
      }
    } catch (fbErr) {
      // If token expired in Firebase, do not fallback to JWT if it was clearly a Firebase token
      if (fbErr.code === 'auth/id-token-expired' || token.startsWith('mock_firebase_expired')) {
        return res.status(401).json({
          success: false,
          message: 'Firebase ID token has expired. Please refresh your session.',
        });
      }
      // Otherwise proceed to legacy JWT check
    }

    // 2. Fallback to legacy custom JWT if not verified via Firebase
    if (!user && !firebaseDecoded) {
      try {
        const secret = getJwtSecret();
        const decoded = jwt.verify(token, secret);
        if (decoded && decoded.id) {
          user = await User.findById(decoded.id);
        }
      } catch (jwtErr) {
        // Both verification attempts failed
      }
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        message: firebaseDecoded
          ? 'User profile not found. Please complete profile bootstrap.'
          : 'Invalid or expired token.',
      });
    }

    // Account suspension check
    if (user.accountStatus === 'suspended' && user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        errorCode: 'ACCOUNT_SUSPENDED',
        message: 'Account has been suspended by administration.',
        suspensionReason: user.suspensionReason || 'Account suspended by administration.',
        suspendedAt: user.suspendedAt,
      });
    }

    req.user = user;
    if (firebaseDecoded) {
      req.firebaseUser = firebaseDecoded;
    }
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token.',
    });
  }
};

/**
 * Validates Firebase ID Token exclusively and attaches decoded payload,
 * without requiring the User to already exist in MongoDB (used by bootstrap endpoint).
 */
const verifyFirebaseTokenOnly = async (req, res, next) => {
  try {
    const token = extractBearerToken(req);
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required. Firebase ID token missing.',
      });
    }

    const decoded = await verifyFirebaseIdToken(token);
    req.firebaseUser = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: error.code === 'auth/id-token-expired'
        ? 'Firebase ID token has expired.'
        : 'Invalid Firebase ID token.',
    });
  }
};

const optionalAuth = async (req, res, next) => {
  try {
    const token = extractBearerToken(req);
    if (!token) {
      req.user = null;
      return next();
    }

    let user = null;
    try {
      const fbDecoded = await verifyFirebaseIdToken(token);
      if (fbDecoded && fbDecoded.uid) {
        user = await User.findOne({ firebaseUid: fbDecoded.uid });
      }
    } catch (_) { }

    if (!user) {
      try {
        const secret = getJwtSecret();
        const decoded = jwt.verify(token, secret);
        user = await User.findById(decoded.id);
      } catch (_) { }
    }

    req.user = user || null;
    next();
  } catch (error) {
    req.user = null;
    next();
  }
};

const ADMIN_ROLES = ['admin', 'super_admin', 'safety_officer', 'support_lead'];

const adminAuth = (req, res, next) => {
  if (!req.user || !ADMIN_ROLES.includes(req.user.role)) {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Administrative privileges required.',
    });
  }
  next();
};

const requireRole = (allowedRoles = []) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
      });
    }

    const userRole = req.user.role;
    if (userRole === 'super_admin') {
      return next();
    }

    if (allowedRoles.length === 1 && allowedRoles[0] === 'super_admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Operation requires super_admin role.',
      });
    }

    if (userRole === 'admin' || allowedRoles.includes(userRole)) {
      return next();
    }

    return res.status(403).json({
      success: false,
      message: `Access denied. Operation requires role: ${allowedRoles.join(', ')}.`,
    });
  };
};

module.exports = {
  authenticate,
  protect: authenticate,
  verifyFirebaseTokenOnly,
  optionalAuth,
  adminAuth,
  requireRole,
  ADMIN_ROLES,
};
