import 'package:flutter/material.dart';
import '/core/design_tokens/app_phosphor_icons.dart';

final List<Map<String, dynamic>> kCreateGamePrimaryFormatOptions = [
  {
    'value': 'Stroke Play',
    'label': 'Stroke Play',
    'icon': Icons.format_list_numbered_rounded,
    'phosphorIcon': AppPhosphorIcons.strokePlay,
  },
  {
    'value': 'Match Play',
    'label': 'Match Play',
    'icon': Icons.sports_golf_rounded,
    'phosphorIcon': AppPhosphorIcons.matchPlay,
  },
  {
    'value': 'Stableford',
    'label': 'Stableford',
    'icon': Icons.star_rounded,
    'phosphorIcon': AppPhosphorIcons.stableford,
  },
];

final List<Map<String, dynamic>> kCreateGameVibeOptions = [
  {
    'value': 'Competitive',
    'label': 'Competitive',
    'icon': Icons.emoji_events_rounded,
    'phosphorIcon': AppPhosphorIcons.competitive,
    'subtitle': 'Rules-focused • pace matters',
  },
  {
    'value': 'Casual',
    'label': 'Casual',
    'icon': Icons.sentiment_satisfied_rounded,
    'phosphorIcon': AppPhosphorIcons.casual,
    'subtitle': 'Relaxed rules • good vibes',
  },
];

final List<Map<String, dynamic>> kCreateGameStakesOptions = [
  {
    'value': 'No Money',
    'label': 'No Money',
    'icon': Icons.handshake_rounded,
    'phosphorIcon': AppPhosphorIcons.noMoney,
  },
  {
    'value': 'Low Stakes',
    'label': 'Low Stakes',
    'icon': Icons.attach_money_rounded,
    'phosphorIcon': AppPhosphorIcons.lowStakes,
  },
  {
    'value': 'High Stakes',
    'label': 'High Stakes',
    'icon': Icons.monetization_on_rounded,
    'phosphorIcon': AppPhosphorIcons.highStakes,
  },
];

final List<Map<String, dynamic>> kCreateGameHandicapOptions = [
  {
    'value': 'Gross',
    'label': 'Gross',
    'icon': Icons.sports_golf_rounded,
    'phosphorIcon': AppPhosphorIcons.scoring,
  },
  {
    'value': 'Net',
    'label': 'Net',
    'icon': Icons.calculate_rounded,
    'phosphorIcon': AppPhosphorIcons.handicap,
  },
  {
    'value': 'Both',
    'label': 'Gross + Net',
    'icon': Icons.compare_arrows_rounded,
    'phosphorIcon': AppPhosphorIcons.handicap,
  },
];
