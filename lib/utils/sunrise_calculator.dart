import 'dart:math' as math;

/// 日の出時刻計算ユーティリティ（B2 §5.2）。
///
/// MVP は **東京固定**（緯度 35.6762 / 経度 139.6503）。
/// 公開後にユーザー位置別へ拡張する想定（B2 §8.4 公開後改善候補 #2）。
///
/// アルゴリズムは NOAA Solar Calculator（簡易版）。誤差は許容範囲 ±1 分以内。
/// ホーム画面の「ベストタイム 5:42〜6:12」表示に使われる用途のため、秒精度は不要。
///
/// 通知の auto モードでは「日の出 30 分前」を推奨送信時刻とする
/// （[recommendedSendOffset]）。
class SunriseCalculator {
  SunriseCalculator._();

  /// 東京（皇居前）の緯度・経度。
  static const double tokyoLat = 35.6762;
  static const double tokyoLng = 139.6503;

  /// auto モードでの推奨送信オフセット（日の出からのオフセット）。
  /// 負の値 = 日の出より前。
  static const Duration recommendedSendOffset = Duration(minutes: -30);

  /// JST タイムゾーン（UTC+9）。日本固定。
  static const Duration _jstOffset = Duration(hours: 9);

  /// 指定した日（JST）の日の出時刻（JST、ローカル DateTime として返却）。
  ///
  /// [date] の年月日のみを使う（時刻は無視）。
  static DateTime sunriseFor(DateTime date) {
    final dayOfYear = _dayOfYear(date);
    final hoursUtc = _calcSunEvent(
      dayOfYear: dayOfYear,
      latDeg: tokyoLat,
      lngDeg: tokyoLng,
      year: date.year,
      isSunrise: true,
    );
    return _hoursToLocalDateTime(date, hoursUtc);
  }

  /// 指定した日の日の入り時刻（JST）。ベストタイム終了表示用。
  static DateTime sunsetFor(DateTime date) {
    final dayOfYear = _dayOfYear(date);
    final hoursUtc = _calcSunEvent(
      dayOfYear: dayOfYear,
      latDeg: tokyoLat,
      lngDeg: tokyoLng,
      year: date.year,
      isSunrise: false,
    );
    return _hoursToLocalDateTime(date, hoursUtc);
  }

  /// auto モードの推奨送信時刻（日の出 30 分前）。
  static DateTime recommendedSendAt(DateTime date) =>
      sunriseFor(date).add(recommendedSendOffset);

  /// ベストタイムの「終わり」（日の出 30 分後）を返す。
  /// ホームの「ベストタイム HH:mm〜HH:mm」表示用。
  static DateTime bestTimeEndAt(DateTime date) =>
      sunriseFor(date).add(const Duration(minutes: 30));

  static int _dayOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    return date.difference(firstDay).inDays + 1;
  }

  /// NOAA 簡易版。Almanac for Computers, 1990 に準拠（許容誤差 ±1 分）。
  ///
  /// 戻り値は UTC の時刻（小数時間）。
  static double _calcSunEvent({
    required int dayOfYear,
    required double latDeg,
    required double lngDeg,
    required int year,
    required bool isSunrise,
    double zenithDeg = 90.833,
  }) {
    const degToRad = math.pi / 180.0;
    const radToDeg = 180.0 / math.pi;

    final lngHour = lngDeg / 15.0;
    final t = dayOfYear + ((isSunrise ? 6 : 18) - lngHour) / 24.0;

    final mDeg = (0.9856 * t) - 3.289;
    final mRad = mDeg * degToRad;
    var lDeg = mDeg + (1.916 * math.sin(mRad)) + (0.020 * math.sin(2 * mRad)) + 282.634;
    lDeg = _mod(lDeg, 360.0);
    final lRad = lDeg * degToRad;

    var raDeg = math.atan(0.91764 * math.tan(lRad)) * radToDeg;
    raDeg = _mod(raDeg, 360.0);

    final lQuadrant = (lDeg / 90.0).floor() * 90;
    final raQuadrant = (raDeg / 90.0).floor() * 90;
    raDeg = raDeg + (lQuadrant - raQuadrant);
    final raHour = raDeg / 15.0;

    final sinDec = 0.39782 * math.sin(lRad);
    final cosDec = math.cos(math.asin(sinDec));

    final cosH = (math.cos(zenithDeg * degToRad) - (sinDec * math.sin(latDeg * degToRad))) /
        (cosDec * math.cos(latDeg * degToRad));
    if (cosH > 1.0 || cosH < -1.0) {
      return double.nan;
    }

    final hRad = isSunrise ? (2 * math.pi - math.acos(cosH)) : math.acos(cosH);
    final hHour = (hRad * radToDeg) / 15.0;

    var localTimeHours = hHour + raHour - (0.06571 * t) - 6.622;
    var utHours = localTimeHours - lngHour;
    utHours = _mod(utHours, 24.0);
    return utHours;
  }

  static DateTime _hoursToLocalDateTime(DateTime date, double utHours) {
    if (utHours.isNaN) {
      return DateTime(date.year, date.month, date.day, 6, 0);
    }
    final hour = utHours.floor();
    final minute = ((utHours - hour) * 60).round();
    final utcMidnight = DateTime.utc(date.year, date.month, date.day);
    final utcEvent = utcMidnight.add(Duration(hours: hour, minutes: minute));
    final jst = utcEvent.add(_jstOffset);
    return DateTime(jst.year, jst.month, jst.day, jst.hour, jst.minute);
  }

  static double _mod(double v, double m) {
    final r = v - (v / m).floor() * m;
    return r < 0 ? r + m : r;
  }
}
