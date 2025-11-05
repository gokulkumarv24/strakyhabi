/**
 * Predictive personalization ranking engine
 * Uses ML-like scoring for user-specific offer ranking
 */

import { getUserProfile } from "./user_profile.js";

export async function predictiveRankOffers(env, userId) {
  try {
    const raw = await env.OFFERS.get("offer_feed_ranked");
    if (!raw) {
      return new Response(JSON.stringify({
        status: 'error',
        message: 'No ranked offers found. Run ranking first.'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    const offers = JSON.parse(raw);
    const user = await getUserProfile(env, userId);
    const currentHour = new Date().getHours();
    
    // Personalize offers for this user
    const personalizedOffers = offers.map((offer) => {
      // Calculate preference match (0 or 1)
      const prefMatch = user.favoriteCats.includes(offer.category) ? 1 : 0;
      
      // Calculate geo weight (0 or 1)
      const geoWeight = offer.targetGeo?.includes(user.geo) ? 1 : 0;
      
      // Calculate time score (higher if user is active at this hour)
      const timeScore = Math.abs(user.activeHour - currentHour) < 3 ? 1 : 0;
      
      // Get user's historical CTR for this category
      const userCTR = user.ctrHistory[offer.category] ? 
        Math.min(user.ctrHistory[offer.category] / user.totalClicks, 1) : 0.02;
      
      // Use offer's CVR from ranking
      const offerCVR = offer.cvr || 0.01;
      
      // Weighted linear scoring
      const linearScore = 
        (0.35 * userCTR) +           // User's historical CTR for category
        (0.25 * offerCVR) +          // Offer's conversion rate
        (0.20 * prefMatch) +         // Category preference match
        (0.10 * geoWeight) +         // Geographic targeting
        (0.10 * timeScore);          // Time-based relevance
      
      // Apply sigmoid normalization for 0-1 range
      const personalizedScore = 1 / (1 + Math.exp(-linearScore * 10));
      
      return {
        ...offer,
        personalizedScore: personalizedScore,
        userCTR: userCTR,
        prefMatch: prefMatch,
        geoWeight: geoWeight,
        timeScore: timeScore
      };
    });
    
    // Sort by personalized score
    personalizedOffers.sort((a, b) => b.personalizedScore - a.personalizedScore);
    
    // Cache personalized ranking for this user
    await env.OFFERS.put(`offers_ranked_${userId}`, JSON.stringify(personalizedOffers));
    
    return new Response(JSON.stringify({
      status: 'success',
      offers: personalizedOffers,
      user: {
        id: userId,
        favoriteCats: user.favoriteCats,
        totalClicks: user.totalClicks,
        totalSales: user.totalSales
      },
      updated_at: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Error in predictive ranking:', error);
    return new Response(JSON.stringify({
      status: 'error',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}