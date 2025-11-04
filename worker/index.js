/**
 * Cloudflare Worker for Streaky App
 * Handles authentication, data sync, and API endpoints
 * Zero-cost serverless backend with KV storage
 */

import { verifyJWT, generateJWT } from './auth_validator.js';
import { logAnalytics } from './analytics_logger.js';

export default {
  async fetch(request, env, ctx) {
    // Add CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: corsHeaders,
      });
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;
      const method = request.method;

      // Health check endpoint
      if (path === '/health') {
        return new Response(JSON.stringify({
          status: 'healthy',
          timestamp: new Date().toISOString(),
          version: '1.0.0',
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Authentication endpoints (no auth required)
      if (path.startsWith('/auth/')) {
        return handleAuth(request, env, path, method);
      }

      // All other endpoints require authentication
      const authHeader = request.headers.get('Authorization');
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return new Response(JSON.stringify({ error: 'Missing or invalid authorization' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const token = authHeader.split(' ')[1];
      const payload = await verifyJWT(token, env.JWT_SECRET);
      
      if (!payload) {
        return new Response(JSON.stringify({ error: 'Invalid or expired token' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Route authenticated requests
      if (path.startsWith('/tasks')) {
        return handleTasks(request, env, path, method, payload);
      }
      
      if (path.startsWith('/streaks')) {
        return handleStreaks(request, env, path, method, payload);
      }
      
      if (path.startsWith('/user')) {
        return handleUser(request, env, path, method, payload);
      }
      
      if (path.startsWith('/premium')) {
        return handlePremium(request, env, path, method, payload);
      }
      
      if (path.startsWith('/analytics')) {
        return handleAnalytics(request, env, path, method, payload);
      }

      // 404 for unknown routes
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });

    } catch (error) {
      console.error('Worker error:', error);
      
      return new Response(JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};

/**
 * Handle authentication endpoints
 */
async function handleAuth(request, env, path, method) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
  };

  if (path === '/auth/register' && method === 'POST') {
    const { name, email, password } = await request.json();
    
    // Generate user ID
    const userId = crypto.randomUUID();
    
    // Generate JWT token
    const token = await generateJWT({
      userId,
      email,
      name,
    }, env.JWT_SECRET);

    // Store user in KV
    const userData = {
      id: userId,
      name,
      email,
      createdAt: new Date().toISOString(),
      subscriptionTier: 'free',
    };

    await env.USER_KV.put(`user:${userId}`, JSON.stringify(userData));

    // Log registration
    await logAnalytics(env, 'user_registered', { userId, email });

    return new Response(JSON.stringify({
      user: userData,
      token,
    }), {
      headers: corsHeaders,
    });
  }

  if (path === '/auth/login' && method === 'POST') {
    const { email } = await request.json();
    
    // For demo purposes, create or find user by email
    const userId = crypto.randomUUID();
    const token = await generateJWT({
      userId,
      email,
      name: 'Demo User',
    }, env.JWT_SECRET);

    const userData = {
      id: userId,
      name: 'Demo User',
      email,
      lastLogin: new Date().toISOString(),
      subscriptionTier: 'free',
    };

    await env.USER_KV.put(`user:${userId}`, JSON.stringify(userData));

    // Log login
    await logAnalytics(env, 'user_login', { userId, email });

    return new Response(JSON.stringify({
      user: userData,
      token,
    }), {
      headers: corsHeaders,
    });
  }

  if (path === '/auth/verify' && method === 'POST') {
    const { token } = await request.json();
    const payload = await verifyJWT(token, env.JWT_SECRET);
    
    return new Response(JSON.stringify({
      valid: !!payload,
      payload,
    }), {
      headers: corsHeaders,
    });
  }

  return new Response(JSON.stringify({ error: 'Auth endpoint not found' }), {
    status: 404,
    headers: corsHeaders,
  });
}

/**
 * Handle task endpoints
 */
async function handleTasks(request, env, path, method, userPayload) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
  };

  const userId = userPayload.userId;

  if (path === '/tasks/sync' && method === 'POST') {
    const { tasks, lastSyncTime } = await request.json();
    
    // Get existing tasks from KV
    const existingTasksJson = await env.USER_KV.get(`tasks:${userId}`);
    const existingTasks = existingTasksJson ? JSON.parse(existingTasksJson) : [];
    
    // Merge tasks (simple strategy: newest timestamp wins)
    const mergedTasks = mergeTasksData(existingTasks, tasks);
    
    // Save merged tasks back to KV
    await env.USER_KV.put(`tasks:${userId}`, JSON.stringify(mergedTasks));
    
    // Log sync event
    await logAnalytics(env, 'tasks_synced', { 
      userId, 
      taskCount: mergedTasks.length 
    });

    return new Response(JSON.stringify({
      tasks: mergedTasks,
      syncTime: new Date().toISOString(),
    }), {
      headers: corsHeaders,
    });
  }

  if (path === '/tasks' && method === 'GET') {
    const tasksJson = await env.USER_KV.get(`tasks:${userId}`);
    const tasks = tasksJson ? JSON.parse(tasksJson) : [];
    
    return new Response(JSON.stringify({ tasks }), {
      headers: corsHeaders,
    });
  }

  if (path === '/tasks' && method === 'POST') {
    const taskData = await request.json();
    taskData.userId = userId;
    taskData.createdAt = new Date().toISOString();
    
    // Get existing tasks
    const tasksJson = await env.USER_KV.get(`tasks:${userId}`);
    const tasks = tasksJson ? JSON.parse(tasksJson) : [];
    
    // Add new task
    tasks.push(taskData);
    
    // Save back to KV
    await env.USER_KV.put(`tasks:${userId}`, JSON.stringify(tasks));

    return new Response(JSON.stringify({ task: taskData }), {
      headers: corsHeaders,
    });
  }

  return new Response(JSON.stringify({ error: 'Task endpoint not found' }), {
    status: 404,
    headers: corsHeaders,
  });
}

/**
 * Handle streak endpoints
 */
async function handleStreaks(request, env, path, method, userPayload) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
  };

  const userId = userPayload.userId;

  if (path === '/streaks/sync' && method === 'POST') {
    const { streaks } = await request.json();
    
    // Get existing streaks from KV
    const existingStreaksJson = await env.USER_KV.get(`streaks:${userId}`);
    const existingStreaks = existingStreaksJson ? JSON.parse(existingStreaksJson) : [];
    
    // Merge streaks
    const mergedStreaks = mergeStreaksData(existingStreaks, streaks);
    
    // Save merged streaks back to KV
    await env.USER_KV.put(`streaks:${userId}`, JSON.stringify(mergedStreaks));

    return new Response(JSON.stringify({
      streaks: mergedStreaks,
      syncTime: new Date().toISOString(),
    }), {
      headers: corsHeaders,
    });
  }

  if (path === '/streaks/leaderboard' && method === 'GET') {
    // For demo purposes, return mock leaderboard
    const leaderboard = [
      { name: 'Alex Johnson', streak: 45, category: 'Fitness' },
      { name: 'Sarah Chen', streak: 38, category: 'Reading' },
      { name: 'Mike Davis', streak: 32, category: 'Coding' },
      { name: 'Emma Wilson', streak: 28, category: 'Meditation' },
      { name: 'John Smith', streak: 24, category: 'Writing' },
    ];

    return new Response(JSON.stringify({ leaderboard }), {
      headers: corsHeaders,
    });
  }

  return new Response(JSON.stringify({ error: 'Streak endpoint not found' }), {
    status: 404,
    headers: corsHeaders,
  });
}

/**
 * Handle user endpoints
 */
async function handleUser(request, env, path, method, userPayload) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
  };

  const userId = userPayload.userId;

  if (path === '/user/profile' && method === 'PUT') {
    const userData = await request.json();
    userData.lastModified = new Date().toISOString();
    
    await env.USER_KV.put(`user:${userId}`, JSON.stringify(userData));

    return new Response(JSON.stringify({ user: userData }), {
      headers: corsHeaders,
    });
  }

  if (path === '/user/analytics' && method === 'GET') {
    // Get user's tasks and streaks for analytics
    const tasksJson = await env.USER_KV.get(`tasks:${userId}`);
    const streaksJson = await env.USER_KV.get(`streaks:${userId}`);
    
    const tasks = tasksJson ? JSON.parse(tasksJson) : [];
    const streaks = streaksJson ? JSON.parse(streaksJson) : [];
    
    const analytics = calculateUserAnalytics(tasks, streaks);

    return new Response(JSON.stringify({ analytics }), {
      headers: corsHeaders,
    });
  }

  return new Response(JSON.stringify({ error: 'User endpoint not found' }), {
    status: 404,
    headers: corsHeaders,
  });
}

/**
 * Handle premium endpoints
 */
async function handlePremium(request, env, path, method, userPayload) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
  };

  if (path === '/premium/verify' && method === 'POST') {
    const { purchaseToken, productId } = await request.json();
    
    // In a real app, verify with Google Play or App Store
    // For demo purposes, assume verification succeeds
    const verificationResult = {
      valid: true,
      productId,
      expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days
    };

    // Update user subscription in KV
    const userJson = await env.USER_KV.get(`user:${userPayload.userId}`);
    const userData = userJson ? JSON.parse(userJson) : {};
    
    userData.subscriptionTier = 'premium';
    userData.subscriptionExpiry = verificationResult.expiryDate;
    
    await env.USER_KV.put(`user:${userPayload.userId}`, JSON.stringify(userData));

    // Log premium upgrade
    await logAnalytics(env, 'premium_upgrade', { 
      userId: userPayload.userId,
      productId 
    });

    return new Response(JSON.stringify(verificationResult), {
      headers: corsHeaders,
    });
  }

  return new Response(JSON.stringify({ error: 'Premium endpoint not found' }), {
    status: 404,
    headers: corsHeaders,
  });
}

