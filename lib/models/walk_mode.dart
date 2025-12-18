/// 散歩モードの列挙型
/// - daily: 日常の散歩（プライベート記録）
/// - outing: おでかけ散歩（公式ルートベース、コミュニティ参加）
enum WalkMode {
  daily('daily', '日常の散歩', 'いつものルートを記録'),
  outing('outing', 'おでかけ散歩', '公式ルートを歩いて体験を共有');

  const WalkMode(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  /// 文字列からWalkModeを取得
  static WalkMode fromString(String value) {
    switch (value) {
      case 'daily':
        return WalkMode.daily;
      case 'outing':
        return WalkMode.outing;
      default:
        return WalkMode.daily;
    }
  }

  /// デフォルトモードはdaily
  static WalkMode get defaultMode => WalkMode.daily;

  bool get isDaily => this == WalkMode.daily;
  bool get isOuting => this == WalkMode.outing;
}
