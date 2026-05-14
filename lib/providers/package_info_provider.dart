import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// pubspec.yaml の `version` を Single Source of Truth とするための provider。
/// 設定画面・ヘルプ画面など、アプリ内バージョン表示はすべてこの provider 経由で取得する。
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

/// 「1.1.0 (33)」形式のラベルを返す。未取得中は空文字を返す。
String formatVersionLabel(AsyncValue<PackageInfo> asyncInfo) {
  return asyncInfo.maybeWhen(
    data: (info) => '${info.version} (${info.buildNumber})',
    orElse: () => '',
  );
}
