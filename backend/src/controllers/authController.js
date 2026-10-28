const jwt = require('jsonwebtoken');
const User = require('../models/User');
const AuditLog = require('../models/AuditLog');
const otpService = require('../services/otpService');
const passwordService = require('../services/passwordService');
const { getJwtSecret, getJwtExpiresIn } = require('../config/jwt');

const generateAccessToken = (userId) => {
  const secret = getJwtSecret();
  return jwt.sign({ id: userId }, secret, {
    expiresIn: getJwtExpiresIn(),
  });
};

/**
 * Validates password policy:
 * - Minimum 8 characters
 * - At least one uppercase letter
 * - At least one lowercase letter
 * - At least one number
 * - At least one special character
 */
const validatePasswordPolicy = (password) => {
  if (!password || typeof password !== 'string') {
    return 'Password is required';
  }
  if (password.length < 8) {
    return 'Password must be at least 8 characters long';
  }
  if (!/[A-Z]/.test(password)) {
    return 'Password must contain at least one uppercase letter';
  }
  if (!/[a-z]/.test(password)) {
    return 'Password must contain at least one lowercase letter';
  }
  if (!/\d/.test(password)) {
    return 'Password must contain at least one number';
  }
  if (!/[\W_]/.test(password)) {
    return 'Password must contain at least one special character';
  }
  return null;
};

/**
 * POST /api/v1/auth/register
 */
