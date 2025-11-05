// Quick Test Server for Affiliate Revenue System
const http = require('http');
const url = require('url');

console.log('🚀 Starting Affiliate Revenue Test Server...');

// Mock data - simulates your real affiliate system
const offers = [
    { 
        offerId: 'amazon_001', 
        title: 'Amazon Electronics Sale - Up to 50% Off', 
        description: 'Get amazing deals on electronics, gadgets, and more',
        cpcRate: 8.50, 
        cpsRate: 12, 
        source: 'vCommission',
        category: 'Electronics',
        image: 'https://via.placeholder.com/300x200/FF9800/white?text=Amazon'
    },
    { 
        offerId: 'flipkart_002', 
        title: 'Flipkart Fashion Festival', 
        description: 'Trendy clothes, shoes, and accessories at best prices',
        cpcRate: 5.00, 
        cpsRate: 15, 
        source: 'Admitad',
        category: 'Fashion',
        image: 'https://via.placeholder.com/300x200/2196F3/white?text=Flipkart'
    },
    { 
        offerId: 'myntra_003', 
        title: 'Myntra End of Season Sale', 
        description: 'Fashion brands with up to 70% discount',
        cpcRate: 6.50, 
        cpsRate: 18, 
        source: 'Cuelinks',
        category: 'Fashion',
        image: 'https://via.placeholder.com/300x200/E91E63/white?text=Myntra'
    },
    { 
        offerId: 'swiggy_004', 
        title: 'Swiggy Food Delivery', 
        description: 'Order food online with exclusive discounts',
        cpcRate: 3.00, 
        cpsRate: 8, 
        source: 'Impact',
        category: 'Food',
        image: 'https://via.placeholder.com/300x200/FF5722/white?text=Swiggy'
    },
    { 
        offerId: 'booking_005', 
        title: 'Booking.com Travel Deals', 
        description: 'Book hotels, flights with amazing cashback',
        cpcRate: 12.00, 
        cpsRate: 25, 
        source: 'Awin',
        category: 'Travel',
        image: 'https://via.placeholder.com/300x200/4CAF50/white?text=Booking'
    }
];

