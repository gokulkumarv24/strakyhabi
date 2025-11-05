/**
 * Main Cloudflare Worker index file
 * Routes requests to appropriate handlers
 */

import { fetchOffers } from "./fetch_offers.js";
import { trackClick } from "./click_tracker.js";
import { handleSaleCallback } from "./sale_callback.js";
import { rankOffers } from "./rank_offers.js";
import { predictiveRankOffers } from "./predictive_rank.js";
import { getUserProfile } from "./user_profile.js";

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const { pathname } = url;
    
    // Add CORS headers for all responses
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
    
    // Handle preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }
    
    try {
      let response;
      
      // Route handling
      if (pathname.startsWith('/offers/fetch') || pathname === '/offers') {
        response = await fetchOffers(env);
      }
      else if (pathname.startsWith('/offers/ranked')) {
        const ranked = await env.OFFERS.get("offer_feed_ranked");
        if (ranked) {
          response = new Response(ranked, {
            headers: { 'Content-Type': 'application/json' }
          });
        } else {
          response = new Response(JSON.stringify({
            status: 'error',
            message: 'No ranked offers found. Run ranking first.'
          }), {
            status: 404,
            headers: { 'Content-Type': 'application/json' }
          });
        }
      }
      else if (pathname.startsWith('/offers/personalized')) {
        const userId = url.searchParams.get('uid') || url.searchParams.get('user_id');
        if (!userId) {
          response = new Response(JSON.stringify({
            error: 'Missing user_id parameter'
          }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' }
          });
        } else {
          response = await predictiveRankOffers(env, userId);
        }
      }
      else if (pathname.startsWith('/click')) {
        response = await trackClick(request, env);
      }
      else if (pathname.startsWith('/affiliate/callback') || pathname.startsWith('/callback')) {
        response = await handleSaleCallback(request, env);
      }
      else if (pathname.startsWith('/rank')) {
        response = await rankOffers(env);
      }
      else if (pathname.startsWith('/user/profile')) {
        const userId = url.searchParams.get('uid') || url.searchParams.get('user_id');
        if (!userId) {
          response = new Response(JSON.stringify({
            error: 'Missing user_id parameter'
          }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' }
          });
        } else {
          const profile = await getUserProfile(env, userId);
          response = new Response(JSON.stringify(profile), {
            headers: { 'Content-Type': 'application/json' }
          });
        }
      }
      else if (pathname.startsWith('/analytics/daily')) {
        const date = url.searchParams.get('date') || new Date().toISOString().split('T')[0];
        const metrics = await env.SALES.get(`daily_metrics_${date}`);
        if (metrics) {
          response = new Response(metrics, {
            headers: { 'Content-Type': 'application/json' }
          });
        } else {
          response = new Response(JSON.stringify({
            status: 'error',
            message: 'No metrics found for date: ' + date
          }), {
            status: 404,
            headers: { 'Content-Type': 'application/json' }
          });
        }
      }
      else if (pathname === '/status' || pathname === '/') {
        const status = {
          status: 'active',
          service: 'Streaky Affiliate Engine',
          version: '1.2',
          timestamp: new Date().toISOString(),
          endpoints: [
            'GET /offers - Fetch latest offers',
            'GET /offers/ranked - Get ranked offers',
            'GET /offers/personalized?uid={user_id} - Get personalized offers',
            'GET /click?offer_url={url}&user_id={id}&offer_id={id} - Track click',
            'POST /affiliate/callback - Handle sale callbacks',
            'GET /rank - Rank offers by performance',
            'GET /user/profile?uid={user_id} - Get user profile',
            'GET /analytics/daily?date={YYYY-MM-DD} - Get daily metrics',
            'GET /status - This status page'
          ]
        };
        response = new Response(JSON.stringify(status, null, 2), {
          headers: { 'Content-Type': 'application/json' }
        });
      }
      else {
        response = new Response(JSON.stringify({
          status: 'error',
          message: 'Endpoint not found',
          path: pathname
        }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' }
        });
      }
      
      // Add CORS headers to response
      Object.entries(corsHeaders).forEach(([key, value]) => {
        response.headers.set(key, value);
      });
      
      return response;
      
    } catch (error) {
      console.error('Worker error:', error);
      
      const errorResponse = new Response(JSON.stringify({
        status: 'error',
        message: 'Internal server error',
        error: error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });
      
      return errorResponse;
    }
  },
  
  // Cron trigger handler
  async scheduled(event, env, ctx) {
    console.log('Cron triggered:', event.cron);
    
    try {
      if (event.cron === "0 0 * * *") {
        // Daily offer refresh
        console.log('Running daily offer refresh...');
        await fetchOffers(env);
      } else if (event.cron === "0 */6 * * *") {
        // 6-hourly ranking update
        console.log('Running offer ranking update...');
        await rankOffers(env);
      }
    } catch (error) {
      console.error('Cron job error:', error);
    }
  }
};