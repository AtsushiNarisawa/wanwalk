import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// WanWalk デザインシステム - アイコン辞書
///
/// DESIGN_TOKENS.md 7章「アイコン規則」に準拠。
/// Phosphor Icons Regular のみ使用。Material Icons / 塗りつぶし / 肉球は禁止。
///
/// 使用例:
/// ```dart
/// Icon(WanWalkIcons.mapPin, size: WanWalkIcons.sizeMd)
/// ```
class WanWalkIcons {
  WanWalkIcons._();

  // ==================================================
  // サイズ（DESIGN_TOKENS §7）
  // ==================================================
  static const double sizeXs = 14;
  static const double sizeSm = 16;
  static const double sizeMd = 20;
  static const double sizeLg = 24;
  static const double sizeXl = 32;

  // ==================================================
  // 地図・ルート系
  // ==================================================
  static IconData get path => PhosphorIcons.path();
  static IconData get mapPin => PhosphorIcons.mapPin();
  static IconData get mapTrifold => PhosphorIcons.mapTrifold();
  static IconData get pushpin => PhosphorIcons.pushPin();

  // ==================================================
  // 散歩系
  // ==================================================
  static IconData get clock => PhosphorIcons.clock();
  static IconData get ruler => PhosphorIcons.ruler();
  static IconData get mountains => PhosphorIcons.mountains();
  static IconData get chartLineUp => PhosphorIcons.chartLineUp();
  static IconData get personWalk => PhosphorIcons.personSimpleWalk();
  static IconData get flag => PhosphorIcons.flag();

  // ==================================================
  // 犬・ペット
  // ==================================================
  static IconData get dog => PhosphorIcons.dog();

  // ==================================================
  // 施設・カテゴリ（スポット）
  // ==================================================
  static IconData get car => PhosphorIcons.car();
  static IconData get toilet => PhosphorIcons.toilet();
  static IconData get drop => PhosphorIcons.drop();
  static IconData get house => PhosphorIcons.house();
  static IconData get tree => PhosphorIcons.tree();
  static IconData get roadHorizon => PhosphorIcons.roadHorizon();

  // ==================================================
  // 季節
  // ==================================================
  static IconData get leaf => PhosphorIcons.leaf();
  static IconData get sun => PhosphorIcons.sun();
  static IconData get snowflake => PhosphorIcons.snowflake();

  // ==================================================
  // UI 操作
  // ==================================================
  static IconData get bookmarkSimple => PhosphorIcons.bookmarkSimple();
  static IconData get bookmarkSimpleFill => PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill);
  static IconData get shareNetwork => PhosphorIcons.shareNetwork();
  static IconData get camera => PhosphorIcons.camera();
  static IconData get user => PhosphorIcons.user();
  static IconData get magnifyingGlass => PhosphorIcons.magnifyingGlass();
  static IconData get arrowRight => PhosphorIcons.arrowRight();
  static IconData get arrowLeft => PhosphorIcons.arrowLeft();
  static IconData get arrowUpRight => PhosphorIcons.arrowUpRight();
  static IconData get caretDown => PhosphorIcons.caretDown();
  static IconData get caretUp => PhosphorIcons.caretUp();
  static IconData get caretRight => PhosphorIcons.caretRight();
  static IconData get caretLeft => PhosphorIcons.caretLeft();
  static IconData get x => PhosphorIcons.x();
  static IconData get list => PhosphorIcons.list();
  static IconData get calendar => PhosphorIcons.calendarBlank();
  static IconData get star => PhosphorIcons.star();
  static IconData get starFill => PhosphorIcons.star(PhosphorIconsStyle.fill);
  static IconData get heart => PhosphorIcons.heart();
  static IconData get heartFill => PhosphorIcons.heart(PhosphorIconsStyle.fill);
  static IconData get check => PhosphorIcons.check();
  static IconData get checkCircle => PhosphorIcons.checkCircle();
  static IconData get sealCheck => PhosphorIcons.sealCheck();
  static IconData get plus => PhosphorIcons.plus();
  static IconData get gear => PhosphorIcons.gear();
  static IconData get bell => PhosphorIcons.bell();
  static IconData get info => PhosphorIcons.info();
  static IconData get warning => PhosphorIcons.warning();
  static IconData get question => PhosphorIcons.question();
  static IconData get dotsThree => PhosphorIcons.dotsThree();
  static IconData get pencil => PhosphorIcons.pencil();
  static IconData get trash => PhosphorIcons.trash();
  static IconData get image => PhosphorIcons.image();
  static IconData get images => PhosphorIcons.images();

  // ==================================================
  // 散歩メトリクス
  // ==================================================
  static IconData get fire => PhosphorIcons.fire();
  static IconData get trophy => PhosphorIcons.trophy();
  static IconData get footprints => PhosphorIcons.footprints();
  static IconData get timer => PhosphorIcons.timer();

  // ==================================================
  // Auth
  // ==================================================
  static IconData get signOut => PhosphorIcons.signOut();
  static IconData get signIn => PhosphorIcons.signIn();
  static IconData get envelope => PhosphorIcons.envelope();
  static IconData get lock => PhosphorIcons.lock();
  static IconData get eye => PhosphorIcons.eye();
  static IconData get eyeSlash => PhosphorIcons.eyeSlash();
}
