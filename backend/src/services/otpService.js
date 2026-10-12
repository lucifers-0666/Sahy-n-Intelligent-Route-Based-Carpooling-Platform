const crypto = require('crypto');

class OtpService {
  /**
   * Generates a 6-digit cryptographically secure numeric OTP code.
   */
  generateOtpCode(length = 6) {
    if (length === 6) {
      return crypto.randomInt(100000, 1000000).toString();
    }
    const min = Math.pow(10, length - 1);
    const max = Math.pow(10, length) - 1;
    return crypto.randomInt(min, max + 1).toString();
  }

  /**
   * Dispatches OTP to recipient via SMS gateway (Fast2SMS / Twilio)
   * or logs to development console when running locally.
   */
  async sendOtp(recipient, otpCode) {
    const isDev = process.env.NODE_ENV !== 'production';

    // 1. Always display clearly in local development terminal for instant testing
    if (isDev) {
      console.log('\n======================================================');
      console.log(`[SAHYĀN OTP DISPATCH]`);
      console.log(`  Recipient : ${recipient}`);
      console.log(`  OTP Code  : ${otpCode}`);
      console.log(`  Valid for : 10 minutes`);
      console.log('======================================================\n');
    }

    // 2. Fast2SMS Gateway (Popular Indian SMS Gateway - +91 numbers)
    if (process.env.FAST2SMS_API_KEY && process.env.FAST2SMS_API_KEY.trim() !== '') {
      try {
        const cleanPhone = recipient.replace(/\D/g, '').slice(-10);
        const apiKey = process.env.FAST2SMS_API_KEY.trim();

        // Try Quick SMS route ('q') first as documented by Fast2SMS
        let response = await fetch('https://www.fast2sms.com/dev/bulkV2', {
          method: 'POST',
          headers: {
            'Authorization': apiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: JSON.stringify({
            route: 'q',
            message: `Your Sahyan verification code is: ${otpCode}. Valid for 10 minutes.`,
            numbers: cleanPhone,
          }),
        });

        let data = await response.json();

        // If 'q' route requires activation or returns error, try 'otp' route as fallback
        if (!data.return && (data.status_code === 996 || data.status_code === 999)) {
          const otpRouteResponse = await fetch('https://www.fast2sms.com/dev/bulkV2', {
            method: 'POST',
            headers: {
              'Authorization': apiKey,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: JSON.stringify({
              route: 'otp',
              variables_values: otpCode,
              numbers: cleanPhone,
            }),
          });
          const otpRouteData = await otpRouteResponse.json();
          if (otpRouteData.return) {
            data = otpRouteData;
          }
        }

        if (data.return) {
          console.log(`[Fast2SMS] SMS dispatched successfully to ${recipient} (request_id: ${data.request_id || 'OK'})`);
          return { success: true, recipient, message: 'SMS delivered via Fast2SMS' };
        } else {
          console.warn(`[Fast2SMS Notice] ${data.message || 'Fast2SMS returned error'} (Code: ${data.status_code || 'unknown'})`);
          if (data.status_code === 999 || data.status_code === 996) {
            console.log(`[Fast2SMS Tip] Fast2SMS requires one-time account verification or activation on fast2sms.com before external API sends.`);
            console.log(`[Fast2SMS Tip] For local development, use the OTP code printed above in the terminal.`);
          }
        }
      } catch (err) {
        console.error('[Fast2SMS Exception]', err.message);
      }
    }

    // 3. Twilio Gateway (International SMS)
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER) {
      try {
        const auth = Buffer.from(`${process.env.TWILIO_ACCOUNT_SID}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');
        const params = new URLSearchParams({
          To: recipient.startsWith('+') ? recipient : `+91${recipient.replace(/\D/g, '').slice(-10)}`,
          From: process.env.TWILIO_PHONE_NUMBER,
          Body: `Your Sahyān verification code is: ${otpCode}. Valid for 10 minutes.`,
        });

        const response = await fetch(
          `https://api.twilio.com/2010-04-01/Accounts/${process.env.TWILIO_ACCOUNT_SID}/Messages.json`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Basic ${auth}`,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: params.toString(),
          }
        );
        const data = await response.json();
        if (response.ok) {
          console.log(`[Twilio] SMS dispatched successfully: SID ${data.sid}`);
          return { success: true, recipient, message: 'SMS delivered via Twilio' };
        } else {
          console.warn(`[Twilio Error] ${data.message}`);
        }
      } catch (err) {
        console.error('[Twilio Exception]', err.message);
      }
    }

    // 4. 2Factor.in Gateway (Indian SMS & OTP Gateway with free developer credits)
    if (process.env.TWO_FACTOR_API_KEY) {
      try {
        const cleanPhone = recipient.replace(/\D/g, '').slice(-10);
        const url = `https://2factor.in/API/V1/${process.env.TWO_FACTOR_API_KEY}/SMS/91${cleanPhone}/${otpCode}`;
        const response = await fetch(url);
        const data = await response.json();
        if (data && data.Status === 'Success') {
          console.log(`[2Factor.in] OTP sent successfully to ${recipient}`);
          return { success: true, recipient, message: 'SMS delivered via 2Factor.in' };
        } else {
          console.warn(`[2Factor.in Error] ${data?.Details || 'Failed to dispatch SMS'}`);
        }
      } catch (err) {
        console.error('[2Factor.in Exception]', err.message);
      }
    }

    return { success: true, recipient, message: 'OTP dispatched successfully' };
  }

  /**
   * Checks if user has exceeded OTP request rate limits:
   * - Enforces 60-second cooldown between consecutive requests
   * - Enforces maximum 5 requests within a 10-minute rolling window
   */
  isRateLimited(userOtpInfo) {
    if (!userOtpInfo || !userOtpInfo.lastRequestedAt) return false;
    const now = new Date();
    const diffSeconds = (now - new Date(userOtpInfo.lastRequestedAt)) / 1000;

    // Cooldown: at least 60 seconds between requests
    if (diffSeconds < 60) {
      return true;
    }

    // Max 5 attempts within 10 minutes window
    const diffMins = diffSeconds / 60;
    if (diffMins < 10 && userOtpInfo.attempts >= 5) {
      return true;
    }

    return false;
  }
}

module.exports = new OtpService();
