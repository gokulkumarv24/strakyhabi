/**
 * Analytics logging utilities for Cloudflare Worker
 */

/**
 * Log analytics event to KV
 */
export async function logAnalytics(env, eventName, properties = {}) {
  try {
    const event = {
      eventName,
      properties,
      timestamp: new Date().toISOString(),
      id: crypto.randomUUID(),
    };

    // Store individual event
    await env.USER_KV.put(
      `analytics:event:${event.id}`,
      JSON.stringify(event),
      { expirationTtl: 60 * 60 * 24 * 30 } // 30 days
    );

    // Update daily aggregates
    const today = new Date().toISOString().split('T')[0];
    const dailyKey = `analytics:daily:${today}`;
    
    const existingDaily = await env.USER_KV.get(dailyKey);
    const dailyData = existingDaily ? JSON.parse(existingDaily) : {
      date: today,
      events: {},
      totalEvents: 0,
    };

    // Increment event count
    dailyData.events[eventName] = (dailyData.events[eventName] || 0) + 1;
    dailyData.totalEvents += 1;
    dailyData.lastUpdated = new Date().toISOString();

    await env.USER_KV.put(dailyKey, JSON.stringify(dailyData));

    console.log('Analytics logged:', eventName, properties);
  } catch (error) {
    console.error('Analytics logging error:', error);
  }
}

/**
 * Get analytics data for a date range
 */
export async function getAnalytics(env, startDate, endDate) {
  try {
    const dailyData = [];
    const currentDate = new Date(startDate);
    const end = new Date(endDate);

    while (currentDate <= end) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const dailyKey = `analytics:daily:${dateStr}`;
      
      const data = await env.USER_KV.get(dailyKey);
      if (data) {
        dailyData.push(JSON.parse(data));
      }

      currentDate.setDate(currentDate.getDate() + 1);
    }

    return dailyData;
  } catch (error) {
    console.error('Analytics retrieval error:', error);
    return [];
  }
}

/**
 * Log user session
 */
export async function logUserSession(env, userId, sessionData = {}) {
  const sessionId = crypto.randomUUID();
  const session = {
    sessionId,
    userId,
    startTime: new Date().toISOString(),
    ...sessionData,
  };

  await env.USER_KV.put(
    `session:${sessionId}`,
    JSON.stringify(session),
    { expirationTtl: 60 * 60 * 24 } // 24 hours
  );

  // Update user's last session
  await env.USER_KV.put(
    `user:${userId}:last_session`,
    sessionId,
    { expirationTtl: 60 * 60 * 24 * 7 } // 7 days
  );

  return sessionId;
}

/**
 * Log performance metrics
 */
export async function logPerformance(env, metric, value, tags = {}) {
  const performanceEvent = {
    metric,
    value,
    tags,
    timestamp: new Date().toISOString(),
  };

  await logAnalytics(env, 'performance_metric', performanceEvent);
}

/**
 * Log error event
 */
export async function logError(env, error, context = {}) {
  const errorEvent = {
    message: error.message,
    stack: error.stack,
    context,
    timestamp: new Date().toISOString(),
  };

  await logAnalytics(env, 'error', errorEvent);
}

/**
 * Get popular categories
 */
export async function getPopularCategories(env, limit = 10) {
  try {
    // Get recent analytics data
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30); // Last 30 days

    const dailyData = await getAnalytics(env, startDate, endDate);
    
    const categoryCount = {};
    
    dailyData.forEach(day => {
      Object.keys(day.events).forEach(eventName => {
        if (eventName.includes('category')) {
          categoryCount[eventName] = (categoryCount[eventName] || 0) + day.events[eventName];
        }
      });
    });

    return Object.entries(categoryCount)
      .sort(([,a], [,b]) => b - a)
      .slice(0, limit)
      .map(([category, count]) => ({ category, count }));
  } catch (error) {
    console.error('Error getting popular categories:', error);
    return [];
  }
}

/**
 * Get user engagement metrics
 */
export async function getUserEngagement(env, userId) {
  try {
    const sessions = await env.USER_KV.get(`user:${userId}:sessions`);
    const sessionsData = sessions ? JSON.parse(sessions) : [];

    const now = new Date();
    const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const recentSessions = sessionsData.filter(session => 
      new Date(session.startTime) > last30Days
    );

    return {
      totalSessions: sessionsData.length,
      recentSessions: recentSessions.length,
      avgSessionLength: calculateAverageSessionLength(recentSessions),
      lastActiveDate: sessionsData.length > 0 
        ? sessionsData[sessionsData.length - 1].startTime 
        : null,
    };
  } catch (error) {
    console.error('Error getting user engagement:', error);
    return null;
  }
}

/**
 * Calculate average session length
 */
function calculateAverageSessionLength(sessions) {
  if (sessions.length === 0) return 0;

  const totalLength = sessions.reduce((sum, session) => {
    if (session.endTime) {
      const start = new Date(session.startTime);
      const end = new Date(session.endTime);
      return sum + (end - start);
    }
    return sum;
  }, 0);

  return totalLength / sessions.length;
}

/**
 * Clean up old analytics data
 */
export async function cleanupOldAnalytics(env, olderThanDays = 90) {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);
    
    // This would need to be implemented with a list of keys
    // For now, we rely on TTL for cleanup
    console.log('Analytics cleanup scheduled for data older than', cutoffDate);
  } catch (error) {
    console.error('Analytics cleanup error:', error);
  }
}