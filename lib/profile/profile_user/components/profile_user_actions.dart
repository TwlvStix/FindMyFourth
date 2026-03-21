import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/users_record.dart';
import '/core/content/report_copy.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/motion/motion_helpers.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/navigation/transition_standards.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/profile/profile_user/components/mutual_friends_sheet.dart';
import '/profile/profile_user/components/report_user_bottom_sheet.dart';
import '/providers/block_provider.dart';
import '/providers/chat_provider.dart';

class ProfileUserActions {
  const ProfileUserActions._();

  static Future<void> openChatWithUser(
    BuildContext context,
    DocumentReference userRef,
  ) async {
    final currentUserRef = currentUserReference;
    if (currentUserRef == null) return;

    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserRef.id,
            otherUid: userRef.id,
          );
      if (!context.mounted) return;
      context.pushChatDetails(chatId: chatRef.id);
    } catch (error, stackTrace) {
      if (!context.mounted) return;
      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat. Please try again.'),
        ),
      );
    }
  }

  static void showReportSheet(
    BuildContext context, {
    required String reportedUid,
    required String displayName,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      enableDrag: true,
      builder: (_) => ReportUserBottomSheet(
        reportedUid: reportedUid,
        reportedDisplayName: displayName,
      ),
    );
  }

  static Future<void> handleBlock(
    BuildContext context, {
    required DocumentReference userRef,
    required String displayName,
  }) async {
    final shouldBlock = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.destructive,
      icon: AppPhosphorIcons.blocked,
      title: ReportBlockCopy.blockTitle(displayName),
      body: ReportBlockCopy.blockBody,
      actionLabel: ReportBlockCopy.blockAction,
    );

    if (shouldBlock != true) return;
    if (!context.mounted) return;

    final currentUid = currentUserReference?.id;
    if (currentUid == null) return;

    try {
      await context.read<BlockProvider>().blockUser(
            currentUid: currentUid,
            blockedUid: userRef.id,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReportBlockCopy.userBlocked)),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReportBlockCopy.blockFailed)),
      );
    }
  }

  static void showMutualFriendsSheet(
    BuildContext context, {
    required List<UsersRecord> mutualFriends,
  }) {
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      enableDrag: true,
      builder: (sheetContext) => MutualFriendsSheet(
        mutualFriends: mutualFriends,
        onFriendTap: (friend) {
          Navigator.of(sheetContext).pop();
          context.pushProfileUser(
            userRef: friend.reference,
            transition: TransitionStandards.noTransition,
          );
        },
      ),
    );
  }
}
