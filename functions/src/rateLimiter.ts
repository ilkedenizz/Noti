/**
 * In-memory sliding window rate limiter preparation for alert spam prevention.
 * Extensible for Redis / Firestore distributed rate limiting in production.
 */
interface RateLimitRecord {
  timestamps: number[];
}

const windowMs = 60 * 1000; // 1 minute window
const maxAlertsPerWindow = 10; // Max 10 alerts per sender per minute
const memoryStore = new Map<string, RateLimitRecord>();

export function checkRateLimit(senderId: string): { allowed: boolean; remaining: number } {
  const now = Date.now();
  const record = memoryStore.get(senderId) ?? { timestamps: [] };

  // Remove timestamps outside the sliding window
  const validTimestamps = record.timestamps.filter((ts) => now - ts < windowMs);

  if (validTimestamps.length >= maxAlertsPerWindow) {
    return {
      allowed: false,
      remaining: 0,
    };
  }

  validTimestamps.push(now);
  memoryStore.set(senderId, { timestamps: validTimestamps });

  return {
    allowed: true,
    remaining: maxAlertsPerWindow - validTimestamps.length,
  };
}