/**
 * Handle analytics endpoints
 */
async function handleAnalytics(request, env, path, method, userPayload) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
  };

  if (path === '/analytics/event' && method === 'POST') {
    const { eventName, properties } = await request.json();
    
    await logAnalytics(env, eventName, {
      userId: userPayload.userId,
      ...properties,
    });

    return new Response(JSON.stringify({ success: true }), {
      headers: corsHeaders,
    });
  }

  return new Response(JSON.stringify({ error: 'Analytics endpoint not found' }), {
    status: 404,
    headers: corsHeaders,
  });
}

/**
 * Merge tasks data with conflict resolution
 */
function mergeTasksData(existingTasks, newTasks) {
  const taskMap = new Map();
  
  // Add existing tasks
  existingTasks.forEach(task => {
    taskMap.set(task.id, task);
  });
  
  // Merge new tasks (newer timestamp wins)
  newTasks.forEach(newTask => {
    const existing = taskMap.get(newTask.id);
    if (!existing || new Date(newTask.lastModified) > new Date(existing.lastModified)) {
      taskMap.set(newTask.id, newTask);
    }
  });
  
  return Array.from(taskMap.values());
}

/**
 * Merge streaks data with conflict resolution
 */
function mergeStreaksData(existingStreaks, newStreaks) {
  const streakMap = new Map();
  
  // Add existing streaks
  existingStreaks.forEach(streak => {
    streakMap.set(streak.id, streak);
  });
  
  // Merge new streaks (newer timestamp wins)
  newStreaks.forEach(newStreak => {
    const existing = streakMap.get(newStreak.id);
    if (!existing || new Date(newStreak.lastUpdated) > new Date(existing.lastUpdated)) {
      streakMap.set(newStreak.id, newStreak);
    }
  });
  
  return Array.from(streakMap.values());
}

/**
 * Calculate user analytics from tasks and streaks
 */
function calculateUserAnalytics(tasks, streaks) {
  const completedTasks = tasks.filter(task => task.isCompleted);
  const activeStreaks = streaks.filter(streak => streak.isActive);
  
  return {
    totalTasks: tasks.length,
    completedTasks: completedTasks.length,
    activeStreaks: activeStreaks.length,
    longestStreak: Math.max(...streaks.map(s => s.longestStreak), 0),
    completionRate: tasks.length > 0 ? (completedTasks.length / tasks.length) : 0,
    categories: [...new Set(tasks.map(task => task.category).filter(Boolean))],
  };
}