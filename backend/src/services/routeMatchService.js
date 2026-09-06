const {
  calculateDistanceKm,
  decodePolyline,
  minDistanceToPolylineKm,
  calculateRouteOverlap,
} = require('../utils/polylineUtils');

/**
 * Intelligent Route Match Engine for Sahyān
 * Deterministic, explainable 6-factor route matching algorithm.
 *
 * Scoring Weights:
 * - Route overlap: 40%
 * - Pickup deviation: 20%
 * - Destination deviation: 15%
 * - Time compatibility: 10%
 * - Driver reliability: 10%
 * - Seat availability: 5%
 * Total = 100%
 */

const WEIGHTS = {
  routeOverlap: 0.40,
  pickupDeviation: 0.20,
  destinationDeviation: 0.15,
  timeCompatibility: 0.10,
  driverReliability: 0.10,
  seatAvailability: 0.05,
};

const ROUTE_OVERLAP_TOLERANCE_KM = 5.0;

const GRADE_BANDS = [
  { min: 90, grade: 'Excellent Match' },
  { min: 80, grade: 'Very Good Match' },
  { min: 70, grade: 'Good Match' },
  { min: 60, grade: 'Fair Match' },
  { min: 0, grade: 'Weak Match' },
];

/**
 * Determine match grade from final normalized score
 * @param {number} score - Integer score between 0 and 100
 * @returns {string}
 */
function getMatchGrade(score) {
  for (const band of GRADE_BANDS) {
    if (score >= band.min) {
      return band.grade;
    }
  }
  return 'Weak Match';
}

/**
 * Calculate pickup deviation score (0-100) from distance in kilometers
 * 0 - 1 km   -> 95 - 100
 * 1 - 3 km   -> 80 - 95
 * 3 - 5 km   -> 60 - 80
 * 5 - 10 km  -> 25 - 60
 * > 10 km    -> 0 - 25
 */
function calculatePickupScore(distanceKm) {
  if (distanceKm <= 0) return 100;
  if (distanceKm <= 1.0) {
    return Math.round(100 - distanceKm * 5);
  }
  if (distanceKm <= 3.0) {
    return Math.round(95 - ((distanceKm - 1.0) / 2.0) * 15);
  }
  if (distanceKm <= 5.0) {
    return Math.round(80 - ((distanceKm - 3.0) / 2.0) * 20);
  }
  if (distanceKm <= 10.0) {
    return Math.round(60 - ((distanceKm - 5.0) / 5.0) * 35);
  }
  return Math.max(0, Math.round(25 - (distanceKm - 10.0) * 2.5));
}

/**
 * Calculate destination deviation score (0-100) from distance in kilometers
 * Uses identical smooth progressive degradation curve as pickup.
 */
function calculateDestinationScore(distanceKm) {
  if (distanceKm <= 0) return 100;
  if (distanceKm <= 1.0) {
    return Math.round(100 - distanceKm * 5);
  }
  if (distanceKm <= 3.0) {
    return Math.round(95 - ((distanceKm - 1.0) / 2.0) * 15);
  }
  if (distanceKm <= 5.0) {
    return Math.round(80 - ((distanceKm - 3.0) / 2.0) * 20);
  }
  if (distanceKm <= 10.0) {
    return Math.round(60 - ((distanceKm - 5.0) / 5.0) * 35);
  }
  return Math.max(0, Math.round(25 - (distanceKm - 10.0) * 2.5));
}

/**
 * Calculate departure time compatibility score (0-100)
 * 0 - 10 min   -> 95 - 100
 * 10 - 30 min  -> 80 - 95
 * 30 - 60 min  -> 60 - 80
 * 60 - 120 min -> 25 - 60
 * > 120 min    -> 0 - 25
 */
function calculateTimeScore(diffMinutes) {
  if (diffMinutes <= 0) return 100;
  if (diffMinutes <= 10) {
    return Math.round(100 - diffMinutes * 0.5);
  }
  if (diffMinutes <= 30) {
    return Math.round(95 - ((diffMinutes - 10) / 20) * 15);
  }
  if (diffMinutes <= 60) {
    return Math.round(80 - ((diffMinutes - 30) / 30) * 20);
  }
  if (diffMinutes <= 120) {
    return Math.round(60 - ((diffMinutes - 60) / 60) * 35);
  }
  return Math.max(0, Math.round(25 - (diffMinutes - 120) * 0.2));
}

/**
 * Calculate deterministic driver reliability score (0-100)
 * Handles unrated drivers safely with a neutral score instead of 100/100.
 */
