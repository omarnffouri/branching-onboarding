import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Our own palette: dusty rose on a blush-white canvas. Pink, like the
/// brand name, but kept soft and premium rather than loud. Every colour in
/// the app comes from here, so a re-theme is a one-file change.
abstract final class AppColors {
  static const background = Color(0xFFFFF7F7);
  static const surface = Color(0xFFFFFFFF);
  static const blush = Color(0xFFFBE8EC);
  static const primary = Color(0xFFA3445F);
  static const primaryPressed = Color(0xFF8A3650);
  static const primaryDeep = Color(0xFF6E2840);
  static const primarySoft = Color(0xFFD7A6B3);
  static const ink = Color(0xFF2A1B21);
  static const inkMuted = Color(0xFF7E6A71);
  static const border = Color(0xFFF1E1E5);
  static const track = Color(0xFFF3E3E7);
  static const success = Color(0xFF2E9161);
  static const error = Color(0xFFB8322A);

  /// The drifting shapes of the flow background.
  static const flowRose = Color(0xFFF4C7D3);
  static const flowPeach = Color(0xFFF9D9C9);
  static const flowLilac = Color(0xFFE9D3EC);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Side gutter of every screen.
  static const page = 24.0;
}

abstract final class AppRadii {
  static const card = 18.0;
  static const button = 16.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0D2B201E), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x1A2B201E), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

/// One motion vocabulary for the whole flow. Calm, never bouncy: this is a
/// Pilates brand, not a game.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 480);

  /// How long a single-choice selection stays on screen before moving on,
  /// long enough to see it land, short enough not to feel slow.
  static const selectionBeat = Duration(milliseconds: 380);

  static const Curve standard = Curves.easeOutCubic;
  static const emphasized = Cubic(0.2, 0, 0, 1);
}
