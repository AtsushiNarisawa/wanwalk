/**
 * 指定ルートのスポット座標を取得してOpenRouteServiceで計算
 */

const https = require('https');
const fs = require('fs');

// Supabase設定
const SUPABASE_URL = 'jkpenklhrlbctebkpvax.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8';

const API_KEY = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjdiOTg1NDM5Zjc2MTRkMTNiMTEwNjNjMGE1Njg3YTNjIiwiaCI6Im11cm11cjY0In0=';
const API_URL = 'api.openrouteservice.org';

// ルートID
const ROUTE_ID = '779d1816-0c24-4d91-b5b2-2fbfc3292024'; // 山下公園・赤レンガ倉庫コース

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

/**
 * OpenRouteService APIでルート計算
 */
function calculateRoute(coordinates) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      coordinates: coordinates,
      profile: 'foot-walking',
      format: 'geojson',
      instructions: false,
      elevation: true
    });

    const options = {
      hostname: API_URL,
      port: 443,
      path: '/v2/directions/foot-walking/geojson',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': API_KEY,
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error(`Parse error: ${e.message}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

/**
 * WKB POINTをパース
 */
function parseWKBPoint(wkbHex) {
  // バイトオーダー(2) + 型(8) + SRID(8) = 18文字
  // 経度(16) + 緯度(16) = 32文字
  const lonHex = wkbHex.substring(18, 34);
  const latHex = wkbHex.substring(34, 50);
  
  const lon = hexToDouble(lonHex);
  const lat = hexToDouble(latHex);
  
  return { lon, lat };
}

function hexToDouble(hex) {
  const byteData = Buffer.alloc(8);
  for (let i = 0; i < 8; i++) {
    byteData[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return byteData.readDoubleLE(0);
}

async function main() {
  try {
    console.log('📍 ルートスポット取得中...\n');

    // ルート情報取得
    const routes = await querySupabase(
      `official_routes?id=eq.${ROUTE_ID}&select=id,name,distance_meters`
    );

    if (!routes || routes.length === 0) {
      console.log('❌ ルートが見つかりません');
      return;
    }

    const route = routes[0];
    console.log(`✅ ルート: ${route.name}`);
    console.log(`📏 距離: ${(route.distance_meters / 1000).toFixed(2)} km\n`);

    // スポット取得
    const spots = await querySupabase(
      `route_spots?route_id=eq.${ROUTE_ID}&select=spot_order,name,location&order=spot_order.asc`
    );

    if (!spots || spots.length === 0) {
      console.log('❌ スポットが見つかりません');
      return;
    }

    console.log(`✅ ${spots.length}個のスポットを取得\n`);

    // 座標変換
    const coordinates = spots.map(spot => {
      const { lon, lat } = parseWKBPoint(spot.location);
      console.log(`  ${spot.spot_order}. ${spot.name}: (${lon}, ${lat})`);
      return [lon, lat];
    });

    console.log(`\n🚶 OpenRouteServiceでルート計算中...\n`);

    // ルート計算
    const result = await calculateRoute(coordinates);

    if (!result.features || result.features.length === 0) {
      console.log('❌ ルート計算失敗');
      return;
    }

    const geometry = result.features[0].geometry;
    const properties = result.features[0].properties;

    console.log(`✅ ルート計算成功！`);
    console.log(`📍 座標ポイント数: ${geometry.coordinates.length} points`);
    console.log(`📏 距離: ${(properties.summary.distance / 1000).toFixed(2)} km`);
    console.log(`⏱️  所要時間: ${Math.round(properties.summary.duration / 60)} 分\n`);

    // 結果を保存
    const outputFile = 'route_geometry_akarenga.json';
    fs.writeFileSync(outputFile, JSON.stringify(geometry, null, 2));
    console.log(`💾 ジオメトリを保存: ${outputFile}`);

    console.log(`\n🔍 最初の5ポイント:`);
    geometry.coordinates.slice(0, 5).forEach((coord, i) => {
      console.log(`  Point ${i}: [${coord[0]}, ${coord[1]}]`);
    });

  } catch (error) {
    console.error('❌ エラー:', error.message);
  }
}

// 実行
main();
