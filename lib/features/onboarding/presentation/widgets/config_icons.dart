import 'package:flutter/material.dart';

/// Icon names the config may use. Kept as a whitelist so a typo in the JSON
/// is caught by a test instead of rendering a blank square.
const configIcons = <String, IconData>{
  'shield': Icons.health_and_safety_outlined,
  'heart': Icons.favorite_border_rounded,
  'leaf': Icons.spa_outlined,
  'calendar': Icons.calendar_today_rounded,
  'timer': Icons.timer_outlined,
  'intensity': Icons.equalizer_rounded,
  'bolt': Icons.bolt_rounded,
  'refresh': Icons.autorenew_rounded,
  'target': Icons.adjust_rounded,
  'drop': Icons.water_drop_outlined,
  'tape': Icons.straighten_rounded,
  'wave': Icons.waves_rounded,
  'hand': Icons.back_hand_outlined,
  'doctor': Icons.medical_services_outlined,
  'breath': Icons.air_rounded,
  'foundation': Icons.self_improvement_rounded,
};

IconData iconFor(String? name) =>
    configIcons[name] ?? Icons.auto_awesome_outlined;
