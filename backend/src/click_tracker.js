/**
 * Click tracking and redirect handler
 * Logs clicks and redirects users to affiliate links
 */

export async function trackClick(request, env) {
  try {
    const url = new URL(request.url);
    const offerUrl = url.searchParams.get("offer_url");
    const userId = url.searchParams.get("user_id");
    const offerId = url.searchParams.get("offer_id");
    
    if (!offerUrl || !userId) {
      return new Response(JSON.stringify({
        error: 'Missing required parameters: offer_url and user_id'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const clickId = `click_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const timestamp = Date.now();
    
    // Log click data
    const clickData = {
      clickId,
      userId,
      offerId: offerId || 'unknown',
      offerUrl,
      timestamp,
      userAgent: request.headers.get('User-Agent'),
      referer: request.headers.get('Referer'),
      ip: request.headers.get('CF-Connecting-IP'),
      country: request.headers.get('CF-IPCountry'),
      device: detectDevice(request.headers.get('User-Agent'))
    };

    // Store click in KV
    await env.CLICKS.put(clickId, JSON.stringify(clickData));
    
    // Update click stats for offer
    if (offerId) {
      await updateOfferStats(env, offerId, 'click');
    }
    
    // Update user click history
    await updateUserClickHistory(env, userId, offerId);

    // Redirect to affiliate link with click tracking
    const trackingUrl = new URL(offerUrl);
    trackingUrl.searchParams.set('click_id', clickId);
    trackingUrl.searchParams.set('source', 'streaky_app');
    
    return Response.redirect(trackingUrl.toString(), 302);
    
  } catch (error) {
    console.error('Error tracking click:', error);
    return new Response(JSON.stringify({
      error: 'Internal server error'
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function updateOfferStats(env, offerId, type) {
  try {
    const statsKey = `offer_stats_${offerId}`;
    const existing = await env.OFFERS.get(statsKey);
    const stats = existing ? JSON.parse(existing) : {
      impressions: 0,
      clicks: 0,
      sales: 0,
      revenue: 0,
      lastUpdated: Date.now()
    };
    
    if (type === 'click') {
      stats.clicks += 1;
    } else if (type === 'sale') {
      stats.sales += 1;
    }
    
    stats.lastUpdated = Date.now();
    await env.OFFERS.put(statsKey, JSON.stringify(stats));
  } catch (error) {
    console.error('Error updating offer stats:', error);
  }
}

async function updateUserClickHistory(env, userId, offerId) {
  try {
    const userKey = `user_${userId}`;
    const existing = await env.USERS.get(userKey);
    const profile = existing ? JSON.parse(existing) : {
      ctrHistory: {},
      favoriteCats: [],
      geo: 'IN',
      activeHour: new Date().getHours(),
      totalClicks: 0,
      lastActive: Date.now()
    };
    
    profile.totalClicks += 1;
    profile.lastActive = Date.now();
    
    // Update category preferences based on clicks
    if (offerId) {
      const offers = await env.OFFERS.get("offer_feed");
      if (offers) {
        const offersList = JSON.parse(offers);
        const offer = offersList.find(o => o.id === offerId);
        if (offer && offer.category) {
          profile.ctrHistory[offer.category] = (profile.ctrHistory[offer.category] || 0) + 1;
          
          // Update favorite categories
          if (!profile.favoriteCats.includes(offer.category)) {
            profile.favoriteCats.push(offer.category);
          }
          
          // Keep only top 5 favorite categories
          if (profile.favoriteCats.length > 5) {
            profile.favoriteCats = profile.favoriteCats.slice(0, 5);
          }
        }
      }
    }
    
    await env.USERS.put(userKey, JSON.stringify(profile));
  } catch (error) {
    console.error('Error updating user profile:', error);
  }
}

function detectDevice(userAgent) {
  if (!userAgent) return 'unknown';
  
  if (/Mobile|Android|iPhone|iPad/.test(userAgent)) {
    return 'mobile';
  } else if (/Tablet/.test(userAgent)) {
    return 'tablet';
  } else {
    return 'desktop';
  }
}