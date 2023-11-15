import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {

  static String realAdIDBanner = 'ca-app-pub-4595438297105102/8443132653';
  static String testAdIDBanner = 'ca-app-pub-4595438297105102/4312315955';
  static String realAdIDInterstitial = 'ca-app-pub-4595438297105102/6882777620';
  static String testAdIDInterstitial = 'ca-app-pub-3940256099942544/1033173712';


  static String? get bannerAdUnitId {
    if(Platform.isAndroid) {
      return testAdIDBanner;
    } else if(Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return null;
  }

  static final BannerAdListener bannerAdListener = BannerAdListener(
    onAdLoaded: (ad) => debugPrint('Ad loaded'),
    onAdFailedToLoad: (ad, err) {
      ad.dispose();
      debugPrint('Ad failed to load: $err');
    },
    onAdOpened: (ad) => debugPrint('Ad opened'),
    onAdClosed: (ad) => debugPrint('Ad closed'),
  );


  static String? get interstitialAdUnitId {
    if(Platform.isAndroid) {
      return realAdIDInterstitial;
    } else if (Platform.isIOS) {
      //TODO iosadid
      return '';
    }
    return null;
  }



}