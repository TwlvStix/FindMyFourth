import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/utils/state_update.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '/backend/cloud_functions/cloud_functions.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/motion/motion_tokens.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/services/trust_flow_service.dart';
import 'components/peer_rating_header.dart';
import 'components/peer_rating_row.dart';
import 'components/peer_rating_status_views.dart';

/// PeerRatingScreen
///
/// Allows app users to rate each other with a segmented toggle
/// ('would you play again') after the host has confirmed attendance.
/// Opened via push notification ~30 min after host confirms.
///
/// Guests are excluded from rating and being rated.
///
/// Route name: 'PeerRating'
/// Parameters: gameRef (DocumentReference)
class PeerRatingScreen extends StatefulWidget {
  const PeerRatingScreen({super.key, required this.gameRef});

  final DocumentReference gameRef;

  static const String routeName = 'PeerRating';
  static const String routePath = '/peerRating';

  @override
  State<PeerRatingScreen> createState() => _PeerRatingScreenState();
}

class _PeerRatingScreenState extends State<PeerRatingScreen>
    with TickerProviderStateMixin {
  final _trustFlowService = TrustFlowService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _submitted = false;
  bool _alreadyCompleted = false;
  bool _windowClosed = false;

  String _courseName = '';

  // Present app users to rate (excluding current user)
  final List<RateeEntry> _ratees = [];

  // Ratings map: uid → wouldPlayAgain (bool)
  final Map<String, bool?> _ratings = {};

  // Staggered entrance animation
  late AnimationController _staggerController;
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadRatees();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _navigateToMyGames({String? message}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.go(GamesJoinedWidget.routePath);
    if (message != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.success,
        duration: const Duration(milliseconds: 3000),
      ));
    }
  }

  void _buildStaggerAnimations() {
    _fadeAnimations.clear();
    _slideAnimations.clear();

    final itemCount =
        _ratees.length.clamp(0, MotionTokens.staggerMaxItems);
    if (itemCount == 0) return;

    for (int i = 0; i < _ratees.length; i++) {
      final staggerIndex = i.clamp(0, MotionTokens.staggerMaxItems - 1);
      final startFraction = (staggerIndex * 24) / 600;
      final endFraction = (startFraction + 0.4).clamp(0.0, 1.0);

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(startFraction, endFraction,
                curve: MotionTokens.curveEnter),
          ),
        ),
      );

      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(startFraction, endFraction,
                curve: MotionTokens.curveEnter),
          ),
        ),
      );
    }
  }

  Future<void> _loadRatees() async {
    try {
      final status = await _trustFlowService.checkPeerRatingStatus(
        gameRef: widget.gameRef,
      );
      if (!mounted) return;
      if (status == ConfirmationStatus.completed) {
        updateState(this, () {
          _alreadyCompleted = true;
          _loading = false;
        });
        return;
      }
      if (status == ConfirmationStatus.windowClosed) {
        updateState(this, () {
          _windowClosed = true;
          _loading = false;
        });
        return;
      }

      final data =
          await _trustFlowService.loadPeerRatees(gameRef: widget.gameRef);

      if (mounted) {
        updateState(this, () {
          _courseName = data.courseName;
          _ratees.addAll(
            data.ratees.map(
              (ratee) => RateeEntry(
                uid: ratee.uid,
                displayName: ratee.displayName,
                photoUrl: ratee.photoUrl,
              ),
            ),
          );
          _ratings.addAll(data.initialRatings);
          _loading = false;
        });
        _buildStaggerAnimations();
        _staggerController.forward();
      }
    } on StateError catch (e) {
      final code = e.message;
      if (mounted) {
        updateState(this, () {
          _error = code == 'not_signed_in'
              ? 'Not signed in.'
              : code == 'game_not_found'
                  ? 'Game not found.'
                  : 'Failed to load players. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      AppLog.d('PeerRatingScreen load error: $e');
      if (mounted) {
        updateState(this, () {
          _error = 'Failed to load players. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final ratedMap = <String, bool>{};
    for (final entry in _ratings.entries) {
      if (entry.value != null) {
        ratedMap[entry.key] = entry.value!;
      }
    }

    if (ratedMap.isEmpty) {
      updateState(this, () {
        _error = 'Please rate at least one player before submitting.';
      });
      return;
    }

    updateState(this, () {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await makeCloudCall('submitPeerRatings', {
        'gameId': widget.gameRef.id,
        'ratings': ratedMap,
      });

      if (result['success'] == true) {
        if (mounted) {
          updateState(this, () {
            _submitting = false;
            _submitted = true;
          });
        }
      } else {
        if (mounted) {
          updateState(this, () {
            _submitting = false;
            _error = 'Submission failed. Please try again.';
          });
        }
      }
    } catch (e) {
      AppLog.d('❌ PeerRatingScreen submit error: $e');
      if (mounted) {
        updateState(this, () {
          _submitting = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Status views (loading, already completed, window closed, submitted, empty/error)
    if (_loading) {
      return const PeerRatingStatusView(type: PeerRatingStatusType.loading);
    }
    if (_alreadyCompleted) {
      return PeerRatingStatusView(
        type: PeerRatingStatusType.alreadyCompleted,
        onDone: () => _navigateToMyGames(),
      );
    }
    if (_windowClosed) {
      return PeerRatingStatusView(
        type: PeerRatingStatusType.windowClosed,
        onDone: () => _navigateToMyGames(),
      );
    }
    if (_submitted) {
      return PeerRatingStatusView(
        type: PeerRatingStatusType.submitted,
        onDone: () => _navigateToMyGames(),
      );
    }
    if (_ratees.isEmpty) {
      return PeerRatingStatusView(
        type: PeerRatingStatusType.empty,
        error: _error,
        onDone: () => _navigateToMyGames(),
        onRetry: () {
          updateState(this, () {
            _loading = true;
            _error = null;
          });
          _loadRatees();
        },
      );
    }

    // Main rating form
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        title: Text('Rate Your Group', style: AppTypography.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon:
              PhosphorIcon(AppPhosphorIcons.back, color: AppColors.textPrimary),
          onPressed: () => _navigateToMyGames(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      PeerRatingHeader(courseName: _courseName),
                      SizedBox(height: AppSpacing.xxxl),
                      Padding(
                        padding: AppSpacing.symmetric(
                            horizontal: AppSpacing.screenPadding),
                        child: Column(
                          children: [
                            for (int i = 0; i < _ratees.length; i++) ...[
                              if (i > 0) SizedBox(height: AppSpacing.xxs),
                              _buildRateeRow(i),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),
                      if (_error != null)
                        Padding(
                          padding: AppSpacing.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.sm),
                          child: Text(
                            _error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Padding(
                        padding: AppSpacing.only(
                            left: AppSpacing.xl,
                            right: AppSpacing.xl,
                            bottom: AppSpacing.xxl,
                            top: AppSpacing.lg),
                        child: AppButtonEnhanced(
                          onPressed: _submitting ? null : _submit,
                          text: _submitting ? 'Submitting...' : 'Submit Ratings',
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.large,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRateeRow(int i) {
    final ratee = _ratees[i];
    Widget row = RateeRow(
      ratee: ratee,
      rating: _ratings[ratee.uid],
      onRate: (val) {
        updateState(this, () {
          _ratings[ratee.uid] = val;
        });
      },
    );

    if (i < _fadeAnimations.length) {
      row = AnimatedBuilder(
        animation: _staggerController,
        builder: (context, child) => Opacity(
          opacity: _fadeAnimations[i].value,
          child: SlideTransition(
            position: _slideAnimations[i],
            child: child,
          ),
        ),
        child: row,
      );
    }

    return row;
  }
}
