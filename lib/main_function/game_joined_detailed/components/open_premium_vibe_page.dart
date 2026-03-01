import 'package:flutter/material.dart';

import '/services/vibe_group_matcher.dart';
import '/services/vibe_match_explanation.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';
import '/utils/app_util.dart';
import '/utils/vibe_archetypes.dart';
import '/vibe/premium_vibe_page/premium_vibe_page_data.dart';

Future<void> openPremiumVibePage({
  required BuildContext context,
  required VibeRepository vibeRepository,
  required DocumentReference userRef,
  required String userName,
  required String userPhotoUrl,
  required GroupVibeMemberResult? memberMatch,
}) async {
  if (memberMatch == null) {
    return;
  }

  try {
    final myVibes = await vibeRepository.getMyVibesCached();
    final theirVibes = memberMatch.member.profile;

    final result = VibeMatcher.score(myVibes, theirVibes);
    final explanation = buildMatchExplanation(
      matchResult: result,
      a: myVibes,
      b: theirVibes,
    );

    final pageData = PremiumVibePageData(
      userId: userRef.id,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      userRef: userRef,
      matchResult: result,
      explanation: explanation,
      myProfile: myVibes,
      theirProfile: theirVibes,
      myArchetype: VibeArchetypes.classifyProfile(myVibes),
      theirArchetype: VibeArchetypes.classifyProfile(theirVibes),
    );

    if (!context.mounted) {
      return;
    }

    context.pushPremiumVibePage(
      userId: userRef.id,
      data: pageData,
    );
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to load vibe match. Please try again.'),
      ),
    );
  }
}
