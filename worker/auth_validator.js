/**
 * JWT Authentication utilities for Cloudflare Worker
 */

/**
 * Generate JWT token
 */
export async function generateJWT(payload, secret) {
  const header = {
    alg: 'HS256',
    typ: 'JWT',
  };

  const now = Math.floor(Date.now() / 1000);
  const jwtPayload = {
    ...payload,
    iat: now,
    exp: now + (30 * 24 * 60 * 60), // 30 days
    iss: 'streaky-app',
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(jwtPayload));
  
  const signature = await sign(`${encodedHeader}.${encodedPayload}`, secret);
  
  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

/**
 * Verify JWT token
 */
export async function verifyJWT(token, secret) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      return null;
    }

    const [headerB64, payloadB64, signatureB64] = parts;
    
    // Verify signature
    const expectedSignature = await sign(`${headerB64}.${payloadB64}`, secret);
    if (signatureB64 !== expectedSignature) {
      return null;
    }

    // Decode and verify payload
    const payload = JSON.parse(base64UrlDecode(payloadB64));
    
    // Check expiration
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) {
      return null;
    }

    return payload;
  } catch (error) {
    console.error('JWT verification error:', error);
    return null;
  }
}

/**
 * Sign data with HMAC-SHA256
 */
async function sign(data, secret) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(data));
  return base64UrlEncode(new Uint8Array(signature));
}

/**
 * Base64 URL encode
 */
function base64UrlEncode(data) {
  if (typeof data === 'string') {
    data = new TextEncoder().encode(data);
  }
  
  const base64 = btoa(String.fromCharCode(...data));
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

/**
 * Base64 URL decode
 */
function base64UrlDecode(str) {
  // Add padding if needed
  str += '='.repeat((4 - str.length % 4) % 4);
  
  // Replace URL-safe characters
  str = str.replace(/-/g, '+').replace(/_/g, '/');
  
  // Decode
  const decoded = atob(str);
  return decoded;
}

/**
 * Generate secure random string
 */
export function generateSecureRandom(length = 32) {
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * Hash password using Web Crypto API
 */
export async function hashPassword(password, salt) {
  const encoder = new TextEncoder();
  const data = encoder.encode(password + salt);
  
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = new Uint8Array(hashBuffer);
  
  return Array.from(hashArray, byte => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * Verify password hash
 */
export async function verifyPassword(password, hash, salt) {
  const computedHash = await hashPassword(password, salt);
  return computedHash === hash;
}