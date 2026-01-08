import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/utils/upload_data.dart';
import '/newsfeed/newsfeed/newsfeed_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BlogCreateWidget extends StatefulWidget {
  const BlogCreateWidget({super.key});

  static String routeName = 'blog_create';
  static String routePath = '/blogCreate';

  @override
  State<BlogCreateWidget> createState() => _BlogCreateWidgetState();
}

class _BlogCreateWidgetState extends State<BlogCreateWidget> {
  FocusNode? inputTitleFocusNode;
  TextEditingController? inputTitleTextController;
  String? Function(BuildContext, String?)? inputTitleTextControllerValidator;
  FocusNode? inputContentFocusNode;
  TextEditingController? inputContentTextController;
  String? Function(BuildContext, String?)? inputContentTextControllerValidator;
  bool isDataUploadingCreatePicNewsfeed = false;
  UploadedFile uploadedLocalFileCreatePicNewsfeed =
      UploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrlCreatePicNewsfeed = '';

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    inputTitleTextController = TextEditingController();
    inputTitleFocusNode = FocusNode();

    inputContentTextController = TextEditingController();
    inputContentFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    inputTitleFocusNode?.dispose();
    inputTitleTextController?.dispose();

    inputContentFocusNode?.dispose();
    inputContentTextController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).secondaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.of(context).secondaryBackground,
        automaticallyImplyLeading: false,
        leading: InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () async {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go('/');
            }
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.of(context).secondaryText,
            size: 20.0,
          ),
        ),
        title: Text(
          'Create Post',
          style: AppTheme.of(context).bodyMedium.override(
                font: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                ),
                color: AppTheme.of(context).primary,
                fontSize: 26.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
              ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: FairwayBackgroundLight(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: AppSpacing.allSm,
                  child: TextFormField(
                    controller: inputTitleTextController,
                    focusNode: inputTitleFocusNode,
                    autofocus: true,
                    obscureText: false,
                    decoration: InputDecoration(
                      hintText: 'Enter title',
                      hintStyle:
                          AppTheme.of(context).bodySmall.override(
                                font: GoogleFonts.outfit(
                                  fontWeight: AppTheme.of(context)
                                      .bodySmall
                                      .fontWeight,
                                  fontStyle: AppTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: AppTheme.of(context)
                                    .bodySmall
                                    .fontWeight,
                                fontStyle: AppTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1.0,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1.0,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1.0,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0x00000000),
                          width: 1.0,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(4.0),
                        ),
                      ),
                    ),
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                    validator: inputTitleTextControllerValidator
                        .asValidator(context),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 0.94,
                  decoration: BoxDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: inputContentTextController,
                                focusNode: inputContentFocusNode,
                                obscureText: false,
                                decoration: InputDecoration(
                                  hintText: 'Enter post details here...',
                                  hintStyle: AppTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.outfit(
                                          fontWeight:
                                              AppTheme.of(context)
                                                  .bodySmall
                                                  .fontWeight,
                                          fontStyle:
                                              AppTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: AppTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppTheme.of(context)
                                          .primaryBackground,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x00000000),
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  contentPadding: EdgeInsets.only(
                                      left: AppSpacing.lg,
                                      top: AppSpacing.xxl,
                                      right: AppSpacing.lg,
                                      bottom: AppSpacing.sm),
                                ),
                                style: AppTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: AppTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: AppTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                textAlign: TextAlign.start,
                                maxLines: 4,
                                validator: inputContentTextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  valueOrDefault<String>(
                    uploadedFileUrlCreatePicNewsfeed,
                    'https://wiki.tripwireinteractive.com/TWIimages/4/47/Placeholder.png',
                  ),
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
              ),
              AppButtonEnhanced(
                text: 'Upload Image',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: () async {
                  final selectedMedia = await selectMediaWithSourceBottomSheet(
                    context: context,
                    maxWidth: 200.00,
                    maxHeight: 200.00,
                    allowPhoto: true,
                    backgroundColor:
                        AppTheme.of(context).primaryBtnText,
                    textColor: AppTheme.of(context).primary,
                  );
                  if (selectedMedia != null &&
                      selectedMedia.every(
                          (m) => validateFileFormat(m.storagePath, context))) {
                    if (mounted) setState(
                        () => isDataUploadingCreatePicNewsfeed = true);
                    var selectedUploadedFiles = <UploadedFile>[];

                    var downloadUrls = <String>[];
                    try {
                      selectedUploadedFiles = selectedMedia
                          .map((m) => UploadedFile(
                                name: m.storagePath.split('/').last,
                                bytes: m.bytes,
                                height: m.dimensions?.height,
                                width: m.dimensions?.width,
                                blurHash: m.blurHash,
                                originalFilename: m.originalFilename,
                              ))
                          .toList();

                      downloadUrls = (await Future.wait(
                        selectedMedia.map(
                          (m) async => await uploadData(m.storagePath, m.bytes),
                        ),
                      ))
                          .where((u) => u != null)
                          .map((u) => u!)
                          .toList();
                    } finally {
                      isDataUploadingCreatePicNewsfeed = false;
                    }
                    if (selectedUploadedFiles.length == selectedMedia.length &&
                        downloadUrls.length == selectedMedia.length) {
                      if (mounted) setState(() {
                        uploadedLocalFileCreatePicNewsfeed =
                            selectedUploadedFiles.first;
                        uploadedFileUrlCreatePicNewsfeed = downloadUrls.first;
                      });
                    } else {
                      if (mounted) setState(() {});
                      return;
                    }
                  }
                },
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: AppButtonEnhanced(
              text: 'Create Post',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              onPressed: () async {
                await PostsRecord.collection.doc().set(createPostsRecordData(
                      content: inputContentTextController.text,
                      title: inputTitleTextController.text,
                      author: currentUserReference,
                      mainImage: uploadedFileUrlCreatePicNewsfeed,
                    ));

                context.pushNamed(
                  NewsfeedWidget.routeName,
                  extra: <String, dynamic>{
                    kTransitionInfoKey: TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.bottomToTop,
                      duration: Duration(milliseconds: 220),
                    ),
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}