function calculateReliabilityScore(driver) {
  if (!driver) {
    return 70; // Neutral fallback
  }

  const rating = Number(driver.rating);
  const ratingCount = Number(driver.ratingCount || 0);

  // New driver with no rating history gets neutral reliability score
  if (isNaN(rating) || rating <= 0 || ratingCount === 0) {
    let neutralScore = 70;
    if (driver.isVerified || driver.isPhoneVerified || driver.isIdentityVerified) {
      neutralScore += 5;
    }
    return Math.min(100, neutralScore);
  }

  // Known rating: base score up to 85, review volume up to 10, verification bonus up to 5
  const clampedRating = Math.max(1, Math.min(5, rating));
  const baseScore = (clampedRating / 5.0) * 85;
  const reviewBonus = Math.min(10, ratingCount * 2);
  const verificationBonus =
    driver.isVerified || driver.isIdentityVerified || driver.isPhoneVerified ? 5 : 0;

  return Math.min(100, Math.round(baseScore + reviewBonus + verificationBonus));
}

/**
 * Calculate seat availability score (0-100)
 * Available >= requested -> 80 to 100
 * Available < requested -> 0
 */
function calculateSeatScore(availableSeats, requestedSeats = 1) {
  const avail = Number(availableSeats) || 0;
  const req = Number(requestedSeats) || 1;

  if (avail < req) return 0;

  const spareSeats = avail - req;
  // 1 seat req, 5 avail -> 80 + 20 = 100
  // 4 seats req, 4 avail -> 80
  return Math.min(100, 80 + spareSeats * 5);
}

/**
 * Dynamically generate 2-4 human-readable explainable reasons
 * based on the strongest contributing factors.
 */
function generateExplainableReasons({ factors, metrics, ride }) {
  const candidates = [];

  // Route overlap
  if (factors.routeOverlap >= 85) {
    candidates.push({
      priority: factors.routeOverlap * 1.5,
      text: `${metrics.routeOverlapPercentage}% of your route overlaps`,
    });
  } else if (factors.routeOverlap >= 65) {
    candidates.push({
      priority: factors.routeOverlap,
      text: `${metrics.routeOverlapPercentage}% route overlap along your journey`,
    });
  }

  // Pickup proximity
  if (metrics.pickupDistanceKm <= 1.0) {
    candidates.push({
      priority: 95,
      text: `Pickup is only ${metrics.pickupDistanceKm} km away`,
    });
  } else if (metrics.pickupDistanceKm <= 3.0) {
    candidates.push({
      priority: 85,
      text: `Pickup point within ${metrics.pickupDistanceKm} km`,
    });
  }

  // Destination alignment
  if (metrics.destinationDistanceKm <= 1.0) {
    candidates.push({
      priority: 92,
      text: `Drop-off aligns directly (${metrics.destinationDistanceKm} km deviation)`,
    });
  } else if (metrics.destinationDistanceKm <= 3.0) {
    candidates.push({
      priority: 82,
      text: `Drop-off within ${metrics.destinationDistanceKm} km of destination`,
    });
  }

  // Time compatibility
  if (metrics.departureDifferenceMinutes <= 10) {
    candidates.push({
      priority: 90,
      text:
        metrics.departureDifferenceMinutes === 0
          ? 'Exact departure time match'
          : `Departure is ${metrics.departureDifferenceMinutes} min from your preferred time`,
    });
  } else if (metrics.departureDifferenceMinutes <= 30) {
    candidates.push({
      priority: 75,
      text: `Departure within ${metrics.departureDifferenceMinutes} min of your preferred time`,
    });
  }

  // Driver reliability
  const driver = ride.driver;
  if (driver && Number(driver.rating) >= 4.5 && Number(driver.ratingCount || 0) > 0) {
    candidates.push({
      priority: 80,
      text: `Top-rated driver (${Number(driver.rating).toFixed(1)} rating)`,
    });
  } else if (driver && (driver.isVerified || driver.isIdentityVerified)) {
    candidates.push({
      priority: 70,
      text: 'Verified community driver',
    });
  }

  // Seat availability
  if (ride.availableSeats >= 3) {
    candidates.push({
      priority: 65,
      text: `${ride.availableSeats} seats available`,
    });
  }

  // Sort candidate reasons by priority descending and take top 2 to 4
  candidates.sort((a, b) => b.priority - a.priority);

  const selected = candidates.slice(0, 4).map((c) => c.text);

  // Fallback if no strong reasons triggered
  if (selected.length < 2) {
    selected.push(`${ride.availableSeats} seats available on this ride`);
    if (selected.length < 2) {
      selected.push('Scheduled ride on your general route');
    }
  }

  return selected;
}

