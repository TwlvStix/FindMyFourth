import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';

/// Premium profile hero section with animated gradient ring around avatar.
///
/// Creates a striking visual anchor for profile pages with:
/// - Large circular avatar (140px)
/// - Animated rotating gradient ring
/// - Display name overlaid
/// - Dark gradient background
/// - Edit button positioned elegantly
class ProfileHeroSection extends StatefulWidget {
  final String photoUrl;
  final String displayName;
  final VoidCallback onEditPhoto;

  const ProfileHeroSection({
    Key? key,
    required this.photoUrl,
    required this.displayName,
    required this.onEditPhoto,
  }) : super(key: key);

  @override
  State<ProfileHeroSection> createState() => _ProfileHeroSectionState();
}

class _ProfileHeroSectionState extends State<ProfileHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.fairwayDark,
            AppColors.fairwayDark.withValues(alpha: 0.8),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle radial glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    AppColors.sunsetGold.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Avatar with animated gradient ring
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated gradient ring
                  RotationTransition(
                    turns: _controller,
                    child: Container(
                      width: 156,
                      height: 156,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppColors.fairway,
                            AppColors.sunsetGold,
                            AppColors.sunsetPeach,
                            AppColors.fairway,
                          ],
                          stops: [0.0, 0.33, 0.66, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Avatar container
                  GestureDetector(
                    onTap: widget.onEditPhoto,
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pure,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.network(
                          widget.photoUrl.isNotEmpty
                              ? widget.photoUrl
                              : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: AppColors.cloud,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.stone,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Edit button - positioned bottom-right of avatar
                  Positioned(
                    bottom: 8,
                    right: MediaQuery.of(context).size.width / 2 - 74 + 8,
                    child: GestureDetector(
                      onTap: widget.onEditPhoto,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sunsetGold,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Display name
          if (widget.displayName.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                widget.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
