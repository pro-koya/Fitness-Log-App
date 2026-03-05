import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../config/ad_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/entitlement_provider.dart';
import '../../paywall/paywall_service.dart';
import '../../paywall/models/paywall_reason.dart';

/// Free ユーザーのときのみ Banner 広告を表示するウィジェット。
/// 広告の下に「広告を非表示にしますか？」の控えめな Pro 誘導を表示。
/// Pro ユーザーでは何も表示しない。
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadStarted = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  Future<void> _loadAd() async {
    final isPro = ref.read(entitlementProvider).isPro;
    if (isPro || !mounted) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            _retryCount = 0;
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load (attempt ${_retryCount + 1}): $err');
          ad.dispose();
          if (mounted) setState(() => _bannerAd = null);
          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(Duration(seconds: _retryCount * 3), () {
              if (mounted) _loadAd();
            });
          }
        },
      ),
    );
    ad.load();
    if (mounted) setState(() => _bannerAd = ad);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(entitlementProvider).isPro;
    if (isPro) return const SizedBox.shrink();
    if (!_loadStarted) {
      _loadStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
    }
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    final ad = _bannerAd!;
    final l10n = AppLocalizations.of(context);
    final ctaLabel = l10n?.adHideWithProCta ?? 'Hide ads with Pro?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ユーザー操作を損なわない程度の Pro 誘導（広告バナーの上部）
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: TextButton(
            onPressed: () => showPaywall(context, reason: PaywallReason.ads),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              ctaLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ],
    );
  }
}
