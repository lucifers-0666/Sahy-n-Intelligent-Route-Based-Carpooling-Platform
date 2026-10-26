const Booking = require('../models/Booking');
const User = require('../models/User');
const AuditLog = require('../models/AuditLog');

/**
 * Sahyān Fraud Detection & Risk Scoring Engine
 * Evaluates behavioral telemetry, dispute frequency, no-shows, bursts, and collusion.
 */
class FraudDetectionService {
  /**
   * Evaluates comprehensive fraud and abuse risk for a given user.
   * Calculates normalized riskScore (0-100) and assigns a proportionate risk tier.
   * 
   * @param {string|mongoose.Types.ObjectId} userId
   * @returns {Promise<{ riskScore: number, riskTier: string, signals: string[], appliedSafeguards: string[] }>}
   */
  static async evaluateUserRisk(userId) {
    const user = await User.findById(userId);
    if (!user) {
      return { riskScore: 0, riskTier: 'low', signals: [], appliedSafeguards: [] };
    }

    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

    // Fetch passenger's bookings in the last 30 days
    const recentBookings = await Booking.find({
      passenger: userId,
      createdAt: { $gte: thirtyDaysAgo },
    }).select('status paymentStatus dispute createdAt requestedSeats boardingPinLocked');

    const totalRecent = recentBookings.length;
    const unpaidReports = recentBookings.filter(
      (b) => b.paymentStatus === 'unpaid_reported' || (b.dispute && b.dispute.status !== 'none')
    ).length;

    const cancelledBookings = recentBookings.filter((b) => b.status === 'cancelled').length;
    const lockedPinBookings = recentBookings.filter((b) => b.boardingPinLocked === true).length;
    const burstBookings = recentBookings.filter((b) => b.createdAt >= oneHourAgo).length;

    const signals = [];
    let score = 0;

    // Signal 1: Unpaid cash reports (+25 per incident)
    if (unpaidReports > 0) {
      const penalty = Math.min(50, unpaidReports * 25);
      score += penalty;
      signals.push(`REPEATED_UNPAID_REPORTS: ${unpaidReports} reported unpaid contribution(s)`);
    }

    // Signal 2: High cancellation rate (> 50% with >= 4 bookings)
    if (totalRecent >= 4) {
      const cancelRate = cancelledBookings / totalRecent;
      if (cancelRate >= 0.5) {
        score += 20;
        signals.push(`ABUSIVE_CANCELLATION_PATTERN: ${(cancelRate * 100).toFixed(0)}% cancellation rate over ${totalRecent} bookings`);
      }
    }

    // Signal 3: Rapid booking burst (> 5 in 1 hour)
    if (burstBookings >= 5) {
      score += 15;
      signals.push(`RAPID_BOOKING_BURST: ${burstBookings} booking requests within 1 hour`);
    }

    // Signal 4: Repeated locked boarding PINs (failed attempt exhaustion)
    if (lockedPinBookings > 0) {
      score += 20;
      signals.push(`BOARDING_PIN_EXHAUSTION: ${lockedPinBookings} booking(s) with locked PIN from failed attempts`);
    }

    // Bound score between 0 and 100
    const finalScore = Math.min(100, Math.max(0, score));

    // Determine risk tier
    let tier = 'low';
    if (finalScore >= 75) tier = 'critical';
    else if (finalScore >= 50) tier = 'high';
    else if (finalScore >= 25) tier = 'medium';

    const appliedSafeguards = [];

    // Safeguard 1: If 2 or more unpaid reports or critical risk, restrict cash bookings
    if (unpaidReports >= 2 || finalScore >= 75) {
      if (user.capabilities && user.capabilities.canBookCash !== false) {
        user.capabilities.canBookCash = false;
        appliedSafeguards.push('RESTRICT_CASH_BOOKING');

        await AuditLog.create({
          action: 'FRAUD_RISK_TRIGGERED',
          targetUser: user._id,
          actorRole: 'system',
          reason: `Automated safeguard: Cash bookings restricted due to high non-payment risk (${unpaidReports} unpaid report(s), risk score: ${finalScore})`,
          metadata: { signals, riskScore: finalScore, riskTier: tier },
        });
      }
    }

    // Update user fraudMetrics
    if (!user.fraudMetrics) {
      user.fraudMetrics = {};
    }
    user.fraudMetrics.unpaidReportsCount = unpaidReports;
    user.fraudMetrics.cancellationsLast30Days = cancelledBookings;
    user.fraudMetrics.riskScore = finalScore;
    user.fraudMetrics.riskTier = tier;
    user.fraudMetrics.lastEvaluatedAt = new Date();

    await user.save();

    return {
      riskScore: finalScore,
      riskTier: tier,
      signals,
      appliedSafeguards,
    };
  }

  /**
   * Check for potential driver-passenger collusion or reciprocal rating manipulation.
   * 
   * @param {string|mongoose.Types.ObjectId} driverId
   * @param {string|mongoose.Types.ObjectId} passengerId
   * @returns {Promise<{ suspicious: boolean, reason?: string, completedRidesTogether: number }>}
   */
  static async detectCollusion(driverId, passengerId) {
    if (driverId.toString() === passengerId.toString()) {
      return { suspicious: true, reason: 'Driver and passenger are the same user account.', completedRidesTogether: 0 };
    }

    // Check shared rides
    const sharedCompletedBookings = await Booking.find({
      passenger: passengerId,
      status: 'completed',
    }).populate('ride', 'driver');

    const matchedRides = sharedCompletedBookings.filter(
      (b) => b.ride && b.ride.driver && b.ride.driver.toString() === driverId.toString()
    );

    const completedTogether = matchedRides.length;

    // If driver and passenger have completed more than 15 rides together in a short window
    if (completedTogether >= 15) {
      return {
        suspicious: true,
        reason: `High reciprocal frequency detected: ${completedTogether} completed journeys together.`,
        completedRidesTogether: completedTogether,
      };
    }

    return {
      suspicious: false,
      completedRidesTogether: completedTogether,
    };
  }
}

module.exports = FraudDetectionService;
