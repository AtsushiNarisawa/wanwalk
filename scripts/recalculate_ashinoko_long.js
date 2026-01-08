/**
 * 芦ノ湖畔ロングウォークのジオメトリを再計算
 * OpenRouteService APIを使用
 */

const https = require('https');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

// Supabase設定
const SUPABASE_URL = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || 'YOUR_SUPABASE_SERVICE_KEY';

// OpenRouteService API設定
const API_KEY = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjdiOTg1NDM5Zjc2MTRkMTNiMTEwNjNjMGE1Njg3YTNjIiwiaCI6Im11cm11cjY0In0=';
const API_URL = 'api.openrouteservice.org';

// 芦ノ湖畔ロングウォークのルートID
const ROUTE_ID = '6ae42d51-4221-4075-a2c7-cb8572e17cf7';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

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
 * ルートのスポットを取得
 */
async function getRouteSpots(routeId) {
  const { data, error } = await supabase
    .rpc('get_route_spots_as_text', { p_route_id: routeId });

  if (error) {
    throw new Error(`Failed to fetch spots: ${error.message}`);
  }

  return data;
}

/**
 * ジオメトリをファイルに保存
 */
function saveGeometry(geometry) {
  const outputFile = `${__dirname}/route_geometry_ashinoko_long_walk.json`;
  fs.writeFileSync(outputFile, JSON.stringify(geometry, null, 2));
  return outputFile;
}

/**
 * UPDATE SQLを生成
 */
function generateUpdateSQL(routeId, geometry) {
  const linestring = `LINESTRING(${geometry.coordinates.map(coord => `${coord[0]} ${coord[1]}`).join(', ')})`;
  return `UPDATE official_routes SET route_line = ST_GeomFromText('${linestring}', 4326) WHERE id = '${routeId}';`;
}

/**
 * メイン処理
 */
async function main() {
  try {
    console.log('🗺️  芦ノ湖畔ロングウォークのジオメトリ再計算を開始...\n');

    // スポットを取得
    console.log('📍 スポット取得中...');
    const spots = await getRouteSpots(ROUTE_ID);
    
    if (spots.length < 2) {
      throw new Error('スポットが2つ未満です');
    }

    console.log(`  ✓ ${spots.length}個のスポット取得完了\n`);
    console.log('📍 スポット情報:');
    spots.forEach((spot, i) => {
      console.log(`  ${i + 1}. ${spot.location_text}`);
    });
    console.log('');

    // 座標配列を作成（OpenRouteServiceは [lon, lat] 形式）
    const coordinates = spots.map(spot => {
      // PostGISのPOINT形式 "POINT(lon lat)" をパース
      const match = spot.location_text.match(/POINT\(([\d.]+)\s+([\d.]+)\)/);
      if (!match) {
        throw new Error(`Invalid location format: ${spot.location_text}`);
      }
      return [parseFloat(match[1]), parseFloat(match[2])];
    });

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

      // ファイル保存
      const outputFile = saveGeometry(geometry);
      console.log(`  - 保存先: ${outputFile}`);

      // SQL生成
      const sql = generateUpdateSQL(ROUTE_ID, geometry);
      const sqlFile = `${__dirname}/update_ashinoko_long_walk.sql`;
      fs.writeFileSync(sqlFile, sql);
      console.log(`  - SQL保存先: ${sqlFile}\n`);

      console.log('📝 次の手順:');
      console.log(`  1. ${sqlFile} を開く`);
      console.log(`  2. 内容をコピー`);
      console.log(`  3. Supabase Studio SQL Editorに貼り付けて実行`);

    } else {
      throw new Error('ルート計算失敗: 結果が空です');
    }

  } catch (error) {
    console.error('❌ エラー:', error.message);
    process.exit(1);
  }
}

// 実行
main();
