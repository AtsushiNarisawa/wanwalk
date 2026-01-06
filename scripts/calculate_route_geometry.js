/**
 * OpenRouteService APIを使用してルートジオメトリを計算
 * 山下公園ルート(20000000-0000-0000-0000-000000000001)の検証用
 */

const https = require('https');
const fs = require('fs');

// 山下公園ルートのスポット座標（route_spotsから取得）
const ROUTE_SPOTS = [
  { order: 1, name: "山下公園入口", lon: 139.6476, lat: 35.4437 },
  { order: 2, name: "氷川丸前広場", lon: 139.6485, lat: 35.4435 },
  { order: 3, name: "海沿いプロムナード", lon: 139.649, lat: 35.443 },
  { order: 4, name: "水の階段・石のステージ", lon: 139.6495, lat: 35.4425 },
  { order: 5, name: "未来のバラ園", lon: 139.6488, lat: 35.4433 },
  { order: 6, name: "山下公園入口（ゴール）", lon: 139.6476, lat: 35.4437 }
];

const API_KEY = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjdiOTg1NDM5Zjc2MTRkMTNiMTEwNjNjMGE1Njg3YTNjIiwiaCI6Im11cm11cjY0In0=';
const API_URL = 'api.openrouteservice.org';

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

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`API Error: ${res.statusCode} - ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * メイン処理
 */
async function main() {
  try {
    console.log('🗺️  山下公園ルートのジオメトリ計算を開始...\n');

    // 座標配列を作成（OpenRouteServiceは [lon, lat] 形式）
    const coordinates = ROUTE_SPOTS.map(spot => [spot.lon, spot.lat]);
    
    console.log('📍 スポット座標:');
    ROUTE_SPOTS.forEach(spot => {
      console.log(`  ${spot.order}. ${spot.name}: [${spot.lon}, ${spot.lat}]`);
    });
    console.log('');

    // OpenRouteService APIでルート計算
    console.log('🚀 OpenRouteService API呼び出し中...');
    const result = await calculateRoute(coordinates);

    // 結果を確認
    if (result.features && result.features.length > 0) {
      const geometry = result.features[0].geometry;
      const properties = result.features[0].properties;

      console.log('✅ ルート計算成功!\n');
      console.log('📊 結果サマリー:');
      console.log(`  - 総距離: ${(properties.summary.distance / 1000).toFixed(2)} km`);
      console.log(`  - 所要時間: ${Math.round(properties.summary.duration / 60)} 分`);
      console.log(`  - 座標点数: ${geometry.coordinates.length} 点`);
      console.log('');

      // GeoJSON形式で保存
      const outputFile = __dirname + '/route_geometry_yamashita.json';
      fs.writeFileSync(outputFile, JSON.stringify(geometry, null, 2));
      console.log(`💾 ジオメトリを保存: ${outputFile}`);

      // PostGIS用のLINESTRING形式を生成
      const linestring = `LINESTRING(${geometry.coordinates.map(coord => `${coord[0]} ${coord[1]}`).join(', ')})`;
      const linestringSql = `ST_GeomFromText('${linestring}', 4326)`;
      
      console.log('\n📝 PostgreSQL/PostGIS用SQL:');
      console.log('```sql');
      console.log(`UPDATE official_routes`);
      console.log(`SET route_line = ${linestringSql}`);
      console.log(`WHERE id = '20000000-0000-0000-0000-000000000001';`);
      console.log('```');

    } else {
      console.error('❌ ルート計算失敗: 結果が空です');
    }

  } catch (error) {
    console.error('❌ エラー:', error.message);
    process.exit(1);
  }
}

// 実行
main();
