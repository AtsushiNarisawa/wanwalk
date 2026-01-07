/**
 * データベースの全ルートを一覧表示
 */

const https = require('https');

// Supabase設定
const SUPABASE_URL = 'jkpenklhrlbctebkpvax.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8';

/**
 * Supabase APIリクエスト
 */
function querySupabase(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SUPABASE_URL,
      port: 443,
      path: `/rest/v1/${path}`,
      method: 'GET',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve(data);
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function listRoutes() {
  try {
    console.log('📍 全ルートを取得中...\n');

    // 全ルート取得（距離順にソート）
    const routes = await querySupabase(
      "official_routes?select=id,name,distance_meters,route_line&order=distance_meters.desc"
    );

    if (!routes || routes.length === 0) {
      console.log('❌ ルートが見つかりません');
      return;
    }

    console.log(`✅ ${routes.length}件のルートが見つかりました\n`);

    // 距離順に表示
    routes.forEach((route, index) => {
      const hasRouteLine = route.route_line ? '✅' : '❌';
      const distance = (route.distance_meters / 1000).toFixed(2);
      console.log(`${index + 1}. ${route.name}`);
      console.log(`   ID: ${route.id}`);
      console.log(`   距離: ${distance} km`);
      console.log(`   route_line: ${hasRouteLine} ${route.route_line ? `(${route.route_line.length}文字)` : '(未設定)'}`);
      console.log('');
    });

    // route_lineが設定されているルート
    const withRouteLine = routes.filter(r => r.route_line);
    console.log(`\n📊 route_lineが設定済み: ${withRouteLine.length}件`);
    console.log(`📊 route_line未設定: ${routes.length - withRouteLine.length}件`);

  } catch (error) {
    console.error('❌ エラー:', error.message);
  }
}

// 実行
listRoutes();
