import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/animations.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/app_card.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/custom_functions.dart' as functions;
import '/newsfeed/blog_create/blog_create_widget.dart';
import '/newsfeed/blog_edit/blog_edit_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:text_search/text_search.dart';

class NewsfeedWidget extends StatefulWidget {
  const NewsfeedWidget({super.key, this.isEmbedded = false});

  final bool isEmbedded;
  static String routeName = 'Newsfeed';
  static String routePath = '/newsfeed';

  @override
  State<NewsfeedWidget> createState() => _NewsfeedWidgetState();
}

class _NewsfeedWidgetState extends State<NewsfeedWidget>
    with TickerProviderStateMixin {
  FocusNode? inputSearchFocusNode;
  TextEditingController? inputSearchTextController;
  String? Function(BuildContext, String?)? inputSearchTextControllerValidator;
  List<PostsRecord> simpleSearchResults = [];

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    inputSearchTextController = TextEditingController();
    inputSearchFocusNode = FocusNode();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 100.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'rowOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'rowOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    inputSearchFocusNode?.dispose();
    inputSearchTextController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PostsRecord>>(
      future: queryPostsRecordOnce(),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          if (widget.isEmbedded) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitWanderingCubes(
                    color: AppColors.sunsetGold,
                    size: 50.0,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Loading news...',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }
          return Scaffold(
            backgroundColor: AppTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitWanderingCubes(
                  color: AppTheme.of(context).secondary,
                  size: 50.0,
                ),
              ),
            ),
          );
        }
        List<PostsRecord> newsfeedPostsRecordList = snapshot.data!;
        final posts = functions
            .getResultList(
              newsfeedPostsRecordList.toList(),
              simpleSearchResults.toList(),
            )
            .toList();

        // Build the content
        Widget content = _buildNewsContent(posts, newsfeedPostsRecordList);

        // If embedded, just return the content
        if (widget.isEmbedded) {
          return content;
        }

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go('/');
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(left: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.fairway.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 28.0,
                  ),
                ),
              ),
              title: Text(
                'Twlv Stix News',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
              elevation: 0.0,
            ),
            body: FairwayBackgroundDark(
              showOrganic: true,
              showTexture: true,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 56,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsContent(List<PostsRecord> posts, List<PostsRecord> newsfeedPostsRecordList) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.fairway.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: TextFormField(
                      controller: inputSearchTextController,
                      focusNode: inputSearchFocusNode,
                      autofocus: false,
                      obscureText: false,
                      decoration: InputDecoration(
                        hintText: 'Search news...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                      validator: inputSearchTextControllerValidator.asValidator(context),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    if (mounted) setState(() {
                      simpleSearchResults = TextSearch(
                        newsfeedPostsRecordList
                            .map(
                              (record) => TextSearchItem.fromTerms(
                                  record, [record.title, record.content]),
                            )
                            .toList(),
                      )
                          .search(inputSearchTextController!.text)
                          .map((r) => r.object)
                          .toList();
                    });
                    if (simpleSearchResults.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No results found',
                            style: TextStyle(color: Colors.white),
                          ),
                          duration: Duration(milliseconds: 2000),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Search',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (valueOrDefault<bool>(
                  valueOrDefault(currentUserDocument?.role, '') == 'admin',
                  false,
                )) ...[
                  SizedBox(width: AppSpacing.xs),
                  AuthUserStreamWidget(
                    builder: (context) => GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        context.pushNamed(
                          BlogCreateWidget.routeName,
                          extra: <String, dynamic>{
                            kTransitionInfoKey: TransitionInfo(
                              hasTransition: true,
                              transitionType: PageTransitionType.bottomToTop,
                              duration: Duration(milliseconds: 220),
                            ),
                          },
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.fairwayLight, AppColors.fairway],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (posts.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.fairway.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.article_outlined,
                      color: Colors.white.withOpacity(0.5),
                      size: 40,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'No News Yet',
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Check back later for updates',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, postsIndex) {
                  final postsItem = posts[postsIndex];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildPremiumNewsCard(postsItem),
                  );
                },
                childCount: posts.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumNewsCard(PostsRecord post) {
    final isAdmin = valueOrDefault(currentUserDocument?.role, '') == 'admin';

    return GestureDetector(
      onTap: isAdmin
          ? () {
              HapticFeedback.lightImpact();
              context.pushNamed(
                BlogEditWidget.routeName,
                queryParameters: {
                  'postRef': serializeParam(
                    post.reference,
                    ParamType.DocumentReference,
                  ),
                }.withoutNulls,
                extra: <String, dynamic>{
                  kTransitionInfoKey: TransitionInfo(
                    hasTransition: true,
                    transitionType: PageTransitionType.bottomToTop,
                    duration: Duration(milliseconds: 220),
                  ),
                },
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.fairway.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Hero(
                  tag: valueOrDefault<String>(
                    post.mainImage,
                    'https://wiki.tripwireinteractive.com/TWIimages/4/47/Placeholder.png${post.reference.id}',
                  ),
                  transitionOnUserGestures: true,
                  child: CachedNetworkImage(
                    imageUrl: valueOrDefault<String>(
                      post.mainImage,
                      'https://wiki.tripwireinteractive.com/TWIimages/4/47/Placeholder.png',
                    ),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                // Delete button for admin
                if (isAdmin)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: AuthUserStreamWidget(
                      builder: (context) => GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await post.reference.delete();
                          if (mounted) setState(() {});
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    post.content.maybeHandleOverflow(
                      maxChars: 100,
                      replacement: '…',
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!);
  }
}