/**
 * Evaluate a single candidate ride against passenger criteria
 * @param {Object} params
 * @param {Object} [params.passengerOrigin] - { latitude, longitude }
 * @param {Object} [params.passengerDestination] - { latitude, longitude }
 * @param {Date} [params.passengerDepartureTime]
 * @param {Array<Object>} [params.passengerPoints] - Sampled coordinates of passenger route
 * @param {Object} params.candidateRide - Mongoose/lean ride object
 * @param {number} [params.requestedSeats=1]
 * @returns {Object} Structured match result
 */
function evaluateRideMatch({
  passengerOrigin,
  passengerDestination,
  passengerDepartureTime,
  passengerPoints = [],
  candidateRide,
  requestedSeats = 1,
}) {
  if (!candidateRide) {
    throw new Error('candidateRide is required for match evaluation.');
  }

  // 1. Decode driver route polyline
  let driverPoints = [];
  if (candidateRide.route && candidateRide.route.encodedPolyline) {
    driverPoints = decodePolyline(candidateRide.route.encodedPolyline);
  }

  // Fallback: If no polyline, synthesize minimal 2-point line from origin to destination
  if (driverPoints.length === 0 && candidateRide.origin && candidateRide.destination) {
    driverPoints = [
      {
        latitude: candidateRide.origin.latitude,
        longitude: candidateRide.origin.longitude,
      },
      {
        latitude: candidateRide.destination.latitude,
        longitude: candidateRide.destination.longitude,
      },
    ];
  }

  // 2. Measure Pickup Deviation
  let pickupDistanceKm = 0;
  if (passengerOrigin && passengerOrigin.latitude !== undefined && passengerOrigin.longitude !== undefined) {
    if (driverPoints.length > 0) {
      const pickupMatch = minDistanceToPolylineKm(
        { latitude: passengerOrigin.latitude, longitude: passengerOrigin.longitude },
        driverPoints
      );
      pickupDistanceKm = Number(pickupMatch.distanceKm.toFixed(1));
    } else if (candidateRide.origin) {
      pickupDistanceKm = Number(
        calculateDistanceKm(
          passengerOrigin.latitude,
          passengerOrigin.longitude,
          candidateRide.origin.latitude,
          candidateRide.origin.longitude
        ).toFixed(1)
      );
    }
  }
  const pickupScore = calculatePickupScore(pickupDistanceKm);

  // 3. Measure Destination Deviation
  let destinationDistanceKm = 0;
  if (
    passengerDestination &&
    passengerDestination.latitude !== undefined &&
    passengerDestination.longitude !== undefined
  ) {
    if (driverPoints.length > 0) {
      const destMatch = minDistanceToPolylineKm(
        { latitude: passengerDestination.latitude, longitude: passengerDestination.longitude },
        driverPoints
      );
      // Destination deviation is the minimum of distance to driver route and distance to driver final destination
      const directDestDist = candidateRide.destination
        ? calculateDistanceKm(
            passengerDestination.latitude,
            passengerDestination.longitude,
            candidateRide.destination.latitude,
            candidateRide.destination.longitude
          )
        : destMatch.distanceKm;

      destinationDistanceKm = Number(
        Math.min(destMatch.distanceKm, directDestDist).toFixed(1)
      );
    } else if (candidateRide.destination) {
      destinationDistanceKm = Number(
        calculateDistanceKm(
          passengerDestination.latitude,
          passengerDestination.longitude,
          candidateRide.destination.latitude,
          candidateRide.destination.longitude
        ).toFixed(1)
      );
    }
  }
  const destScore = calculateDestinationScore(destinationDistanceKm);

  // 4. Measure Route Overlap
  let routeOverlapPercentage = 0;
  if (Array.isArray(passengerPoints) && passengerPoints.length > 0 && driverPoints.length > 0) {
    const overlapResult = calculateRouteOverlap({
      passengerPoints,
      driverPoints,
      toleranceKm: ROUTE_OVERLAP_TOLERANCE_KM,
    });
    routeOverlapPercentage = overlapResult.overlapPercentage;
  } else {
    // If no passenger route points available, estimate route overlap from pickup + destination scores
    routeOverlapPercentage = Math.round((pickupScore * 0.5) + (destScore * 0.5));
  }
  const routeOverlapScore = Math.max(0, Math.min(100, routeOverlapPercentage));

  // 5. Measure Departure Time Compatibility
  let departureDifferenceMinutes = 0;
  if (passengerDepartureTime && candidateRide.departureTime) {
    const pTime = new Date(passengerDepartureTime).getTime();
    const dTime = new Date(candidateRide.departureTime).getTime();
    if (!isNaN(pTime) && !isNaN(dTime)) {
      departureDifferenceMinutes = Math.round(Math.abs(dTime - pTime) / (60 * 1000));
    }
  }
  const timeScore = calculateTimeScore(departureDifferenceMinutes);

  // 6. Measure Driver Reliability
  const reliabilityScore = calculateReliabilityScore(candidateRide.driver);

  // 7. Measure Seat Availability
  const seatScore = calculateSeatScore(candidateRide.availableSeats, requestedSeats);

  // 8. Calculate Final Deterministic Weighted Score
  const rawWeightedScore =
    routeOverlapScore * WEIGHTS.routeOverlap +
    pickupScore * WEIGHTS.pickupDeviation +
    destScore * WEIGHTS.destinationDeviation +
    timeScore * WEIGHTS.timeCompatibility +
    reliabilityScore * WEIGHTS.driverReliability +
    seatScore * WEIGHTS.seatAvailability;

  const finalScore = Math.max(0, Math.min(100, Math.round(rawWeightedScore)));
  const matchGrade = getMatchGrade(finalScore);

  const factors = {
    routeOverlap: routeOverlapScore,
    pickupDeviation: pickupScore,
    destinationDeviation: destScore,
    timeCompatibility: timeScore,
    driverReliability: reliabilityScore,
    seatAvailability: seatScore,
  };

  const metrics = {
    routeOverlapPercentage,
    pickupDistanceKm,
    destinationDistanceKm,
    departureDifferenceMinutes,
  };

  const reasons = generateExplainableReasons({
    factors,
    metrics,
    ride: candidateRide,
  });

  return {
    score: finalScore,
    grade: matchGrade,
    factors,
    metrics,
    reasons,
  };
}

