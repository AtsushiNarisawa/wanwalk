import 'package:flutter/foundation.dart';

/// アプリ共通のデバッグログ関数
/// kDebugModeチェックにより、リリースビルドではログが出力されない
void appLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}
