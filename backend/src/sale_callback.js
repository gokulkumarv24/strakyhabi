/**
 * Sale callback handler for affiliate postbacks
 * Receives and processes commission data from affiliate networks
 */

export async function handleSaleCallback(request, env) {
  try {
    const contentType = request.headers.get('Content-Type') || '';
    let data;
    
    if (contentType.includes('application/json')) {
      data = await request.json();
    } else if (contentType.includes('application/x-www-form-urlencoded')) {
      const formData = await request.formData();
      data = Object.fromEntries(formData.entries());
    } else {
      // Try to parse as JSON anyway
      const text = await request.text();
      try {
        data = JSON.parse(text);
      } catch {
        data = { rawData: text };
      }
    }
    
    console.log('Received sale callback:', data);
    
    // Extract standard fields (different networks use different field names)
    const saleData = {
      clickId: data.click_id || data.clickId || data.subid || data.sub_id,
      orderId: data.order_id || data.orderId || data.transaction_id,
      amount: parseFloat(data.amount || data.order_amount || data.sale_amount || 0),
      commission: parseFloat(data.commission || data.commission_amount || data.payout || 0),
      currency: data.currency || 'INR',
      network: detectNetwork(request.headers.get('User-Agent') || '', data),
      status: data.status || 'pending',
      timestamp: Date.now(),
      rawData: data
    };
    
    // Validate required fields
    if (!saleData.clickId && !saleData.orderId) {
      return new Response(JSON.stringify({
        status: 'error',
        message: 'Missing click_id or order_id'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const saleId = `sale_${saleData.clickId || saleData.orderId}_${Date.now()}`;
    
    // Store sale data
    await env.SALES.put(saleId, JSON.stringify(saleData));
    
    // Update offer stats if we can find the click
    if (saleData.clickId) {
      const clickData = await env.CLICKS.get(saleData.clickId);
      if (clickData) {
        const click = JSON.parse(clickData);
        if (click.offerId) {
          await updateOfferSaleStats(env, click.offerId, saleData.commission);
        }
        
        // Update user conversion data
        if (click.userId) {
          await updateUserConversionStats(env, click.userId, saleData);
        }
      }
    }
    
    // Log revenue metrics
    await logRevenueMetrics(env, saleData);
    
    return new Response(JSON.stringify({
      status: 'success',
      saleId: saleId,
      message: 'Sale logged successfully'
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Error handling sale callback:', error);
    return new Response(JSON.stringify({
      status: 'error',
      message: 'Internal server error',
      error: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function updateOfferSaleStats(env, offerId, commission) {
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
    
    stats.sales += 1;
    stats.revenue += commission;
    stats.lastUpdated = Date.now();
    
    await env.OFFERS.put(statsKey, JSON.stringify(stats));
  } catch (error) {
    console.error('Error updating offer sale stats:', error);
  }
}

async function updateUserConversionStats(env, userId, saleData) {
  try {
    const userKey = `user_${userId}`;
    const existing = await env.USERS.get(userKey);
    const profile = existing ? JSON.parse(existing) : {
      ctrHistory: {},
      favoriteCats: [],
      geo: 'IN',
      activeHour: new Date().getHours(),
      totalClicks: 0,
      totalSales: 0,
      totalEarnings: 0,
      lastActive: Date.now()
    };
    
    profile.totalSales += 1;
    profile.totalEarnings += saleData.commission;
    profile.lastActive = Date.now();
    
    await env.USERS.put(userKey, JSON.stringify(profile));
  } catch (error) {
    console.error('Error updating user conversion stats:', error);
  }
}

async function logRevenueMetrics(env, saleData) {
  try {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const metricsKey = `daily_metrics_${today}`;
    
    const existing = await env.SALES.get(metricsKey);
    const metrics = existing ? JSON.parse(existing) : {
      date: today,
      totalSales: 0,
      totalRevenue: 0,
      networks: {},
      avgOrderValue: 0
    };
    
    metrics.totalSales += 1;
    metrics.totalRevenue += saleData.commission;
    metrics.avgOrderValue = metrics.totalRevenue / metrics.totalSales;
    
    if (!metrics.networks[saleData.network]) {
      metrics.networks[saleData.network] = { sales: 0, revenue: 0 };
    }
    metrics.networks[saleData.network].sales += 1;
    metrics.networks[saleData.network].revenue += saleData.commission;
    
    await env.SALES.put(metricsKey, JSON.stringify(metrics));
  } catch (error) {
    console.error('Error logging revenue metrics:', error);
  }
}

function detectNetwork(userAgent, data) {
  // Detect network based on user agent or data patterns
  if (userAgent.includes('Admitad') || data.partner === 'admitad') return 'admitad';
  if (userAgent.includes('Cuelinks') || data.source === 'cuelinks') return 'cuelinks';
  if (userAgent.includes('vCommission') || data.network === 'vcommission') return 'vcommission';
  if (userAgent.includes('Impact') || data.campaign_name) return 'impact';
  if (userAgent.includes('Awin') || data.advertiser_id) return 'awin';
  
  return 'unknown';
}