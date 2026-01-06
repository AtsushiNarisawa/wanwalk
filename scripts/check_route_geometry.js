/**
 * データベースに保存されているルートジオメトリを確認
 */

const https = require('https');

// Supabase設定
const SUPABASE_URL = 'jkpenklhrlbctebkpvax.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8';

/**
 * Supabase APIリクエスト
 */
function querySupabase(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SUPABASE_URL,
      port: 443,
      path: `/rest/v1/${path}`,
      method: method,
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    };

    if (body && method !== 'GET') {
      const postData = JSON.stringify(body);
      options.headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed);
        } catch (e) {
          resolve(data);
        }
      });
    });

    req.on('error', reject);

    if (body && method !== 'GET') {
      req.write(JSON.stringify(body));
    }
    
    req.end();
  });
}

async function checkRouteGeometry() {
  try {
    console.log('📍 山下公園ルートのジオメトリを確認中...\n');

    // 山下公園ルート取得（route_lineフィールドを含む）
    const routes = await querySupabase(
      "official_routes?id=eq.20000000-0000-0000-0000-000000000001&select=id,name,route_line"
    );

    if (!routes || routes.length === 0) {
      console.log('❌ ルートが見つかりません');
      return;
    }

    const route = routes[0];
    console.log(`✅ ルート名: ${route.name}`);
    console.log(`📊 ID: ${route.id}`);

    if (!route.route_line) {
      console.log('❌ route_line フィールドが空です（まだ保存されていません）');
      console.log('\n💡 次のステップ: update_route_geometry.js を実行してジオメトリを保存してください');
      return;
    }

    // PostGIS geometryの形式を解析
    const routeLine = route.route_line;
    
    if (typeof routeLine === 'string') {
      console.log(`✅ route_line: テキスト形式 (WKT)`);
      console.log(`📏 データ長: ${routeLine.length} 文字`);
      console.log(`🔍 先頭100文字: ${routeLine.substring(0, 100)}...`);
      
      // LINESTRING の座標数をカウント
      const coordMatches = routeLine.match(/[\d\.]+\s+[\d\.]+/g);
      if (coordMatches) {
        console.log(`📍 座標ポイント数: ${coordMatches.length} points`);
      }
    } else if (typeof routeLine === 'object' && routeLine.coordinates) {
      console.log(`✅ route_line: GeoJSON形式`);
      console.log(`📍 座標ポイント数: ${routeLine.coordinates.length} points`);
      console.log(`🔍 最初の座標: ${JSON.stringify(routeLine.coordinates[0])}`);
      console.log(`🔍 最後の座標: ${JSON.stringify(routeLine.coordinates[routeLine.coordinates.length - 1])}`);
    } else {
      console.log(`⚠️ route_line: 不明な形式`);
      console.log(JSON.stringify(routeLine, null, 2));
    }

    console.log('\n✅ 確認完了');

  } catch (error) {
    console.error('❌ エラー:', error.message);
  }
}

// 実行
checkRouteGeometry();
