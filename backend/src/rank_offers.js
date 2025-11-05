/**
 * Dynamic offer ranking algorithm
 * Ranks offers based on CTR, CVR, and EPC metrics
 */

export async function rankOffers(env) {
  try {
    const raw = await env.OFFERS.get("offer_feed");
    if (!raw) {
      return new Response(JSON.stringify({
        status: 'error',
        message: 'No offers found'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const offers = JSON.parse(raw);
    
    // Calculate performance metrics for each offer
    const rankedOffers = await Promise.all(offers.map(async (offer) => {
      const statsKey = `offer_stats_${offer.id}`;
      const statsData = await env.OFFERS.get(statsKey);
      const stats = statsData ? JSON.parse(statsData) : {
        impressions: 100, // Default impressions for new offers
        clicks: 0,
        sales: 0,
        revenue: 0
      };
      
      // Calculate metrics
      const ctr = stats.impressions > 0 ? stats.clicks / stats.impressions : 0;
      const cvr = stats.clicks > 0 ? stats.sales / stats.clicks : 0;
      const epc = stats.clicks > 0 ? stats.revenue / stats.clicks : 0;
      
      // Normalize scores (0-1 range)
      const normalizedCTR = Math.min(ctr * 100, 1); // Cap at 100% CTR
      const normalizedCVR = Math.min(cvr * 100, 1); // Cap at 100% CVR
      const normalizedEPC = Math.min(epc / 100, 1); // Normalize EPC to 0-1 range
      
      // Weighted scoring (CTR: 40%, CVR: 40%, EPC: 20%)
      const score = (0.4 * normalizedCTR) + (0.4 * normalizedCVR) + (0.2 * normalizedEPC);
      
      return {
        ...offer,
        ctr: ctr,
        cvr: cvr,
        epc: epc,
        score: score,
        stats: stats
      };
    }));
    
    // Sort by score (highest first)
    rankedOffers.sort((a, b) => b.score - a.score);
    
    // Store ranked offers
    await env.OFFERS.put("offer_feed_ranked", JSON.stringify(rankedOffers));
    await env.OFFERS.put("ranking_updated_at", new Date().toISOString());
    
    return new Response(JSON.stringify({
      status: 'success',
      message: 'Offers ranked successfully',
      count: rankedOffers.length,
      topOffer: rankedOffers[0]?.name || 'None',
      updated_at: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Error ranking offers:', error);
    return new Response(JSON.stringify({
      status: 'error',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}