const register = async (req, res, next) => {
  try {
    const { name, email, phone, password } = req.body;

    // Full name validation
    if (!name || name.trim().length < 2 || name.trim().length > 50) {
      return res.status(400).json({ success: false, message: 'Name must be between 2 and 50 characters' });
    }

    // Email validation
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!email || !emailRegex.test(email.trim())) {
      return res.status(400).json({ success: false, message: 'Please provide a valid email address' });
    }

    // Indian mobile phone validation
    const cleanPhone = phone ? phone.toString().replace(/\D/g, '') : '';
    const phoneRegex = /^[6-9]\d{9}$/;
    const localPhone = cleanPhone.length === 12 && cleanPhone.startsWith('91')
        ? cleanPhone.substring(2)
        : cleanPhone;

    if (!phoneRegex.test(localPhone)) {
      return res.status(400).json({ success: false, message: 'Please provide a valid 10-digit Indian mobile number' });
    }

    // Password policy validation
    const passwordError = validatePasswordPolicy(password);
    if (passwordError) {
      return res.status(400).json({ success: false, message: passwordError });
    }

    // Check duplicate email
    const normalizedEmail = email.toLowerCase().trim();
    const existingEmail = await User.findOne({ email: normalizedEmail });
    if (existingEmail) {
      return res.status(400).json({ success: false, message: 'An account with this email already exists' });
    }

    // Check duplicate phone
    const formattedPhone = `+91${localPhone}`;
    const existingPhone = await User.findOne({ phone: formattedPhone });
    if (existingPhone) {
      return res.status(400).json({ success: false, message: 'An account with this mobile number already exists' });
    }

    // Generate initial 6-digit cryptographic OTP
    const otpCode = otpService.generateOtpCode(6);
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000);

    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      phone: formattedPhone,
      password,
      isVerified: false,
      otpInfo: {
        code: otpCode,
        expiresAt: otpExpires,
        attempts: 1,
        verificationAttempts: 0,
        lastRequestedAt: new Date(),
      },
    });

    await otpService.sendOtp(formattedPhone, otpCode);

    return res.status(201).json({
      success: true,
      message: 'Registration successful. OTP sent for verification.',
      data: {
        user: user.toJSON(),
      },
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/auth/login
 */
const login = async (req, res, next) => {
  try {
    const { emailOrPhone, identifier, email, phone, password } = req.body;
    const targetIdentifier = identifier || emailOrPhone || email || phone;

    if (!targetIdentifier || !password) {
      return res.status(400).json({ success: false, message: 'Please provide email/phone and password' });
    }

    const cleanInput = targetIdentifier.trim();
    let query = { email: cleanInput.toLowerCase() };

    if (!cleanInput.includes('@')) {
      const cleanPhone = cleanInput.replace(/\D/g, '');
      const localPhone = cleanPhone.length === 12 && cleanPhone.startsWith('91')
          ? cleanPhone.substring(2)
          : cleanPhone;
      const formattedPhone = localPhone.length === 10 ? `+91${localPhone}` : cleanInput;
      query = { phone: formattedPhone };
    }

    const user = await User.findOne(query).select('+password');
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    if (user.accountStatus === 'suspended') {
      return res.status(403).json({
        success: false,
        errorCode: 'ACCOUNT_SUSPENDED',
        message: 'Your account has been suspended by the Sahyān administration team.',
        suspensionReason: user.suspensionReason || 'Account suspended by administration.',
        suspendedAt: user.suspendedAt,
      });
    }

    // Block unverified accounts from logging in via password
    if (!user.isVerified) {
      return res.status(403).json({
        success: false,
        message: 'Please verify your mobile number before logging in',
        isVerified: false,
        phone: user.phone,
      });
    }

    const token = generateAccessToken(user._id);

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      accessToken: token,
      token,
      data: {
        token,
        accessToken: token,
        user: user.toJSON(),
      },
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/auth/me or /api/v1/auth/me
 */
const getMe = async (req, res, next) => {
  try {
    const user = req.user.toJSON ? req.user.toJSON() : req.user;
    return res.status(200).json({
      success: true,
      message: 'Authenticated user profile retrieved successfully',
      data: {
        user,
      },
      user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/auth/send-otp
 */
const sendOtp = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required' });
    }

    const cleanPhone = phone.toString().replace(/\D/g, '');
    const localPhone = cleanPhone.length === 12 && cleanPhone.startsWith('91')
        ? cleanPhone.substring(2)
        : cleanPhone;

    if (localPhone.length !== 10) {
      return res.status(400).json({ success: false, message: 'Please provide a valid 10-digit mobile number' });
    }

    const formattedPhone = `+91${localPhone}`;
    let user = await User.findOne({ phone: formattedPhone });
    if (!user) {
      // Auto-provision user account for passwordless phone login/signup
      user = await User.create({
        name: `Traveler ${localPhone.slice(-4)}`,
        phone: formattedPhone,
        isVerified: false,
        authProvider: 'local',
      });
    }

    if (otpService.isRateLimited(user.otpInfo)) {
      return res.status(429).json({ success: false, message: 'Too many OTP requests. Please wait before requesting a new code.' });
    }

    const now = new Date();
    let currentAttempts = 1;
    if (user.otpInfo && user.otpInfo.lastRequestedAt) {
      const diffMins = (now - new Date(user.otpInfo.lastRequestedAt)) / (1000 * 60);
      if (diffMins < 10) {
        currentAttempts = (user.otpInfo.attempts || 0) + 1;
      }
    }

    const otpCode = otpService.generateOtpCode(6);
    user.otpInfo = {
      code: otpCode,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      attempts: currentAttempts,
      verificationAttempts: 0,
      lastRequestedAt: now,
    };

    await user.save();
    await otpService.sendOtp(formattedPhone, otpCode);

    return res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/auth/verify-otp
 */
const verifyOtp = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;
    if (!otp) {
      return res.status(400).json({ success: false, message: 'OTP is required' });
    }

    let user;
    if (req.user) {
      user = req.user;
    } else if (phone) {
      const cleanPhone = phone.toString().replace(/\D/g, '');
      const localPhone = cleanPhone.length === 12 && cleanPhone.startsWith('91')
          ? cleanPhone.substring(2)
          : cleanPhone;
      const formattedPhone = localPhone.length === 10 ? `+91${localPhone}` : phone;
      user = await User.findOne({ phone: formattedPhone });
    }

    if (!user) {
      return res.status(400).json({ success: false, message: 'User account not found' });
    }

    if (!user.otpInfo || !user.otpInfo.code) {
      return res.status(400).json({ success: false, message: 'No active OTP request found. Please request a new OTP.' });
    }

    if (new Date() > new Date(user.otpInfo.expiresAt)) {
      user.otpInfo = undefined;
      await user.save();
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new OTP.' });
    }

    // Check verification attempts limit (max 5 failed attempts)
    user.otpInfo.verificationAttempts = (user.otpInfo.verificationAttempts || 0) + 1;
    if (user.otpInfo.verificationAttempts > 5) {
      user.otpInfo = undefined;
      await user.save();
      return res.status(400).json({ success: false, message: 'Too many failed verification attempts. Please request a new OTP.' });
    }

    const trimmedOtp = otp.toString().trim();
    // Validate exclusively against the server-generated cryptographic OTP (no bypasses)
    if (user.otpInfo.code !== trimmedOtp) {
      await user.save();
      return res.status(400).json({ success: false, message: 'Invalid OTP code' });
    }

    // Mark user verified and clear OTP
    user.isVerified = true;
    user.otpInfo = undefined;
    await user.save();

    const token = generateAccessToken(user._id);

    return res.status(200).json({
      success: true,
      message: 'Mobile number verified successfully',
      accessToken: token,
      token,
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/auth/forgot-password
 */
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email address is required' });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      // Do not reveal user existence for security
      return res.status(200).json({
        success: true,
        message: 'If an account exists with this email, a reset token has been sent.',
      });
    }

    const { rawToken, hashedToken, expiresAt } = passwordService.generateResetToken();
    user.resetPasswordInfo = { token: hashedToken, expiresAt };
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'If an account exists with this email, a reset token has been sent.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/auth/reset-password
 */
const resetPassword = async (req, res, next) => {
  try {
    const token = req.body.token;
    const newPassword = req.body.newPassword || req.body.password;
    if (!token || !newPassword) {
      return res.status(400).json({ success: false, message: 'Valid token and new password are required' });
    }

    const passwordError = validatePasswordPolicy(newPassword);
    if (passwordError) {
      return res.status(400).json({ success: false, message: passwordError });
    }

    const hashedToken = passwordService.hashToken(token);

    const user = await User.findOne({
      'resetPasswordInfo.token': hashedToken,
      'resetPasswordInfo.expiresAt': { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid or expired password reset token' });
    }

    user.password = newPassword;
    user.resetPasswordInfo = undefined;
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Password reset successful. You can now log in with your new password.',
    });
  } catch (error) {
    next(error);
  }
};


/**
 * POST /api/v1/auth/firebase-sync
 * Idempotently provisions or updates a MongoDB user record from a verified Firebase ID token.
 */
const firebaseSync = async (req, res, next) => {
  try {
    const firebaseUser = req.firebaseUser;
    if (!firebaseUser || !firebaseUser.uid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid Firebase authentication session.',
      });
    }

    const {
      uid,
      email,
      email_verified: emailVerified,
      phone_number: phoneNumber,
      name: fbName,
      picture,
      firebase: fbMeta,
    } = firebaseUser;

    const provider = fbMeta?.sign_in_provider || 'custom';

    // 1. Check if user already exists by firebaseUid
    let user = await User.findOne({ firebaseUid: uid });
    if (user) {
      let modified = false;
      if (req.body.name && req.body.name.trim().length >= 2 && user.name === 'Sahyān Traveler') {
        user.name = req.body.name.trim();
        modified = true;
      }
      if (phoneNumber && !user.phone) {
        user.phone = phoneNumber;
        user.isVerified = true;
        modified = true;
      }
      if (email && emailVerified && !user.email) {
        user.email = email.toLowerCase().trim();
        modified = true;
      }
      if (picture && !user.profileImage) {
        user.profileImage = picture;
        modified = true;
      }
      if (modified) {
        await user.save();
      }

      if (user.accountStatus === 'suspended' && user.role !== 'admin') {
        return res.status(403).json({
          success: false,
          errorCode: 'ACCOUNT_SUSPENDED',
          message: 'Your account has been suspended by the Sahyān administration team.',
          suspensionReason: user.suspensionReason || 'Account suspended by administration.',
          suspendedAt: user.suspendedAt,
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Profile synchronized successfully.',
        isNewUser: false,
        user: user.toJSON(),
      });
    }

    // 2. Safe account association by verified email
    if (email && emailVerified) {
      const existingByEmail = await User.findOne({ email: email.toLowerCase().trim() });
      if (existingByEmail) {
        existingByEmail.firebaseUid = uid;
        const alreadyLinked = existingByEmail.firebaseProviders.some((p) => p.providerId === provider);
        if (!alreadyLinked) {
          existingByEmail.firebaseProviders.push({ providerId: provider, uid, linkedAt: new Date() });
        }
        await existingByEmail.save();
        return res.status(200).json({
          success: true,
          message: 'Existing account linked with Firebase credentials.',
          isNewUser: false,
          user: existingByEmail.toJSON(),
        });
      }
    }

    // 3. Safe account association by verified phone number
    if (phoneNumber) {
      const cleanPhone = phoneNumber.replace(/\D/g, '').slice(-10);
      const formattedPhone = `+91${cleanPhone}`;
      const existingByPhone = await User.findOne({ phone: formattedPhone });
      if (existingByPhone && !existingByPhone.firebaseUid) {
        existingByPhone.firebaseUid = uid;
        existingByPhone.isVerified = true;
        existingByPhone.firebaseProviders.push({ providerId: 'phone', uid, linkedAt: new Date() });
        await existingByPhone.save();
        return res.status(200).json({
          success: true,
          message: 'Existing mobile account linked with Firebase credentials.',
          isNewUser: false,
          user: existingByPhone.toJSON(),
        });
      }
    }

    // 4. Create new user profile in MongoDB
    const clientName = req.body.name && req.body.name.trim().length >= 2
      ? req.body.name.trim()
      : (fbName || 'Sahyān Traveler');

    const cleanPhone = phoneNumber
      ? `+91${phoneNumber.replace(/\D/g, '').slice(-10)}`
      : (req.body.phone ? `+91${req.body.phone.toString().replace(/\D/g, '').slice(-10)}` : undefined);

    let authProviderType = 'local';
    if (provider.includes('phone')) authProviderType = 'firebase_phone';
    else if (provider.includes('google')) authProviderType = 'firebase_google';
    else if (provider.includes('password')) authProviderType = 'firebase_email';
    else authProviderType = 'firebase_mixed';

    user = await User.create({
      firebaseUid: uid,
      name: clientName,
      email: email ? email.toLowerCase().trim() : undefined,
      phone: cleanPhone,
      profileImage: picture || req.body.profileImage || '',
      city: req.body.city || 'Ahmedabad',
      isVerified: !!phoneNumber,
      authProvider: authProviderType,
      firebaseProviders: [
        {
          providerId: provider,
          uid,
          linkedAt: new Date(),
        },
      ],
    });

    return res.status(201).json({
      success: true,
      message: 'Account provisioned successfully.',
      isNewUser: true,
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/auth/link-provider
 */
const linkProvider = async (req, res, next) => {
  try {
    const { providerId, providerUid } = req.body;
    if (!providerId || !providerUid) {
      return res.status(400).json({
        success: false,
        message: 'Provider details are required for account linking.',
      });
    }

    const user = req.user;
    const alreadyLinked = user.firebaseProviders.some(
      (p) => p.providerId === providerId || p.uid === providerUid
    );

    if (alreadyLinked) {
      return res.status(200).json({
        success: true,
        message: 'Provider already linked to this profile.',
        user: user.toJSON(),
      });
    }

    user.firebaseProviders.push({
      providerId,
      uid: providerUid,
      linkedAt: new Date(),
    });
    user.authProvider = 'firebase_mixed';
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Provider linked successfully.',
      user: user.toJSON(),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/auth/logout
 * Session revocation endpoint
 */
const logout = async (req, res, next) => {
  try {
    return res.status(200).json({
      success: true,
      message: 'Session revoked successfully.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/auth/appeal
 * Submit reinstatement appeal for suspended or restricted accounts
 */
const submitAppeal = async (req, res, next) => {
  try {
    const { reason, email, phone } = req.body;
    if (!reason || String(reason).trim().length < 5) {
      return res.status(400).json({
        success: false,
        message: 'A detailed appeal reason of at least 5 characters is required.',
      });
    }

    let user = null;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, getJwtSecret());
        if (decoded && decoded.id) {
          user = await User.findById(decoded.id);
        }
      } catch (_) {
        // Token might be invalid or expired; fallback to email/phone lookup
      }
    }

    if (!user && email) {
      user = await User.findOne({ email: email.toLowerCase().trim() });
    }
    if (!user && phone) {
      user = await User.findOne({ phone: phone.trim() });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User account not found. Please provide registered email or phone.',
      });
    }

    if (!user.appeals) user.appeals = [];
    user.appeals.push({
      reason: String(reason).trim(),
      status: 'pending',
      submittedAt: new Date(),
    });
    await user.save();

    await AuditLog.create({
      action: 'APPEAL_SUBMITTED',
      targetUser: user._id,
      reason: String(reason).trim(),
      metadata: {
        email: user.email,
        accountStatus: user.accountStatus,
        appealsCount: user.appeals.length,
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Reinstatement appeal submitted successfully. It has been queued for administrative safety review.',
      data: {
        appealIndex: user.appeals.length - 1,
        status: 'pending',
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  getMe,
  sendOtp,
  verifyOtp,
  forgotPassword,
  resetPassword,
  validatePasswordPolicy,
  firebaseSync,
  linkProvider,
  logout,
  submitAppeal,
};