/**
 * Evaluate and rank an array of candidate rides for passenger search
 * Sorts primarily by match score descending, with departure time difference
 * as secondary tie-breaker.
 */
function evaluateAndRankCandidates({
  passengerOrigin,
  passengerDestination,
  passengerDepartureTime,
  passengerPoints = [],
  candidateRides = [],
  requestedSeats = 1,
}) {
  if (!Array.isArray(candidateRides) || candidateRides.length === 0) {
    return [];
  }

  const evaluated = candidateRides.map((ride) => {
    const match = evaluateRideMatch({
      passengerOrigin,
      passengerDestination,
      passengerDepartureTime,
      passengerPoints,
      candidateRide: ride,
      requestedSeats,
    });

    const normalizedRide = {
      ...ride,
      id: ride._id ? ride._id.toString() : (ride.id || ''),
    };
    if (normalizedRide.driver && normalizedRide.driver._id) {
      normalizedRide.driver.id = normalizedRide.driver._id.toString();
    }
    if (normalizedRide.vehicle && normalizedRide.vehicle._id) {
      normalizedRide.vehicle.id = normalizedRide.vehicle._id.toString();
    }

    const proximityDesc =
      match.metrics.pickupDistanceKm <= 1
        ? 'Direct pickup'
        : `Pickup within ${match.metrics.pickupDistanceKm} km`;

    const timeDesc =
      match.metrics.departureDifferenceMinutes === 0
        ? 'Exact departure time'
        : `${match.metrics.departureDifferenceMinutes} min departure difference`;

    const matchPreview = `${match.score}% Match | ${match.grade}`;

    return {
      ride: normalizedRide,
      match,
      pickupDistanceKm: match.metrics.pickupDistanceKm,
      destinationDistanceKm: match.metrics.destinationDistanceKm,
      departureDifferenceMinutes: match.metrics.departureDifferenceMinutes,
      availableSeats: ride.availableSeats,
      matchPreview,
    };
  });

  // Rank by match score descending, then departureDifferenceMinutes ascending
  evaluated.sort((a, b) => {
    if (b.match.score !== a.match.score) {
      return b.match.score - a.match.score;
    }
    if (a.departureDifferenceMinutes !== b.departureDifferenceMinutes) {
      return a.departureDifferenceMinutes - b.departureDifferenceMinutes;
    }
    return a.pickupDistanceKm - b.pickupDistanceKm;
  });

  return evaluated;
}

module.exports = {
  WEIGHTS,
  ROUTE_OVERLAP_TOLERANCE_KM,
  GRADE_BANDS,
  getMatchGrade,
  calculatePickupScore,
  calculateDestinationScore,
  calculateTimeScore,
  calculateReliabilityScore,
  calculateSeatScore,
  generateExplainableReasons,
  evaluateRideMatch,
  evaluateAndRankCandidates,
};
