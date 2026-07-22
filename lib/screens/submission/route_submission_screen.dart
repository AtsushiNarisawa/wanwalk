import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/submission_constants.dart';
import '../../config/wanwalk_colors.dart';
import '../../config/wanwalk_spacing.dart';
import '../../config/wanwalk_typography.dart';
import '../../providers/analytics_provider.dart';
import '../../services/submission_service.dart';
import '../../utils/route_trim.dart';
import '../../widgets/submission/route_trim_section.dart';
import '../../widgets/wanwalk_button.dart';
import '../../widgets/wanwalk_snackbar.dart';

/// 新しい道の推薦フォーム（type='new_route'）。
///
/// 歩いた散歩(walkId)を起点に、写真3枚・道の名前・おすすめ理由・発着点トリミング・
/// 公開名・同意を集め、EXIF除去のうえ route_submissions へ単一INSERTする。
/// entryPoint は [SubmissionEntryPoint] のいずれか（walk_end / walk_detail）。
class RouteSubmissionScreen extends ConsumerStatefulWidget {
  const RouteSubmissionScreen({
    super.key,
    required this.walkId,
    required this.entryPoint,
  });

  final String walkId;
  final String entryPoint;

  @override
  ConsumerState<RouteSubmissionScreen> createState() =>
      _RouteSubmissionScreenState();
}

class _RouteSubmissionScreenState extends ConsumerState<RouteSubmissionScreen> {
  final ImagePicker _picker = ImagePicker();
  final SubmissionService _service = SubmissionService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _publicNameController = TextEditingController();

  final List<XFile> _photos = [];

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  bool _loading = true;
  bool _tooShort = false;
  String? _loadError;

  EndpointTrimmer? _trimmer;
  TrimOutput? _trim;

