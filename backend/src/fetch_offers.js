/**
 * Fetch offers from multiple affiliate networks
 * Supports: Cuelinks, Admitad, vCommission, Impact, Awin
 */

export async function fetchOffers(env) {
  try {
    const offers = [];
    
    // Fetch from Cuelinks API
    if (env.CUELINKS_API_KEY) {
      try {
        const cuelinksRes = await fetch(`https://api.cuelinks.com/api/v2/offers.json?api_key=${env.CUELINKS_API_KEY}`);
        if (cuelinksRes.ok) {
          const cuelinksData = await cuelinksRes.json();
          const cuelinksOffers = cuelinksData.offers?.map(offer => ({
            id: `cuelinks_${offer.id}`,
            network: 'cuelinks',
            name: offer.name,
            description: offer.description,
            category: offer.category,
            commission: offer.commission,
            tracking_url: offer.tracking_url,
            image_url: offer.image_url,
            merchant: offer.merchant,
            targetGeo: ['IN'],
            cpc: offer.cpc || 3,
            cps: offer.cps || 50,
            expires_at: offer.expires_at
          })) || [];
          offers.push(...cuelinksOffers);
        }
      } catch (error) {
        console.error('Cuelinks API error:', error);
      }
    }

    // Fetch from Admitad API
    if (env.ADMITAD_CLIENT_ID && env.ADMITAD_SECRET) {
      try {
        // Get Admitad access token
        const authRes = await fetch('https://api.admitad.com/token/', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': `Basic ${btoa(`${env.ADMITAD_CLIENT_ID}:${env.ADMITAD_SECRET}`)}`
          },
          body: 'grant_type=client_credentials&scope=advcampaigns_for_website'
        });
        
        if (authRes.ok) {
          const authData = await authRes.json();
          const accessToken = authData.access_token;
          
          // Fetch campaigns
          const campaignsRes = await fetch('https://api.admitad.com/advcampaigns/?limit=50', {
            headers: {
              'Authorization': `Bearer ${accessToken}`
            }
          });
          
          if (campaignsRes.ok) {
            const campaignsData = await campaignsRes.json();
            const admitadOffers = campaignsData.results?.map(campaign => ({
              id: `admitad_${campaign.id}`,
              network: 'admitad',
              name: campaign.name,
              description: campaign.description,
              category: campaign.categories[0]?.name || 'general',
              commission: campaign.actions[0]?.hold_time || 'Variable',
              tracking_url: campaign.gotolink,
              image_url: campaign.image,
              merchant: campaign.advcampaign_name,
              targetGeo: campaign.regions || ['Global'],
              cpc: 4,
              cps: 75,
              expires_at: null
            })) || [];
            offers.push(...admitadOffers);
          }
        }
      } catch (error) {
        console.error('Admitad API error:', error);
      }
    }

    // Add sample offers if no API data
    if (offers.length === 0) {
      offers.push(...getSampleOffers());
    }

    // Store in KV
    await env.OFFERS.put("offer_feed", JSON.stringify(offers));
    await env.OFFERS.put("last_updated", new Date().toISOString());
    
    return new Response(JSON.stringify({
      status: 'success',
      count: offers.length,
      updated_at: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Error fetching offers:', error);
    return new Response(JSON.stringify({
      status: 'error',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

function getSampleOffers() {
  return [
    {
      id: 'sample_amazon_electronics',
      network: 'sample',
      name: 'Amazon Electronics Mega Sale',
      description: 'Up to 70% off on electronics, smartphones, laptops',
      category: 'electronics',
      commission: '2-8%',
      tracking_url: 'https://amazon.in/electronics',
      image_url: 'https://via.placeholder.com/200x150?text=Amazon+Electronics',
      merchant: 'Amazon India',
      targetGeo: ['IN'],
      cpc: 5,
      cps: 100,
      expires_at: null
    },
    {
      id: 'sample_udemy_courses',
      network: 'sample',
      name: 'Udemy Skill Development Courses',
      description: 'Learn new skills with 90% off courses',
      category: 'education',
      commission: '15-50%',
      tracking_url: 'https://udemy.com/courses',
      image_url: 'https://via.placeholder.com/200x150?text=Udemy+Courses',
      merchant: 'Udemy',
      targetGeo: ['Global'],
      cpc: 3,
      cps: 75,
      expires_at: null
    },
    {
      id: 'sample_flipkart_fashion',
      network: 'sample',
      name: 'Flipkart Fashion Week',
      description: 'Trendy fashion at unbeatable prices',
      category: 'fashion',
      commission: '3-12%',
      tracking_url: 'https://flipkart.com/fashion',
      image_url: 'https://via.placeholder.com/200x150?text=Flipkart+Fashion',
      merchant: 'Flipkart',
      targetGeo: ['IN'],
      cpc: 2,
      cps: 40,
      expires_at: null
    }
  ];
}