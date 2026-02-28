import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/widgets/collapsed_join_request_row.dart';
import '/core/widgets/premium_section_header.dart';
import '/core/widgets/vibe_join_request_card.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/providers/profile_provider.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';

/// Displays pending join requests for game owners.
///
/// Shows an accordion-style list where one request is expanded at a time,
/// displaying vibe match info and approve/decline buttons.
class PendingRequestsSection extends StatefulWidget {
  const PendingRequestsSection({
    super.key,
    required this.pendingRequests,
    required this.ownerVibeProfile,
    required this.expandedRequestId,
    required this.onApprove,
    required this.onDecline,
    required this.onRemoved,
    required this.onExpandRequest,
  });

  final List<JoinRequest> pendingRequests;
  final VibeProfile ownerVibeProfile;
  final String? expandedRequestId;
  final void Function(JoinRequest request) onApprove;
  final void Function(JoinRequest request) onDecline;
  final void Function(String requestId) onRemoved;
  final void Function(String requestId) onExpandRequest;

  @override
  State<PendingRequestsSection> createState() => _PendingRequestsSectionState();
}

class _PendingRequestsSectionState extends State<PendingRequestsSection> {
  final VibeRepository _vibeRepository = VibeRepository();
  Future<_PendingRequestSectionData>? _requestDataFuture;
  String _requestIdsKey = '';

  @override
  void initState() {
    super.initState();
    _refreshRequestDataFuture();
  }

  @override
  void didUpdateWidget(PendingRequestsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_buildRequestIdsKey(oldWidget.pendingRequests) !=
        _buildRequestIdsKey(widget.pendingRequests)) {
      _refreshRequestDataFuture(force: true);
    }
  }

  String _buildRequestIdsKey(List<JoinRequest> requests) =>
      requests.map((request) => request.requesterId).join('|');

  void _refreshRequestDataFuture({bool force = false}) {
    final newKey = _buildRequestIdsKey(widget.pendingRequests);
    if (!force && _requestDataFuture != null && _requestIdsKey == newKey) {
      return;
    }
    _requestIdsKey = newKey;
    _requestDataFuture = _loadRequestData(widget.pendingRequests);
  }

  Future<_PendingRequestSectionData> _loadRequestData(
    List<JoinRequest> pendingRequests,
  ) async {
    if (pendingRequests.isEmpty) return const _PendingRequestSectionData.empty();

    final requesterIds = pendingRequests
        .map((request) => request.requesterId)
        .toSet()
        .toList();
    final profileProvider = context.read<ProfileProvider>();

    final results = await Future.wait<Object>([
      profileProvider.batchGetProfiles(requesterIds),
      _fetchVibeProfiles(requesterIds),
    ]);

    return _PendingRequestSectionData(
      profileMap: results[0] as Map<String, UsersRecord>,
      vibeProfilesById: results[1] as Map<String, VibeProfile>,
    );
  }

  Future<Map<String, VibeProfile>> _fetchVibeProfiles(
    List<String> requesterIds,
  ) async {
    final entries = await Future.wait(
      requesterIds.map((requesterId) async {
        final vibeProfile =
            await _vibeRepository.getVibeProfileForUser(requesterId);
        return MapEntry(requesterId, vibeProfile);
      }),
    );

    return {
      for (final entry in entries) entry.key: entry.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with styled count
          PremiumSectionHeader(
            title: 'Pending requests',
            trailing: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '(',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '${widget.pendingRequests.length}',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ')',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          // Fetch profiles and vibe data in one pass, then render accordion.
          FutureBuilder<_PendingRequestSectionData>(
            future: _requestDataFuture,
            builder: (context, requestDataSnapshot) {
              if (!requestDataSnapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                );
              }

              final requestData = requestDataSnapshot.data!;
              final profileMap = requestData.profileMap;
              final vibeProfilesById = requestData.vibeProfilesById;

              return Column(
                children: widget.pendingRequests.map((request) {
                  final requesterProfile = profileMap[request.requesterId];
                  if (requesterProfile == null) {
                    return const SizedBox.shrink();
                  }

                  final requesterVibeProfile =
                      vibeProfilesById[request.requesterId] ??
                          VibeProfile.defaults();
                  final isExpanded = request.id == widget.expandedRequestId;

                  // Build expanded card or collapsed row with animation
                  return AnimatedSize(
                    duration: ReducedMotionService.adjust(
                      MotionTokens.contentReveal,
                    ),
                    curve: MotionTokens.curveEnter,
                    alignment: Alignment.topCenter,
                    child: isExpanded
                        ? _ExpandedRequestCard(
                            request: request,
                            requesterProfile: requesterProfile,
                            ownerVibeProfile: widget.ownerVibeProfile,
                            requesterVibeProfile: requesterVibeProfile,
                            onApprove: () => widget.onApprove(request),
                            onDecline: () => widget.onDecline(request),
                            onRemoved: () => widget.onRemoved(request.id),
                          )
                        : _CollapsedRequestRow(
                            request: request,
                            requesterProfile: requesterProfile,
                            onTap: () => widget.onExpandRequest(request.id),
                          ),
                  );
                }).toList(),
              );
            },
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Builds the fully expanded join request card with vibe info and buttons
class _ExpandedRequestCard extends StatelessWidget {
  const _ExpandedRequestCard({
    required this.request,
    required this.requesterProfile,
    required this.ownerVibeProfile,
    required this.requesterVibeProfile,
    required this.onApprove,
    required this.onDecline,
    required this.onRemoved,
  });

  final JoinRequest request;
  final UsersRecord requesterProfile;
  final VibeProfile ownerVibeProfile;
  final VibeProfile requesterVibeProfile;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final matchResult = VibeMatcher.score(
      ownerVibeProfile,
      requesterVibeProfile,
    );

    return AnimatedOpacity(
      duration: MotionTokens.contentReveal,
      opacity: 1.0,
      child: Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: VibeJoinRequestCard(
          request: request,
          requesterProfile: requesterProfile,
          ownerVibeProfile: ownerVibeProfile,
          requesterVibeProfile: requesterVibeProfile,
          matchResult: matchResult,
          onApprove: onApprove,
          onDecline: onDecline,
          onRemoved: onRemoved,
        ),
      ),
    );
  }
}

/// Builds a collapsed row for a join request (accordion pattern)
class _CollapsedRequestRow extends StatelessWidget {
  const _CollapsedRequestRow({
    required this.request,
    required this.requesterProfile,
    required this.onTap,
  });

  final JoinRequest request;
  final UsersRecord requesterProfile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: MotionTokens.contentReveal,
      opacity: 1.0,
      child: CollapsedJoinRequestRow(
        requesterProfile: requesterProfile,
        onTap: onTap,
      ),
    );
  }
}

class _PendingRequestSectionData {
  const _PendingRequestSectionData({
    required this.profileMap,
    required this.vibeProfilesById,
  });

  const _PendingRequestSectionData.empty()
      : profileMap = const <String, UsersRecord>{},
        vibeProfilesById = const <String, VibeProfile>{};

  final Map<String, UsersRecord> profileMap;
  final Map<String, VibeProfile> vibeProfilesById;
}
