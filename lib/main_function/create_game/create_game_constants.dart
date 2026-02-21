import 'package:flutter/material.dart';
import '/core/design_tokens/app_icons.dart';

final List<Map<String, dynamic>> kCreateGamePrimaryFormatOptions = [
  {
    'value': 'Stroke Play',
    'label': 'Stroke Play',
    'icon': Icons.format_list_numbered_rounded,
    'svgPath': AppIcons.strokePlay,
  },
  {
    'value': 'Match Play',
    'label': 'Match Play',
    'icon': Icons.sports_golf_rounded,
    'svgPath': AppIcons.matchPlay,
  },
  {
    'value': 'Stableford',
    'label': 'Stableford',
    'icon': Icons.star_rounded,
    'svgPath': AppIcons.stableford,
  },
];

final List<Map<String, dynamic>> kCreateGameVibeOptions = [
  {
    'value': 'Competitive',
    'label': 'Competitive',
    'icon': Icons.emoji_events_rounded,
    'svgPath': AppIcons.competitive,
    'subtitle': 'Rules-focused • pace matters',
  },
  {
    'value': 'Casual',
    'label': 'Casual',
    'icon': Icons.sentiment_satisfied_rounded,
    'svgPath': AppIcons.casual,
    'subtitle': 'Relaxed rules • good vibes',
  },
];

final List<Map<String, dynamic>> kCreateGameStakesOptions = [
  {
    'value': 'No Money',
    'label': 'No Money',
    'icon': Icons.handshake_rounded,
    'svgPath': AppIcons.noMoney,
  },
  {
    'value': 'Low Stakes',
    'label': 'Low Stakes',
    'icon': Icons.attach_money_rounded,
    'svgPath': AppIcons.lowStakes,
  },
  {
    'value': 'High Stakes',
    'label': 'High Stakes',
    'icon': Icons.monetization_on_rounded,
    'svgPath': AppIcons.highStakes,
  },
];

final List<Map<String, dynamic>> kCreateGameHandicapOptions = [
  {
    'value': 'Gross',
    'label': 'Gross',
    'icon': Icons.sports_golf_rounded,
    'svgPath': AppIcons.scoring,
  },
  {
    'value': 'Net',
    'label': 'Net',
    'icon': Icons.calculate_rounded,
    'svgPath': AppIcons.handicap,
  },
  {
    'value': 'Both',
    'label': 'Gross + Net',
    'icon': Icons.compare_arrows_rounded,
    'svgPath': AppIcons.handicap, // TODO: May need a combined icon
  },
];