  bool _agreed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openUrl(SubmissionConstants.termsUrl);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _openUrl(SubmissionConstants.privacyUrl);
    _init();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    _publicNameController.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final supabase = Supabase.instance.client;
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _loadError = '投稿にはログインが必要です。';
        return;
      }

      // 歩いた軌跡（本人のwalk・RLSで読める）
      final walkRow = await supabase
          .from('walks')
          .select('path_geojson')
          .eq('id', widget.walkId)
          .maybeSingle();
      final geoRaw = walkRow?['path_geojson'];
      final geo = geoRaw is Map ? Map<String, dynamic>.from(geoRaw) : null;
      final points = decodeLineString(geo);

      if (points.length < 2) {
        _tooShort = true;
      } else {
        final trimmer = EndpointTrimmer(points);
        if (!trimmer.isTrimmable) {
          _tooShort = true;
        } else {
          _trimmer = trimmer;
        }
      }

      // 公開名の初期値（display_name）
      final prof = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      final dn = (prof?['display_name'] as String?)?.trim();
      if (dn != null && dn.isNotEmpty) {
        _publicNameController.text = dn;
      }

      if (!_tooShort) {
        unawaited(ref.read(analyticsServiceProvider).logSubmitStart(
              entryPoint: widget.entryPoint,
              submissionType: SubmissionType.newRoute,
              theme: SubmissionConstants.activeTheme,
            ));
      }
    } catch (_) {
      _loadError = '読み込みに失敗しました。通信環境をご確認ください。';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _canSubmit =>
      !_loading &&
      !_tooShort &&
      _loadError == null &&
      _photos.length == SubmissionConstants.requiredPhotoCount &&
      _nameController.text.trim().isNotEmpty &&
      _reasonController.text.trim().isNotEmpty &&
      _publicNameController.text.trim().isNotEmpty &&
      (_trim?.valid ?? false) &&
      _agreed &&
      !_submitting;

  void _showPhotoChoice() {
    if (_photos.length >= SubmissionConstants.requiredPhotoCount) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(ctx);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (images.isEmpty) return;
      final remaining =
          SubmissionConstants.requiredPhotoCount - _photos.length;
      if (remaining <= 0) return;
      setState(() {
        _photos.addAll(images.take(remaining));
      });
      if (images.length > remaining && mounted) {
        showWanWalkSnackBar(
          context,
          '写真は${SubmissionConstants.requiredPhotoCount}枚までです',
          type: WanWalkSnackBarType.warning,
        );
      }
    } catch (e) {
      if (mounted) {
        showWanWalkSnackBar(context, '写真の選択に失敗しました',
            type: WanWalkSnackBarType.error);
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;
      if (_photos.length >= SubmissionConstants.requiredPhotoCount) return;
      setState(() => _photos.add(image));
    } catch (e) {
      if (mounted) {
        showWanWalkSnackBar(context, '撮影に失敗しました',
            type: WanWalkSnackBarType.error);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final trim = _trim;
    if (userId == null || trim == null || !trim.valid) return;

    setState(() => _submitting = true);
    try {
      await _service.createNewRouteSubmission(
        userId: userId,
        walkId: widget.walkId,
        proposedName: _nameController.text.trim(),
        reason: _reasonController.text.trim(),
        photoFilePaths: _photos.map((x) => x.path).toList(),
        publicName: _publicNameController.text.trim(),
        trimmedPath: trim.geojson,
        trimmedStartIdx: trim.startIdx,
        trimmedEndIdx: trim.endIdx,
        distanceMeters: trim.distanceMeters,
        entryPoint: widget.entryPoint,
      );

      unawaited(ref.read(analyticsServiceProvider).logSubmitComplete(
            entryPoint: widget.entryPoint,
            submissionType: SubmissionType.newRoute,
            theme: SubmissionConstants.activeTheme,
          ));

      if (!mounted) return;
      await _showThanksDialog();
      if (mounted) Navigator.of(context).pop(true);
    } on SubmissionException catch (e) {
      if (mounted) {
        showWanWalkSnackBar(context, e.message,
            type: WanWalkSnackBarType.error);
      }
    } catch (_) {
      if (mounted) {
        showWanWalkSnackBar(context, '投稿に失敗しました。もう一度お試しください。',
            type: WanWalkSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showThanksDialog() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ありがとうございます'),
        content: const Text(
          '愛犬と歩いた道を受け取りました。編集部が確認し、掲載できるかを2週間以内にお知らせします。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('愛犬と歩いた道を推薦')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _buildNotice(_loadError!);
    }
    if (_tooShort) {
      return _buildNotice(
        'この散歩は短いため、推薦にはご利用いただけません。もう少し長く歩いた道でお試しください。',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WanWalkSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '愛犬と歩いた道が、編集部の確認を経て、次の誰かの道になります。',
              style: WanWalkTypography.bodyMedium.copyWith(
                color: isDark
                    ? WanWalkColors.textSecondaryDark
                    : WanWalkColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // 写真（3枚）
            _sectionLabel('写真（${SubmissionConstants.requiredPhotoCount}枚）'),
            _sectionHint('道の雰囲気が伝わる写真を選んでください。'),
            const SizedBox(height: WanWalkSpacing.sm),
            _buildPhotoRow(),
            const SizedBox(height: WanWalkSpacing.lg),

            // 道の名前
            _sectionLabel('道の名前'),
            const SizedBox(height: WanWalkSpacing.sm),
            _buildTextField(
              controller: _nameController,
              hint: '例: 銀杏並木の朝さんぽ道',
              maxLength: 40,
            ),
            const SizedBox(height: WanWalkSpacing.md),

            // おすすめの理由
            _sectionLabel('おすすめの理由'),
            const SizedBox(height: WanWalkSpacing.sm),
            _buildTextField(
              controller: _reasonController,
              hint: 'どんなところが愛犬とのお散歩にいいか、教えてください。',
              maxLength: 500,
              maxLines: 4,
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // 発着点トリミング
            _sectionLabel('発着点をぼかす'),
            const SizedBox(height: WanWalkSpacing.sm),
            RouteTrimSection(
              trimmer: _trimmer!,
              onChanged: (out) => setState(() => _trim = out),
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // 公開名
            _sectionLabel('掲載時のお名前（公開名）'),
            _sectionHint('ニックネームで構いません。'),
            const SizedBox(height: WanWalkSpacing.sm),
            _buildTextField(
              controller: _publicNameController,
              hint: '例: こむぎのおさんぽ',
              maxLength: 30,
            ),
            const SizedBox(height: WanWalkSpacing.lg),

            // 同意
            _buildConsent(isDark),
            const SizedBox(height: WanWalkSpacing.lg),

            WanWalkButton(
              text: '推薦する',
              fullWidth: true,
              size: WanWalkButtonSize.large,
              loading: _submitting,
              onPressed: _canSubmit ? _submit : null,
            ),
            const SizedBox(height: WanWalkSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WanWalkSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: WanWalkTypography.bodyMedium,
            ),
            const SizedBox(height: WanWalkSpacing.lg),
            WanWalkButton(
              text: '戻る',
              variant: WanWalkButtonVariant.outlined,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoRow() {
    final slots = <Widget>[];
    for (var i = 0; i < _photos.length; i++) {
      slots.add(_photoThumb(i));
    }
    if (_photos.length < SubmissionConstants.requiredPhotoCount) {
      slots.add(_addPhotoTile());
    }
    return Row(
      children: [
        for (final s in slots) ...[
          s,
          const SizedBox(width: WanWalkSpacing.sm),
        ],
      ],
    );
  }

  Widget _photoThumb(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_photos[index].path),
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addPhotoTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _showPhotoChoice,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: isDark
              ? WanWalkColors.cardDark
              : WanWalkColors.accentPrimarySoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: WanWalkColors.accentPrimary.withValues(alpha: 0.4),
          ),
        ),
        child: const Icon(Icons.add_a_photo,
            color: WanWalkColors.accentPrimary),
      ),
    );
  }

  Widget _buildConsent(bool isDark) {
    final textColor = isDark
        ? WanWalkColors.textSecondaryDark
        : WanWalkColors.textSecondaryLight;
    final linkStyle = WanWalkTypography.bodySmall.copyWith(
      color: WanWalkColors.accentPrimary,
      decoration: TextDecoration.underline,
    );
    final baseStyle = WanWalkTypography.bodySmall.copyWith(color: textColor);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Checkbox(
            value: _agreed,
            activeColor: WanWalkColors.accentPrimary,
            onChanged: (v) => setState(() => _agreed = v ?? false),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: baseStyle,
                children: [
                  const TextSpan(text: '私は18歳以上であり、'),
                  TextSpan(
                    text: '利用規約',
                    style: linkStyle,
                    recognizer: _termsTap,
                  ),
                  const TextSpan(text: '（投稿プログラムに関する条項を含みます）および'),
                  TextSpan(
                    text: 'プライバシーポリシー',
                    style: linkStyle,
                    recognizer: _privacyTap,
                  ),
                  const TextSpan(
                    text:
                        'に同意します。投稿した写真・GPS軌跡・紹介文を、WanWalk編集部が確認・編集のうえ本サービス等に掲載することに同意します。',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: WanWalkTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark
            ? WanWalkColors.textPrimaryDark
            : WanWalkColors.textPrimaryLight,
      ),
    );
  }

  Widget _sectionHint(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: WanWalkTypography.bodySmall.copyWith(
          color: isDark
              ? WanWalkColors.textSecondaryDark
              : WanWalkColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: (isDark
                  ? WanWalkColors.textSecondaryDark
                  : WanWalkColors.textSecondaryLight)
              .withValues(alpha: 0.5),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WanWalkColors.accentPrimary),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
      style: WanWalkTypography.bodyMedium.copyWith(
        color: isDark
            ? WanWalkColors.textPrimaryDark
            : WanWalkColors.textPrimaryLight,
      ),
    );
  }
}
