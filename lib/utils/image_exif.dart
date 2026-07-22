import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// EXIF（GPS位置情報を含む全メタデータ）を除去したJPEGバイト列を返す。
///
/// 仕組み:
/// 1. デコード（この時点で decoded.exif にGPS等が読み込まれる）
/// 2. 撮影時の向き(Orientation)をピクセルへ焼き込む（この後EXIFを消すため）
/// 3. EXIFを空の [img.ExifData] に置換して全メタデータを破棄
/// 4. JPEG再エンコード
///
/// なぜ「空に置換」が必須か:
/// image パッケージの JpegEncoder は `image.exif` が空でない限り APP1(EXIF)
/// セグメントを書き戻す（jpeg_encoder.dart `_writeAPP1` / `if (exif.isEmpty) return;`）。
/// 単純な decode→encode ではGPSが再埋め込みされてしまうため、encode前に必ずEXIFを空にする。
///
/// [compute] でUIアイソレート外実行するためのトップレベル関数。
///
/// デコード失敗時は空の [Uint8List] を返す。呼び出し側はこれを「処理失敗」とみなし
/// 当該写真を却下すること（生バイト＝位置情報付きを絶対にアップロードしない）。
Uint8List stripExifFromImage(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    return Uint8List(0);
  }
  // 撮影時の向きをピクセルへ焼き込み（EXIF Orientation を消しても正しく表示されるように）
  final baked = img.bakeOrientation(decoded);
  // GPSを含む全EXIFを破棄（空なら JpegEncoder は APP1 を書かない）
  baked.exif = img.ExifData();
  // maxWidth/Height 1920・quality 85 は image_picker 側で適用済み。ここでは再圧縮のみ。
  return img.encodeJpg(baked, quality: 85);
}
