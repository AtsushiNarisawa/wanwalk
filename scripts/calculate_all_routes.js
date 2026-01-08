/**
 * 全ルートのジオメトリを一括計算
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
 * ルートのスポットを取得（WKB形式対応）
 */
async function getRouteSpots(routeId) {
  // PostGIS RPC関数を使ってテキスト形式で取得
  const { data, error } = await supabase
    .rpc('get_route_spots_as_text', { p_route_id: routeId });

  if (error) {
    throw new Error(`Failed to fetch spots: ${error.message}`);
  }

  return data;
}

/**
 * 全ルートを取得
 */
async function getAllRoutes() {
  const { data, error } = await supabase
    .from('official_routes')
    .select('id, name')
    .order('name');

  if (error) {
    throw new Error(`Failed to fetch routes: ${error.message}`);
  }

  return data;
}

/**
 * ジオメトリをファイルに保存
 */
function saveGeometry(routeName, geometry) {
  const sanitizedName = routeName.replace(/[^a-zA-Z0-9]/g, '_').toLowerCase();
  const outputFile = `${__dirname}/route_geometry_${sanitizedName}.json`;
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
 * 単一ルートを処理
 */
async function processRoute(route, index, total) {
  try {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`[${index + 1}/${total}] 🗺️  ${route.name}`);
    console.log(`${'='.repeat(60)}\n`);

    // スポットを取得
    console.log('📍 スポット取得中...');
    const spots = await getRouteSpots(route.id);
    
    if (spots.length < 2) {
      console.log('⚠️  スキップ: スポットが2つ未満');
      return { success: false, reason: 'Not enough spots' };
    }

    // 座標配列を作成（OpenRouteServiceは [lon, lat] 形式）
    const coordinates = spots.map(spot => {
      // PostGISのPOINT形式 "POINT(lon lat)" をパース
      const match = spot.location.match(/POINT\(([\d.]+)\s+([\d.]+)\)/);
      if (!match) {
        throw new Error(`Invalid location format: ${spot.location}`);
      }
      return [parseFloat(match[1]), parseFloat(match[2])];
    });

    console.log(`  ✓ ${spots.length}個のスポット取得完了`);
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

      // ファイル保存
      const outputFile = saveGeometry(route.name, geometry);
      console.log(`  - 保存先: ${outputFile}`);

      // SQL生成
      const sql = generateUpdateSQL(route.id, geometry);

      return {
        success: true,
        routeId: route.id,
        routeName: route.name,
        points: geometry.coordinates.length,
        distance: properties.summary.distance,
        duration: properties.summary.duration,
        outputFile: outputFile,
        sql: sql
      };

    } else {
      console.error('❌ ルート計算失敗: 結果が空です');
      return { success: false, reason: 'Empty result' };
    }

  } catch (error) {
    console.error(`❌ エラー: ${error.message}`);
    return { success: false, reason: error.message };
  }
}

/**
 * メイン処理
 */
async function main() {
  try {
    console.log('🗺️  全ルートのジオメトリ計算を開始...\n');

    // 全ルートを取得
    console.log('📋 ルート一覧取得中...');
    const routes = await getAllRoutes();
    console.log(`  ✓ ${routes.length}個のルート取得完了\n`);

    // 結果を格納
    const results = [];
    const sqlStatements = [];

    // 各ルートを処理（レート制限を考慮して1秒間隔）
    for (let i = 0; i < routes.length; i++) {
      const result = await processRoute(routes[i], i, routes.length);
      results.push(result);

      if (result.success) {
        sqlStatements.push(result.sql);
      }

      // レート制限を回避するため、次のルートまで1秒待機
      if (i < routes.length - 1) {
        console.log('\n⏳ 次のルートまで1秒待機...');
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    // サマリーを表示
    console.log(`\n${'='.repeat(60)}`);
    console.log('📊 処理完了サマリー');
    console.log(`${'='.repeat(60)}\n`);

    const successCount = results.filter(r => r.success).length;
    const failCount = results.filter(r => !r.success).length;

    console.log(`✅ 成功: ${successCount}/${routes.length}`);
    console.log(`❌ 失敗: ${failCount}/${routes.length}\n`);

    if (successCount > 0) {
      console.log('📝 成功したルート:');
      results
        .filter(r => r.success)
        .forEach((r, i) => {
          console.log(`  ${i + 1}. ${r.routeName} (${r.points}点)`);
        });
    }

    if (failCount > 0) {
      console.log('\n❌ 失敗したルート:');
      results
        .filter(r => !r.success)
        .forEach((r, i) => {
          console.log(`  ${i + 1}. ${routes[i].name}: ${r.reason}`);
        });
    }

    // 全SQLを1つのファイルに保存
    if (sqlStatements.length > 0) {
      const sqlFile = `${__dirname}/update_all_routes.sql`;
      const sqlContent = sqlStatements.join('\n\n');
      fs.writeFileSync(sqlFile, sqlContent);
      console.log(`\n💾 全UPDATE SQLを保存: ${sqlFile}`);
      console.log('\n📝 Supabase Studioで実行してください:');
      console.log(`  1. ${sqlFile} を開く`);
      console.log(`  2. 内容をコピー`);
      console.log(`  3. Supabase Studio SQL Editorに貼り付けて実行`);
    }

  } catch (error) {
    console.error('❌ エラー:', error.message);
    process.exit(1);
  }
}

// 実行
main();
