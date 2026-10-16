import 'package:flutter/painting.dart';

/// Every image and video the app ships, in one place, so a path is never
/// typed twice and a renamed file is a one-line change.
abstract final class AppAssets {
  static const welcome = AssetImage('assets/images/welcome.jpg');
  static const plan = AssetImage('assets/images/plan.jpg');
  static const paywall = AssetImage('assets/images/paywall.jpg');
  static const success = AssetImage('assets/images/success.jpg');

  static const welcomeVideo = 'assets/video/welcome.mp4';

  /// Fixed screen images, decoded up front so none pops in late.
  static const List<AssetImage> screenImages = [
    welcome,
    plan,
    paywall,
    success,
  ];

  /// Photos named per step in the config (`"image": "goal.jpg"`). Decoded at
  /// display width rather than full resolution, to save memory.
  static ImageProvider step(String fileName) => ResizeImage(
    AssetImage('assets/images/steps/$fileName'),
    width: _stepDecodeWidth,
  );

  static const _stepDecodeWidth = 1080;
}
