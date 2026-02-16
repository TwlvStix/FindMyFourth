import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/services/vibe_match_explanation.dart';
import 'package:find_my_fourth/services/vibe_matcher.dart';
import 'package:find_my_fourth/utils/vibe_archetypes.dart';

/// Data model for the Premium Vibe Page.
///
/// Contains all information needed to render the vibe match analysis page,
/// including match results, profiles, archetypes, and user information.
class PremiumVibePageData {
  const PremiumVibePageData({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.userRef,
    required this.matchResult,
    required this.explanation,
    required this.myProfile,
    required this.theirProfile,
    required this.myArchetype,
    required this.theirArchetype,
  });

  /// The matched user's ID
  final String userId;

  /// The matched user's display name
  final String userName;

  /// The matched user's profile photo URL
  final String userPhotoUrl;

  /// Firestore reference to the matched user
  final DocumentReference userRef;

  /// Complete vibe match scoring result
  final VibeMatchResult matchResult;

  /// Structured explanation of the match with insights
  final MatchExplanation explanation;

  /// Current user's vibe profile
  final VibeProfile myProfile;

  /// Matched user's vibe profile
  final VibeProfile theirProfile;

  /// Current user's archetype classification
  final VibeArchetypeMatch myArchetype;

  /// Matched user's archetype classification
  final VibeArchetypeMatch theirArchetype;
}
