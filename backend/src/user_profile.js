/**
 * User profile management for personalization
 */

export async function getUserProfile(env, userId) {
  try {
    const userKey = `user_${userId}`;
    const profile = await env.USERS.get(userKey);
    
    if (profile) {
      return JSON.parse(profile);
    }
    
    // Create default profile for new users
    const defaultProfile = {
      userId: userId,
      ctrHistory: {}, // category → click count
      favoriteCats: ["shopping", "electronics", "education"],
      geo: "IN",
      activeHour: new Date().getHours(),
      totalClicks: 0,
      totalSales: 0,
      totalEarnings: 0,
      createdAt: Date.now(),
      lastActive: Date.now()
    };
    
    await env.USERS.put(userKey, JSON.stringify(defaultProfile));
    return defaultProfile;
    
  } catch (error) {
    console.error('Error getting user profile:', error);
    return {
      userId: userId,
      ctrHistory: {},
      favoriteCats: ["shopping", "electronics"],
      geo: "IN",
      activeHour: 18,
      totalClicks: 0,
      totalSales: 0,
      totalEarnings: 0,
      createdAt: Date.now(),
      lastActive: Date.now()
    };
  }
}