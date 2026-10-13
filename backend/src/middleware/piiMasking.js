/**
 * Sahyān Enterprise PII Masking Middleware
 * 
 * Automatically redacts Personally Identifiable Information (PII)
 * on admin API endpoints to enforce DPDP / GDPR privacy compliance.
 * Raw PII can only be retrieved via explicit audit-logged unmasking.
 */

/**
 * Mask Indian & international phone numbers: +91 98****3210
 * @param {string} phone
 * @returns {string}
 */
function maskPhone(phone) {
  if (!phone || typeof phone !== 'string') return phone;
  const cleaned = phone.trim();
  if (cleaned.length <= 4) return '****';

  // Format with country code if present (e.g. +91 9876543210)
  if (cleaned.startsWith('+91')) {
    const rawNumber = cleaned.replace('+91', '').trim();
    if (rawNumber.length >= 6) {
      const start = rawNumber.slice(0, 2);
      const end = rawNumber.slice(-4);
      return `+91 ${start}****${end}`;
    }
    return `+91 ****${rawNumber.slice(-4)}`;
  }

  // Standard 10-digit number
  if (cleaned.length >= 8) {
    const start = cleaned.slice(0, 2);
    const end = cleaned.slice(-4);
    return `${start}****${end}`;
  }

  return `${cleaned.slice(0, 1)}****${cleaned.slice(-2)}`;
}

/**
 * Mask email address: ar***@example.com
 * @param {string} email
 * @returns {string}
 */
function maskEmail(email) {
  if (!email || typeof email !== 'string') return email;
  const parts = email.trim().split('@');
  if (parts.length !== 2) return '***@***.com';

  const [username, domain] = parts;
  const visibleChars = Math.min(2, username.length);
  const start = username.slice(0, visibleChars);
  return `${start}***@${domain}`;
}

/**
 * Mask government / driver license number: GJ-01-****-0941
 * @param {string} docId
 * @returns {string}
 */
function maskLicense(docId) {
  if (!docId || typeof docId !== 'string') return docId;
  const cleaned = docId.trim();
  if (cleaned.length <= 6) return '****';

  // If standard format with hyphens e.g. GJ-01-2023-0941 or GJ01 20230000941
  if (cleaned.includes('-')) {
    const parts = cleaned.split('-');
    if (parts.length >= 3) {
      return `${parts[0]}-${parts[1]}-****-${parts[parts.length - 1]}`;
    }
  }

  const start = cleaned.slice(0, 5);
  const end = cleaned.slice(-4);
  return `${start}-****-${end}`;
}

/**
 * Recursively mask PII fields within a user or embedded object
 * @param {any} item
 * @returns {any}
 */
function maskSingleItem(item) {
  if (!item || typeof item !== 'object') return item;

  // Plain copy, safely converting Mongoose documents if applicable
  const raw = typeof item.toObject === 'function' ? item.toObject() : item;
  const masked = { ...raw };

  if (typeof masked.phone === 'string') {
    masked.phone = maskPhone(masked.phone);
    masked._isPhoneMasked = true;
  }

  if (typeof masked.email === 'string') {
    masked.email = maskEmail(masked.email);
    masked._isEmailMasked = true;
  }

  if (masked.driverProfile && typeof masked.driverProfile === 'object') {
    masked.driverProfile = { ...masked.driverProfile };
    if (typeof masked.driverProfile.licenseNumber === 'string' && masked.driverProfile.licenseNumber) {
      masked.driverProfile.licenseNumber = maskLicense(masked.driverProfile.licenseNumber);
      masked.driverProfile._isLicenseMasked = true;
    }
  }

  if (Array.isArray(masked.emergencyContacts)) {
    masked.emergencyContacts = masked.emergencyContacts.map((contact) => {
      if (!contact || typeof contact !== 'object') return contact;
      return {
        ...contact,
        phone: typeof contact.phone === 'string' ? maskPhone(contact.phone) : contact.phone,
        _isPhoneMasked: true,
      };
    });
  }

  // Nested user objects inside bookings, rides, reports
  if (masked.passenger && typeof masked.passenger === 'object') {
    masked.passenger = maskSingleItem(masked.passenger);
  }
  if (masked.driver && typeof masked.driver === 'object') {
    masked.driver = maskSingleItem(masked.driver);
  }
  if (masked.reporter && typeof masked.reporter === 'object') {
    masked.reporter = maskSingleItem(masked.reporter);
  }
  if (masked.reportedUser && typeof masked.reportedUser === 'object') {
    masked.reportedUser = maskSingleItem(masked.reportedUser);
  }
  if (masked.targetUser && typeof masked.targetUser === 'object') {
    masked.targetUser = maskSingleItem(masked.targetUser);
  }

  return masked;
}

/**
 * Mask PII in various response shapes (array, paginated { users: [] }, single object)
 * @param {any} data
 * @returns {any}
 */
function maskPiiData(data) {
  if (!data) return data;

  if (Array.isArray(data)) {
    return data.map(maskSingleItem);
  }

  if (typeof data === 'object') {
    const clone = { ...data };

    if (Array.isArray(clone.users)) {
      clone.users = clone.users.map(maskSingleItem);
    }
    if (Array.isArray(clone.bookings)) {
      clone.bookings = clone.bookings.map(maskSingleItem);
    }
    if (Array.isArray(clone.rides)) {
      clone.rides = clone.rides.map(maskSingleItem);
    }
    if (Array.isArray(clone.reports)) {
      clone.reports = clone.reports.map(maskSingleItem);
    }
    if (Array.isArray(clone.logs)) {
      clone.logs = clone.logs.map(maskSingleItem);
    }
    if (clone.user && typeof clone.user === 'object') {
      clone.user = maskSingleItem(clone.user);
    }
    if (clone.booking && typeof clone.booking === 'object') {
      clone.booking = maskSingleItem(clone.booking);
    }
    if (clone.ride && typeof clone.ride === 'object') {
      clone.ride = maskSingleItem(clone.ride);
    }
    if (clone.report && typeof clone.report === 'object') {
      clone.report = maskSingleItem(clone.report);
    }

    return clone;
  }

  return data;
}

/**
 * Express middleware to automatically mask PII in JSON responses
 */
const maskAdminPii = (req, res, next) => {
  const originalJson = res.json.bind(res);

  res.json = function (body) {
    if (body && body.success && body.data) {
      body.data = maskPiiData(body.data);
    }
    return originalJson(body);
  };

  next();
};

module.exports = {
  maskPhone,
  maskEmail,
  maskLicense,
  maskSingleItem,
  maskPiiData,
  maskAdminPii,
};
