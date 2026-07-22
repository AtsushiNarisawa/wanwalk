import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/submission_constants.dart';
import '../utils/image_exif.dart';
import '../utils/logger.dart';

/// ユーザーに提示するメッセージ付きの投稿エラー。
class SubmissionException implements Exception {
  SubmissionException(this.message);
  final String message;
  @override
  String toString() => 'SubmissionException: $message';
}

/// 投稿プログラム v1: route_submissions への書き込み＋写真アップロード（EXIF除去）。
///
/// RLS: INSERT=本人(auth.uid()=user_id)・UPDATE=is_admin限定。
/// → 投稿者は自分の行を後から更新できないため、写真アップロード→単一INSERTで
///   id・photo_paths を同時に確定する（クライアントでUUIDを先に発番）。
class SubmissionService {
  SubmissionService([SupabaseClient? client])
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  static const String _bucket = 'submission-photos';

  /// 新しい道の推薦（type='new_route'）。
  /// 写真は必須（[SubmissionConstants.requiredPhotoCount] 枚）。
  /// 戻り値＝作成した route_submissions.id。
  Future<String> createNewRouteSubmission({
    required String userId,
    required String walkId,
    required String proposedName,
    required String reason,
    required List<String> photoFilePaths,
    required String publicName,
    required Map<String, dynamic> trimmedPath,
    required int trimmedStartIdx,
    required int trimmedEndIdx,
    required double distanceMeters,
    required String entryPoint,
    String theme = SubmissionConstants.activeTheme,
  }) async {
    final submissionId = _uuid.v4();
    final photoPaths = await _uploadPhotos(
      filePaths: photoFilePaths,
      userId: userId,
      submissionId: submissionId,
    );

    final row = <String, dynamic>{
      'id': submissionId,
      'user_id': userId,
      'walk_id': walkId,
      'type': SubmissionType.newRoute,
      'proposed_name': proposedName,
      'reason': reason,
      'public_name': publicName,
      'photo_paths': photoPaths,
      'trimmed_path': trimmedPath,
      'trimmed_start_idx': trimmedStartIdx,
      'trimmed_end_idx': trimmedEndIdx,
      'distance_meters': distanceMeters,
      'theme': theme,
      'entry_point': entryPoint,
      'age_confirmed': true,
      'terms_version': SubmissionConstants.termsVersion,
    };

    return _insert(row, context: 'new_route');
  }

  /// 既存公式ルートへの実走報告（type='field_report'）。写真は任意。
  Future<String> createFieldReport({
    required String userId,
    required String targetRouteId,
    required String reason,
    required String publicName,
    String? walkId,
    List<String> photoFilePaths = const [],
    String? entryPoint,
    String theme = SubmissionConstants.activeTheme,
  }) async {
    final submissionId = _uuid.v4();
    final photoPaths = photoFilePaths.isEmpty
        ? const <String>[]
        : await _uploadPhotos(
            filePaths: photoFilePaths,
            userId: userId,
            submissionId: submissionId,
          );

    final row = <String, dynamic>{
      'id': submissionId,
      'user_id': userId,
      if (walkId != null) 'walk_id': walkId,
      'type': SubmissionType.fieldReport,
      'target_route_id': targetRouteId,
      'reason': reason,
      'public_name': publicName,
      'photo_paths': photoPaths,
      'theme': theme,
      if (entryPoint != null) 'entry_point': entryPoint,
      'age_confirmed': true,
      'terms_version': SubmissionConstants.termsVersion,
    };

    return _insert(row, context: 'field_report');
  }

  Future<String> _insert(Map<String, dynamic> row,
      {required String context}) async {
    try {
      final res = await _supabase
          .from('route_submissions')
          .insert(row)
          .select('id')
          .single();
      return res['id'] as String;
    } catch (e) {
      if (kDebugMode) {
        appLog('❌ route_submissions insert 失敗($context): $e');
      }
      throw SubmissionException(
          '投稿の保存に失敗しました。通信環境をご確認のうえ、もう一度お試しください。');
    }
  }

  /// 写真からEXIF（位置情報）を除去して submission-photos(private) へアップロード。
  /// 返り値＝ストレージ上のオブジェクトパス（public URLではない・privateバケット）。
  /// いずれか1枚でも処理・アップロードに失敗したら [SubmissionException] を投げる
  /// （位置情報付きの生バイトは絶対にアップロードしない・部分投稿も作らない）。
  Future<List<String>> _uploadPhotos({
    required List<String> filePaths,
    required String userId,
    required String submissionId,
  }) async {
    final paths = <String>[];
    for (var i = 0; i < filePaths.length; i++) {
      final file = File(filePaths[i]);
      if (!await file.exists()) {
        throw SubmissionException('写真が見つかりませんでした。もう一度選び直してください。');
      }
      final raw = await file.readAsBytes();
      // decode→向き焼き込み→EXIF破棄→再encode（重いのでUIアイソレート外で実行）
      final cleaned = await compute(stripExifFromImage, raw);
      if (cleaned.isEmpty) {
        throw SubmissionException('写真の処理に失敗しました。別の写真でお試しください。');
      }
      final objectPath = '$userId/$submissionId/$i.jpg';
      try {
        await _supabase.storage.from(_bucket).uploadBinary(
              objectPath,
              cleaned,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );
      } catch (e) {
        if (kDebugMode) {
          appLog('❌ submission-photos アップロード失敗: $e');
        }
        throw SubmissionException(
            '写真のアップロードに失敗しました。通信環境をご確認のうえ、もう一度お試しください。');
      }
      paths.add(objectPath);
    }
    return paths;
  }
}
