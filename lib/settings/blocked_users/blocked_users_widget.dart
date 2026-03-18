import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/users_record.dart';
import '/core/content/report_copy.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_avatar.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_empty_state.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/providers/block_provider.dart';
import '/providers/profile_provider.dart';

class BlockedUsersWidget extends StatefulWidget {
  const BlockedUsersWidget({super.key});

  static const String routeName = 'BlockedUsers';
  static const String routePath = '/blockedUsers';

  @override
  State<BlockedUsersWidget> createState() => _BlockedUsersWidgetState();
}

class _BlockedUsersWidgetState extends State<BlockedUsersWidget> {
  bool _profilesWarmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _warmProfiles();
  }

  void _warmProfiles() {
    if (_profilesWarmed) return;
    _profilesWarmed = true;

    final blockedIds = context.read<BlockProvider>().blockedUserIds;
    if (blockedIds.isNotEmpty) {
      context.read<ProfileProvider>().warmProfiles(blockedIds);
    }
  }

  Future<void> _handleUnblock(String blockedUid) async {
    final currentUid = currentUserUid;
    if (currentUid.isEmpty) return;

    try {
      await context.read<BlockProvider>().unblockUser(
            currentUid: currentUid,
            blockedUid: blockedUid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReportBlockCopy.userUnblocked)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReportBlockCopy.unblockFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedIds =
        context.select<BlockProvider, Set<String>>((p) => p.blockedUserIds);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        leading: PremiumBackButton(
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          ReportBlockCopy.blockedUsersTitle,
          style: AppTypography.headlineMediumSans.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          top: false,
          child: blockedIds.isEmpty
              ? Center(
                  child: AppEmptyState(
                    icon: AppPhosphorIcons.blocked,
                    title: ReportBlockCopy.noBlockedUsersTitle,
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 80,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.xxl,
                  ),
                  itemCount: blockedIds.length,
                  itemBuilder: (context, index) {
                    final uid = blockedIds.elementAt(index);
                    return _BlockedUserTile(
                      uid: uid,
                      onUnblock: () => _handleUnblock(uid),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.uid,
    required this.onUnblock,
  });

  final String uid;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final profile = context.select<ProfileProvider, UsersRecord?>(
      (p) => p.getCachedProfile(uid),
    );

    final displayName = (profile?.displayName ?? '').isNotEmpty
        ? profile!.displayName
        : 'Golfer';
    final photoUrl = profile?.photoUrl ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.navyLight),
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: photoUrl,
            initials: displayName.isNotEmpty ? displayName[0] : '?',
            size: AppAvatarSize.medium,
            backgroundColor: AppColors.navyLight,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              displayName,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          AppButtonEnhanced(
            text: ReportBlockCopy.unblock,
            variant: AppButtonVariant.ghostDark,
            size: AppButtonSize.small,
            onPressed: onUnblock,
          ),
        ],
      ),
    );
  }
}