// User earnings tracking
const userEarnings = {
    totalCpc: 0,
    totalCps: 0,
    totalClicks: 0,
    totalSales: 0,
    clickHistory: [],
    saleHistory: []
};

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const method = req.method;
    
    // CORS headers for browser testing
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    res.setHeader('Content-Type', 'application/json');
    
    console.log(`${method} ${parsedUrl.pathname}`);
    
    try {
        // Handle different API endpoints
        if (parsedUrl.pathname === '/api/offers') {
            // Get all available offers
            res.statusCode = 200;
            res.end(JSON.stringify({
                success: true,
                offers: offers,
                total: offers.length
            }));
        }
        else if (parsedUrl.pathname.startsWith('/api/click/')) {
            // Track offer click - CPC revenue
            const pathParts = parsedUrl.pathname.split('/');
            const offerId = pathParts[3];
            const userId = pathParts[4] || 'user123';
            
            const offer = offers.find(o => o.offerId === offerId);
            if (offer) {
                userEarnings.totalCpc += offer.cpcRate;
                userEarnings.totalClicks += 1;
                userEarnings.clickHistory.push({
                    offerId: offerId,
                    offerTitle: offer.title,
                    earned: offer.cpcRate,
                    timestamp: new Date().toISOString()
                });
                
                res.statusCode = 200;
                res.end(JSON.stringify({
                    success: true,
                    message: `Click tracked! Earned ₹${offer.cpcRate}`,
                    earnings: userEarnings,
                    redirectUrl: `https://example.com/affiliate-link/${offerId}`
                }));
                
                console.log(`💰 CPC Earned: ₹${offer.cpcRate} from ${offer.title}`);
            } else {
                res.statusCode = 404;
                res.end(JSON.stringify({ success: false, error: 'Offer not found' }));
            }
        }
        else if (parsedUrl.pathname.startsWith('/api/sale/')) {
            // Track sale conversion - CPS revenue
            const pathParts = parsedUrl.pathname.split('/');
            const offerId = pathParts[3];
            const userId = pathParts[4] || 'user123';
            const saleAmount = parseFloat(parsedUrl.query.amount) || 100;
            
            const offer = offers.find(o => o.offerId === offerId);
            if (offer) {
                const commission = (saleAmount * offer.cpsRate / 100);
                userEarnings.totalCps += commission;
                userEarnings.totalSales += 1;
                userEarnings.saleHistory.push({
                    offerId: offerId,
                    offerTitle: offer.title,
                    saleAmount: saleAmount,
                    commission: commission,
                    timestamp: new Date().toISOString()
                });
                
                res.statusCode = 200;
                res.end(JSON.stringify({
                    success: true,
                    message: `Sale tracked! Earned ₹${commission.toFixed(2)} commission`,
                    earnings: userEarnings,
                    saleAmount: saleAmount,
                    commissionRate: offer.cpsRate
                }));
                
                console.log(`💰 CPS Earned: ₹${commission.toFixed(2)} from ${offer.title} (${offer.cpsRate}% of ₹${saleAmount})`);
            } else {
                res.statusCode = 404;
                res.end(JSON.stringify({ success: false, error: 'Offer not found' }));
            }
        }
        else if (parsedUrl.pathname.startsWith('/api/user/')) {
            // Get user earnings and statistics
            const pathParts = parsedUrl.pathname.split('/');
            const userId = pathParts[3] || 'user123';
            
            if (pathParts[4] === 'earnings') {
                const totalEarnings = userEarnings.totalCpc + userEarnings.totalCps;
                
                res.statusCode = 200;
                res.end(JSON.stringify({
                    success: true,
                    user: userId,
                    earnings: {
                        total: totalEarnings,
                        cpc: userEarnings.totalCpc,
                        cps: userEarnings.totalCps,
                        clicks: userEarnings.totalClicks,
                        sales: userEarnings.totalSales
                    },
                    history: {
                        clicks: userEarnings.clickHistory,
                        sales: userEarnings.saleHistory
                    },
                    projections: {
                        monthly_1000_users: totalEarnings * 1000,
                        monthly_10000_users: totalEarnings * 10000
                    }
                }));
            } else {
                res.statusCode = 200;
                res.end(JSON.stringify({
                    success: true,
                    user: userId,
                    profile: {
                        totalClicks: userEarnings.totalClicks,
                        totalSales: userEarnings.totalSales,
                        favoriteCategory: 'Electronics',
                        memberSince: '2024-01-01'
                    }
                }));
            }
        }
        else if (parsedUrl.pathname === '/api/stats') {
            // Overall system statistics
            const totalEarnings = userEarnings.totalCpc + userEarnings.totalCps;
            
            res.statusCode = 200;
            res.end(JSON.stringify({
                success: true,
                system_stats: {
                    total_offers: offers.length,
                    total_networks: 5,
                    total_earnings: totalEarnings,
                    avg_cpc: offers.reduce((sum, o) => sum + o.cpcRate, 0) / offers.length,
                    avg_cps: offers.reduce((sum, o) => sum + o.cpsRate, 0) / offers.length
                },
                revenue_potential: {
                    per_user_per_month: '₹50-200',
                    thousand_users: '₹50,000-200,000',
                    ten_thousand_users: '₹500,000-2,000,000'
                }
            }));
        }
        else {
            // API documentation endpoint
            res.statusCode = 200;
            res.end(JSON.stringify({
                success: true,
                message: 'Affiliate Revenue API Test Server',
                endpoints: {
                    'GET /api/offers': 'Get all available offers',
                    'POST /api/click/{offerId}/{userId}': 'Track CPC click',
                    'POST /api/sale/{offerId}/{userId}?amount=100': 'Track CPS sale',
                    'GET /api/user/{userId}/earnings': 'Get user earnings',
                    'GET /api/user/{userId}': 'Get user profile',
                    'GET /api/stats': 'Get system statistics'
                },
                current_earnings: userEarnings,
                test_urls: [
                    'http://localhost:3000/api/click/amazon_001/user123',
                    'http://localhost:3000/api/sale/amazon_001/user123?amount=500',
                    'http://localhost:3000/api/user/user123/earnings'
                ]
            }));
        }
    } catch (error) {
        console.error('Server Error:', error);
        res.statusCode = 500;
        res.end(JSON.stringify({ 
            success: false, 
            error: 'Internal server error',
            details: error.message 
        }));
    }
});

const PORT = 3000;
server.listen(PORT, () => {
    console.log(`\n🚀 Affiliate Revenue Test Server is running!`);
    console.log(`📍 Server URL: http://localhost:${PORT}`);
    console.log(`\n📊 Test your affiliate system:`);
    console.log(`   Browser: http://localhost:${PORT}`);
    console.log(`   Offers:  http://localhost:${PORT}/api/offers`);
    console.log(`   Click:   http://localhost:${PORT}/api/click/amazon_001/user123`);
    console.log(`   Sale:    http://localhost:${PORT}/api/sale/amazon_001/user123?amount=500`);
    console.log(`   Earnings: http://localhost:${PORT}/api/user/user123/earnings`);
    console.log(`\n💰 Ready to test CPC (clicks) and CPS (sales) revenue!`);
    console.log(`📱 Open the HTML demo and backend server together for full testing\n`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down test server...');
    console.log(`💰 Final Earnings Summary:`);
    console.log(`   Total CPC: ₹${userEarnings.totalCpc.toFixed(2)} (${userEarnings.totalClicks} clicks)`);
    console.log(`   Total CPS: ₹${userEarnings.totalCps.toFixed(2)} (${userEarnings.totalSales} sales)`);
    console.log(`   Total Revenue: ₹${(userEarnings.totalCpc + userEarnings.totalCps).toFixed(2)}`);
    process.exit(0);
});