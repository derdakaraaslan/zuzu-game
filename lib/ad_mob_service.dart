import 'dart:core';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/6300978111";
    }

    return null;
  }

  static String? get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/1033173712";
    }

    return null;
  }

  static String? get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/5224354917";
    }

    return null;
  }

  static final BannerAdListener bannerAdListener = BannerAdListener();
}
