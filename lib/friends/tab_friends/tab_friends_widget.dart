import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/autocomplete_options_list.dart';
import '/core/button_tabbar.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/navigation/app_router.dart';
import '/profile/profile_user/profile_user_firebase_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import '/providers/user_provider.dart';

class TabFriendsWidget extends StatefulWidget {
  const TabFriendsWidget({super.key});

  static String routeName = 'Tab_Friends';
  static String routePath = '/tabFriends';

  @override
  State<TabFriendsWidget> createState() => _TabFriendsWidgetState();
}

class _TabFriendsWidgetState extends State<TabFriendsWidget>
    with TickerProviderStateMixin {
  List<String> reqUserList = [];
  void addToReqUserList(String item) => reqUserList.add(item);
  void removeFromReqUserList(String item) => reqUserList.remove(item);
  void removeAtIndexFromReqUserList(int index) => reqUserList.removeAt(index);
  void insertAtIndexInReqUserList(int index, String item) =>
      reqUserList.insert(index, item);
  void updateReqUserListAtIndex(int index, Function(String) updateFn) =>
      reqUserList[index] = updateFn(reqUserList[index]);

  List<DocumentReference> friendList = [];
  void addToFriendList(DocumentReference item) => friendList.add(item);
  void removeFromFriendList(DocumentReference item) => friendList.remove(item);
  void removeAtIndexFromFriendList(int index) => friendList.removeAt(index);
  void insertAtIndexInFriendList(int index, DocumentReference item) =>
      friendList.insert(index, item);
  void updateFriendListAtIndex(
          int index, Function(DocumentReference) updateFn) =>
      friendList[index] = updateFn(friendList[index]);

  TabController? tabBarController;
  int get tabBarCurrentIndex => tabBarController != null
      ? tabBarController!.index
      : 0;
  int get tabBarPreviousIndex => tabBarController != null
      ? tabBarController!.previousIndex
      : 0;

  final textFieldKey = GlobalKey();
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? textFieldSelectedOption;
  String? Function(BuildContext, String?)? textControllerValidator;

  Future<void> _openDirectChat(UsersRecord user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        showSnackbar(context, 'Please sign in to chat.');
      }
      return;
    }
    final currentUserId = currentUser.uid;
    final otherUserId = user.reference.id;
    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserId,
            otherUid: otherUserId,
          );
      context.pushNamed(
        'ChatDetails',
        pathParameters: {
          'chatId': chatRef.id,
        },
      );
    } catch (error, stackTrace) {
      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);
      if (mounted) {
        showSnackbar(context, 'Unable to start chat. Please try again.');
      }
    }
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    tabBarController = TabController(
      vsync: this,
      length: 3,
      initialIndex: 0,
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    textController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    textController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.of(context).alternate,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).alternate,
          automaticallyImplyLeading: false,
          leading: AppIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 55.0,
            icon: Icon(
              Icons.arrow_back_sharp,
              color: AppTheme.of(context).primary,
              size: 25.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Golfers',
            style: AppTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.outfit(
                    fontWeight:
                        AppTheme.of(context).headlineSmall.fontWeight,
                    fontStyle:
                        AppTheme.of(context).headlineSmall.fontStyle,
                  ),
                  color: AppTheme.of(context).primary,
                  letterSpacing: 0.0,
                  fontWeight:
                      AppTheme.of(context).headlineSmall.fontWeight,
                  fontStyle:
                      AppTheme.of(context).headlineSmall.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: false,
        ),
        body: FairwayBackgroundDark(
          child: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Expanded(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment(-1.0, 0),
                      child: AppButtonTabBar(
                        useToggleButtonStyle: false,
                        labelStyle:
                            AppTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.outfit(
                                    fontWeight: AppTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: AppTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  fontSize: 18.0,
                                  letterSpacing: 0.0,
                                  fontWeight: AppTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: AppTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                        unselectedLabelStyle: TextStyle(),
                        labelColor: AppTheme.of(context).primaryBtnText,
                        unselectedLabelColor:
                            AppTheme.of(context).secondaryText,
                        backgroundColor: AppTheme.of(context).primary,
                        unselectedBackgroundColor:
                            AppTheme.of(context).alternate,
                        borderColor: AppTheme.of(context).primary,
                        unselectedBorderColor:
                            AppTheme.of(context).alternate,
                        borderWidth: 2.0,
                        borderRadius: 8.0,
                        elevation: 0.0,
                        labelPadding: EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.sm, 0.0, AppSpacing.sm, 0.0),
                        buttonMargin:
                            EdgeInsetsDirectional.fromSTEB(AppSpacing.xs, 0.0, AppSpacing.xs, 0.0),
                        padding: AppSpacing.allXxs,
                        tabs: [
                          Tab(
                            text: 'Search',
                          ),
                          Tab(
                            text: 'Requests',
                          ),
                          Tab(
                            text: 'Friends',
                          ),
                        ],
                        controller: tabBarController,
                        onTap: (i) async {
                          [
                            () async {},
                            () async {
                              friendList = [];
                              if (mounted) setState(() {});
                            },
                            () async {
                              friendList = [];
                              if (mounted) setState(() {});
                            }
                          ][i]();
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tabBarController,
                        children: [
                          KeepAliveWidgetWrapper(
                            builder: (context) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.of(context)
                                    .secondaryBackground,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: Image.asset(
                                    'assets/images/igdownloader.com_2980395830822133751.jpg',
                                  ).image,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(AppSpacing.xs, 0.0, AppSpacing.xs, 0.0),
                                              child: Autocomplete<String>(
                                                initialValue:
                                                    TextEditingValue(),
                                                optionsBuilder:
                                                    (textEditingValue) {
                                                  if (textEditingValue.text ==
                                                      '') {
                                                    return const Iterable<
                                                        String>.empty();
                                                  }
                                                  return ['Option 1']
                                                      .where((option) {
                                                    final lowercaseOption =
                                                        option.toLowerCase();
                                                    return lowercaseOption
                                                        .contains(
                                                            textEditingValue
                                                                .text
                                                                .toLowerCase());
                                                  });
                                                },
                                                optionsViewBuilder: (context,
                                                    onSelected, options) {
                                                  return AutocompleteOptionsList(
                                                    textFieldKey: textFieldKey,
                                                    textController:
                                                        textController!,
                                                    options: options.toList(),
                                                    onSelected: onSelected,
                                                    textStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .outfit(
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                              fontStyle:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                    textHighlightStyle:
                                                        TextStyle(),
                                                    elevation: 4.0,
                                                    optionBackgroundColor:
                                                        AppTheme.of(
                                                                context)
                                                            .primaryBackground,
                                                    optionHighlightColor:
                                                        AppTheme.of(
                                                                context)
                                                            .secondaryBackground,
                                                    maxHeight: 200.0,
                                                  );
                                                },
                                                onSelected: (String selection) {
                                                  if (mounted) {
                                                    setState(() =>
                                                        textFieldSelectedOption =
                                                            selection);
                                                  }
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                },
                                                fieldViewBuilder: (
                                                  context,
                                                  textEditingController,
                                                  focusNode,
                                                  onEditingComplete,
                                                ) {
                                                  textFieldFocusNode =
                                                      focusNode;

                                                  textController =
                                                      textEditingController;
                                                  return TextFormField(
                                                    key: textFieldKey,
                                                    controller:
                                                        textEditingController,
                                                    focusNode: focusNode,
                                                    onChanged: (_) {
                                                      if (mounted) {
                                                        setState(() {});
                                                      }
                                                    },
                                                    onEditingComplete:
                                                        onEditingComplete,
                                                    autofocus: true,
                                                    obscureText: false,
                                                    decoration: InputDecoration(
                                                      labelStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                      hintStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .primaryBtnText,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .primaryBtnText,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      errorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .error,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppTheme
                                                                  .of(context)
                                                              .error,
                                                          width: 2.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      prefixIcon: Icon(
                                                        Icons.search_rounded,
                                                        color:
                                                            AppTheme.of(
                                                                    context)
                                                                .primaryBtnText,
                                                      ),
                                                    ),
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .outfit(
                                                            fontWeight:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: AppTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                    validator: textControllerValidator
                                                        .asValidator(context),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    AppSpacing.sm, 0.0, 0.0, 0.0),
                                            child: AppIconButton(
                                              borderColor: Colors.transparent,
                                              borderRadius: 30.0,
                                              borderWidth: 1.0,
                                              buttonSize: 44.0,
                                              icon: Icon(
                                                Icons.clear_sharp,
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                size: 24.0,
                                              ),
                                              onPressed: () {
                                                textController?.clear();
                                                FocusScope.of(context)
                                                    .unfocus();
                                                if (mounted) {
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          AppSpacing.xl, 0.0, 0.0, 0.0),
                                      child: Text(
                                        'Add a Friend Request',
                                        style: AppTheme.of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight:
                                                    AppTheme.of(context)
                                                        .labelMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    AppTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  AppTheme.of(context)
                                                      .primaryBtnText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                    StreamBuilder<List<UsersRecord>>(
                                      stream: (() {
                                        final term = textController?.text
                                                .trim()
                                                .toLowerCase() ??
                                            '';
                                        if (term.isEmpty) {
                                          return Stream.value(<UsersRecord>[]);
                                        }
                                        return queryUsersRecord(
                                          queryBuilder: (usersRecord) =>
                                              usersRecord
                                                  .orderBy('display_name')
                                                  .startAt([term]).endAt(
                                                      ['${term}\uf8ff']).limit(25),
                                        );
                                      })(),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: SpinKitWanderingCubes(
                                                color: AppTheme.of(context).secondary,
                                                size: 50.0,
                                              ),
                                            ),
                                          );
                                        }
                                        final searchTerm = textController?.text
                                                .trim()
                                                .toLowerCase() ??
                                            '';
                                        List<UsersRecord>
                                            listViewUsersRecordList = snapshot
                                                .data!
                                                .where((u) =>
                                                    u.uid != currentUserUid)
                                                .where((user) {
                                          if (searchTerm.isEmpty) {
                                            return true;
                                          }
                                          final displayName =
                                              user.displayName.toLowerCase();
                                          final firstName =
                                              user.firstName.toLowerCase();
                                          final lastName =
                                              user.lastName.toLowerCase();
                                          return displayName
                                                  .contains(searchTerm) ||
                                              firstName.contains(searchTerm) ||
                                              lastName.contains(searchTerm);
                                        }).toList();

                                        return ListView.separated(
                                          padding: EdgeInsets.fromLTRB(
                                            0,
                                            AppSpacing.sm,
                                            0,
                                            44.0,
                                          ),
                                          primary: false,
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount:
                                              listViewUsersRecordList.length,
                                          separatorBuilder: (_, __) =>
                                              SizedBox(height: AppSpacing.sm),
                                          itemBuilder:
                                              (context, listViewIndex) {
                                            final listViewUsersRecord =
                                                listViewUsersRecordList[
                                                    listViewIndex];
                                            return Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      12.0, 0.0, 12.0, 0.0),
                                              child: Container(
                                                width: double.infinity,
                                                height: 60.0,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.of(
                                                          context)
                                                      .primaryBtnText,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      blurRadius: 4.0,
                                                      color: Color(0x32000000),
                                                      offset: Offset(
                                                        0.0,
                                                        2.0,
                                                      ),
                                                    )
                                                  ],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          8.0, 0.0, 8.0, 0.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(26.0),
                                                        child: Image.network(
                                                          valueOrDefault<
                                                              String>(
                                                            listViewUsersRecord
                                                                .photoUrl,
                                                            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                          ),
                                                          width: 36.0,
                                                          height: 36.0,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      12.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Align(
                                                                alignment:
                                                                    AlignmentDirectional(
                                                                        -1.0,
                                                                        0.0),
                                                                child: Text(
                                                                  valueOrDefault<
                                                                      String>(
                                                                    listViewUsersRecord
                                                                        .displayName,
                                                                    'name',
                                                                  ),
                                                                  style: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          fontStyle: AppTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        fontSize:
                                                                            16.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    AppSpacing.sm,
                                                                    0.0),
                                                        child: AppButtonEnhanced(
                                                          onPressed: () async {
                                                            Navigator.of(context)
                                                                .push(
                                                              MaterialPageRoute(
                                                                builder: (context) =>
                                                                    ProfileUserFirebaseWidget(
                                                                  userRef:
                                                                      listViewUsersRecord
                                                                          .reference,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          text: 'View',
                                                          variant: AppButtonVariant.primary,
                                                          size: AppButtonSize.small,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    5.0,
                                                                    0.0,
                                                                    5.0,
                                                                    0.0),
                                                        child:
                                                            AppIconButton(
                                                          borderColor:
                                                              AppTheme.of(
                                                                      context)
                                                                  .primary,
                                                          borderRadius: 20.0,
                                                          borderWidth: 1.0,
                                                          buttonSize: 40.0,
                                                          fillColor:
                                                              AppTheme.of(context).primary,
                                                          icon: FaIcon(
                                                            FontAwesomeIcons
                                                                .facebookMessenger,
                                                            color: Colors.white,
                                                            size: 18.0,
                                                          ),
                                                          onPressed: () async {
                                                            await _openDirectChat(
                                                                listViewUsersRecord);
                                                          },
                                                        ),
                                                      ),
                                                      Stack(
                                                        children: [
                                                          AuthUserStreamWidget(
                                                            builder: (context) {
                                                              final isFriend =
                                                                  (currentUserDocument
                                                                              ?.friends
                                                                              .toList() ??
                                                                          [])
                                                                      .contains(
                                                                listViewUsersRecord
                                                                    .reference,
                                                              );
                                                              final hasPending =
                                                                  listViewUsersRecord
                                                                      .friendRequests
                                                                      .contains(
                                                                          currentUserReference) ||
                                                                      (currentUserDocument
                                                                              ?.friendRequests
                                                                              .toList() ??
                                                                          [])
                                                                          .contains(
                                                                listViewUsersRecord
                                                                    .reference,
                                                              );
                                                              if (isFriend) {
                                                                return Padding(
                                                                  padding:
                                                                      EdgeInsetsDirectional
                                                                          .fromSTEB(
                                                                              5.0,
                                                                              0.0,
                                                                              5.0,
                                                                              0.0),
                                                                  child:
                                                                      AppIconButton(
                                                                    borderColor:
                                                                        AppTheme.of(context)
                                                                            .primary,
                                                                    borderRadius:
                                                                        20.0,
                                                                    borderWidth:
                                                                        1.0,
                                                                    buttonSize:
                                                                        40.0,
                                                                    fillColor:
                                                                        Color(
                                                                            0xFF253551),
                                                                    icon: Icon(
                                                                      Icons.people,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 22.0,
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      print(
                                                                          'friends pressed ...');
                                                                    },
                                                                  ),
                                                                );
                                                              }
                                                              if (hasPending) {
                                                                return Padding(
                                                                  padding:
                                                                      EdgeInsetsDirectional
                                                                          .fromSTEB(
                                                                              5.0,
                                                                              0.0,
                                                                              5.0,
                                                                              0.0),
                                                                  child:
                                                                      AppIconButton(
                                                                    borderColor:
                                                                        AppTheme.of(context)
                                                                            .primary,
                                                                    borderRadius:
                                                                        20.0,
                                                                    borderWidth:
                                                                        1.0,
                                                                    buttonSize:
                                                                        40.0,
                                                                    fillColor:
                                                                        Color(
                                                                            0xFF253551),
                                                                    icon: Icon(
                                                                      Icons
                                                                          .pending,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 22.0,
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      print(
                                                                          'pending pressed ...');
                                                                    },
                                                                  ),
                                                                );
                                                              }
                                                              return Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            5.0,
                                                                            0.0,
                                                                            5.0,
                                                                            0.0),
                                                                child:
                                                                    AppIconButton(
                                                                  borderColor:
                                                                      AppTheme.of(context)
                                                                          .primary,
                                                                  borderRadius:
                                                                      20.0,
                                                                  borderWidth:
                                                                      1.0,
                                                                  buttonSize:
                                                                      40.0,
                                                                  fillColor:
                                                                      Color(
                                                                          0xFF253551),
                                                                  icon: Icon(
                                                                    Icons.add,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 18.0,
                                                                  ),
                                                                  onPressed:
                                                                      () async {
                                                                    await context
                                                                        .read<UserProvider>()
                                                                        .sendFriendRequest(
                                                                          listViewUsersRecord
                                                                              .reference,
                                                                        );
                                                                    addToReqUserList(
                                                                        valueOrDefault<
                                                                            String>(
                                                                      listViewUsersRecord
                                                                          .uid,
                                                                      '007',
                                                                    ));
                                                                    if (mounted) {
                                                                      setState(
                                                                          () {});
                                                                    }
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .clearSnackBars();
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text(
                                                                          'A Friend Request Has Been Sent!',
                                                                          style: AppTheme.of(context)
                                                                              .titleMedium
                                                                              .override(
                                                                                font: GoogleFonts.outfit(
                                                                                  fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                                                                  fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                                                                                ),
                                                                                color: AppTheme.of(context).primaryBtnText,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                                                                fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                        duration:
                                                                            Duration(milliseconds: 1500),
                                                                        backgroundColor:
                                                                            AppTheme.of(context).primary,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          KeepAliveWidgetWrapper(
                            builder: (context) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              constraints: BoxConstraints(
                                minWidth: double.infinity,
                                minHeight: double.infinity,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.of(context)
                                    .secondaryBackground,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: Image.asset(
                                    'assets/images/igdownloader.com_2980395830822133751.jpg',
                                  ).image,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isiOS) const SizedBox.shrink(),
                                    AuthUserStreamWidget(
                                      builder: (context) => Builder(
                                        builder: (context) {
                                          final friendRequestList =
                                              (currentUserDocument
                                                          ?.friendRequests
                                                          .toList() ??
                                                      [])
                                                  .toList();
                                          print(
                                            'Requests tab friend_requests raw: ${currentUserDocument?.snapshotData['friend_requests']}',
                                          );

                                          return ListView.separated(
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              12.0,
                                              0,
                                              44.0,
                                            ),
                                            primary: false,
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount: friendRequestList.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: AppSpacing.sm),
                                            itemBuilder: (context,
                                                friendRequestListIndex) {
                                              final friendRequestListItem =
                                                  friendRequestList[
                                                      friendRequestListIndex];
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                                                child:
                                                    StreamBuilder<UsersRecord>(
                                                  stream:
                                                      UsersRecord.getDocument(
                                                          friendRequestListItem),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return Center(
                                                        child: SizedBox(
                                                          width: 50.0,
                                                          height: 50.0,
                                                          child:
                                                              SpinKitWanderingCubes(
                                                            color: Color(
                                                                0xFF25504F),
                                                            size: 50.0,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    final userList5UsersRecord =
                                                        snapshot.data!;

                                                    return Container(
                                                      width: double.infinity,
                                                      height: 60.0,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            blurRadius: 4.0,
                                                            color: Color(
                                                                0x32000000),
                                                            offset: Offset(
                                                              0.0,
                                                              2.0,
                                                            ),
                                                          )
                                                        ],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    8.0,
                                                                    0.0,
                                                                    8.0,
                                                                    0.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceAround,
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          26.0),
                                                              child:
                                                                  Image.network(
                                                                valueOrDefault<
                                                                    String>(
                                                                  userList5UsersRecord
                                                                      .photoUrl,
                                                                  'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                                ),
                                                                width: 36.0,
                                                                height: 36.0,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            12.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children: [
                                                                        Text(
                                                                          userList5UsersRecord
                                                                              .displayName,
                                                                          style: AppTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.outfit(
                                                                                  fontWeight: FontWeight.w500,
                                                                                  fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                                fontSize: 16.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.w500,
                                                                                fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          AppSpacing.xs,
                                                                          0.0),
                                                              child:
                                                                  AppButtonEnhanced(
                                                                onPressed:
                                                                    () async {
                                                                  Navigator.of(context)
                                                                      .push(
                                                                    MaterialPageRoute(
                                                                      builder: (context) =>
                                                                          ProfileUserFirebaseWidget(
                                                                        userRef:
                                                                            userList5UsersRecord.reference,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                text: 'View',
                                                                variant: AppButtonVariant.primary,
                                                                size: AppButtonSize.small,
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AppIconButton(
                                                                borderColor:
                                                                    AppTheme.of(
                                                                            context)
                                                                        .primary,
                                                                borderRadius:
                                                                    20.0,
                                                                borderWidth:
                                                                    1.0,
                                                                buttonSize:
                                                                    40.0,
                                                                fillColor: Color(
                                                                    0xFF253551),
                                                                icon: Icon(
                                                                  Icons.check,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 18.0,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  print(
                                                                    'Accept request: current=${currentUserReference?.path} requester=${userList5UsersRecord.reference.path}',
                                                                  );
                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .runTransaction(
                                                                          (transaction) async {
                                                                    transaction
                                                                        .update(
                                                                      currentUserReference!,
                                                                      {
                                                                        ...mapToFirestore(
                                                                          {
                                                                            'friends':
                                                                                FieldValue.arrayUnion([
                                                                              userList5UsersRecord.reference
                                                                            ]),
                                                                            'friend_requests':
                                                                                FieldValue.arrayRemove([
                                                                              userList5UsersRecord.reference,
                                                                              userList5UsersRecord.reference.id
                                                                            ]),
                                                                          },
                                                                        ),
                                                                      },
                                                                    );
                                                                    transaction
                                                                        .update(
                                                                      userList5UsersRecord
                                                                          .reference,
                                                                      {
                                                                        ...mapToFirestore(
                                                                          {
                                                                            'friends':
                                                                                FieldValue.arrayUnion([
                                                                              currentUserReference
                                                                            ]),
                                                                          },
                                                                        ),
                                                                      },
                                                                    );
                                                                  });
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .clearSnackBars();
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content:
                                                                          Text(
                                                                        'You  have successfully made a Friend!',
                                                                        style: AppTheme.of(context)
                                                                            .titleMedium
                                                                            .override(
                                                                              font: GoogleFonts.outfit(
                                                                                fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                                                                fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                                                                              ),
                                                                              color: AppTheme.of(context).primaryBtnText,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                                                              fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                                                                            ),
                                                                      ),
                                                                      duration: Duration(
                                                                          milliseconds:
                                                                              1500),
                                                                      backgroundColor:
                                                                          AppTheme.of(context)
                                                                              .primary,
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AppButtonEnhanced(
                                                                onPressed:
                                                                    () async {
                                                                  try {
                                                                    await currentUserReference!
                                                                        .update({
                                                                      ...mapToFirestore(
                                                                        {
                                                                          'friend_requests':
                                                                              FieldValue.arrayRemove([
                                                                            userList5UsersRecord
                                                                                .reference,
                                                                            userList5UsersRecord
                                                                                .reference
                                                                                .id
                                                                          ]),
                                                                        },
                                                                      ),
                                                                    });
                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(
                                                                            'Request denied.',
                                                                            style: AppTheme.of(context)
                                                                                .titleMedium
                                                                                .override(
                                                                                  font: GoogleFonts.outfit(
                                                                                    fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                                                                    fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                                                                                  ),
                                                                                  color: AppTheme.of(context).primaryBtnText,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                                                                  fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                                                                                ),
                                                                          ),
                                                                          duration: Duration(
                                                                              milliseconds:
                                                                                  1500),
                                                                          backgroundColor:
                                                                              AppTheme.of(context)
                                                                                  .primary,
                                                                        ),
                                                                      );
                                                                    }
                                                                  } catch (e) {
                                                                    print(
                                                                      'Deny request failed: $e',
                                                                    );
                                                                    if (mounted) {
                                                                      showSnackbar(
                                                                        context,
                                                                        'Unable to deny request. Please try again.',
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                                text: 'Deny',
                                                                variant:
                                                                    AppButtonVariant
                                                                        .secondary,
                                                                size: AppButtonSize
                                                                    .small,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          KeepAliveWidgetWrapper(
                            builder: (context) => Container(
                              width: double.infinity,
                              height: double.infinity,
                              constraints: BoxConstraints(
                                minWidth: double.infinity,
                                minHeight: double.infinity,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.of(context)
                                    .secondaryBackground,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: Image.asset(
                                    'assets/images/igdownloader.com_2980395830822133751.jpg',
                                  ).image,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AuthUserStreamWidget(
                                      builder: (context) => Builder(
                                        builder: (context) {
                                          final friendsList =
                                              (currentUserDocument?.friends
                                                          .toList() ??
                                                      [])
                                                  .toList();

                                          return ListView.separated(
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              12.0,
                                              0,
                                              44.0,
                                            ),
                                            primary: false,
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount: friendsList.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: AppSpacing.sm),
                                            itemBuilder:
                                                (context, friendsListIndex) {
                                              final friendsListItem =
                                                  friendsList[friendsListIndex];
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                                                child:
                                                    StreamBuilder<UsersRecord>(
                                                  stream:
                                                      UsersRecord.getDocument(
                                                          friendsListItem),
                                                  builder: (context, snapshot) {
                                                    // Customize what your widget looks like when it's loading.
                                                    if (!snapshot.hasData) {
                                                      return Center(
                                                        child: SizedBox(
                                                          width: 50.0,
                                                          height: 50.0,
                                                          child:
                                                              SpinKitWanderingCubes(
                                                            color: Color(
                                                                0xFF25504F),
                                                            size: 50.0,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    final userList5UsersRecord =
                                                        snapshot.data!;

                                                    return Container(
                                                      width: double.infinity,
                                                      height: 60.0,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            blurRadius: 4.0,
                                                            color: Color(
                                                                0x32000000),
                                                            offset: Offset(
                                                              0.0,
                                                              2.0,
                                                            ),
                                                          )
                                                        ],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    8.0,
                                                                    0.0,
                                                                    8.0,
                                                                    0.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceAround,
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          26.0),
                                                              child:
                                                                  Image.network(
                                                                valueOrDefault<
                                                                    String>(
                                                                  userList5UsersRecord
                                                                      .photoUrl,
                                                                  'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                                ),
                                                                width: 36.0,
                                                                height: 36.0,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            12.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .max,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      children: [
                                                                        Text(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            userList5UsersRecord.displayName,
                                                                            'name',
                                                                          ),
                                                                          style: AppTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.outfit(
                                                                                  fontWeight: FontWeight.w500,
                                                                                  fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                                fontSize: 16.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.w500,
                                                                                fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          AppSpacing.xs,
                                                                          0.0),
                                                              child:
                                                                  AppButtonEnhanced(
                                                                onPressed:
                                                                    () async {
                                                                  Navigator.of(context)
                                                                      .push(
                                                                    MaterialPageRoute(
                                                                      builder: (context) =>
                                                                          ProfileUserFirebaseWidget(
                                                                        userRef:
                                                                            userList5UsersRecord.reference,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                text: 'View',
                                                                variant: AppButtonVariant.primary,
                                                                size: AppButtonSize.small,
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AppIconButton(
                                                                borderColor:
                                                                    AppTheme.of(
                                                                            context)
                                                                        .primary,
                                                                borderRadius:
                                                                    20.0,
                                                                borderWidth:
                                                                    1.0,
                                                                buttonSize:
                                                                    40.0,
                                                                fillColor: Color(
                                                                    0xFF253551),
                                                                icon: FaIcon(
                                                                  FontAwesomeIcons
                                                                      .minus,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 18.0,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .runTransaction(
                                                                          (transaction) async {
                                                                    transaction
                                                                        .update(
                                                                      currentUserReference!,
                                                                      {
                                                                        ...mapToFirestore(
                                                                          {
                                                                            'friends':
                                                                                FieldValue.arrayRemove([
                                                                              userList5UsersRecord.reference
                                                                            ]),
                                                                          },
                                                                        ),
                                                                      },
                                                                    );
                                                                    transaction
                                                                        .update(
                                                                      userList5UsersRecord
                                                                          .reference,
                                                                      {
                                                                        ...mapToFirestore(
                                                                          {
                                                                            'friends':
                                                                                FieldValue.arrayRemove([
                                                                              currentUserReference
                                                                            ]),
                                                                          },
                                                                        ),
                                                                      },
                                                                    );
                                                                  });
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .clearSnackBars();
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content:
                                                                          Text(
                                                                        'You don\'t like this person and now they know',
                                                                        style: AppTheme.of(context)
                                                                            .titleMedium
                                                                            .override(
                                                                              font: GoogleFonts.outfit(
                                                                                fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                                                                fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                                                                              ),
                                                                              color: AppTheme.of(context).primaryBtnText,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                                                              fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                                                                            ),
                                                                      ),
                                                                      duration: Duration(
                                                                          milliseconds:
                                                                              1500),
                                                                      backgroundColor:
                                                                          AppTheme.of(context)
                                                                              .primary,
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                focusColor: Colors
                                                                    .transparent,
                                                                hoverColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onDoubleTap:
                                                                    () async {
                                                                  await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (alertDialogContext) {
                                                                      return AlertDialog(
                                                                        title: Text(
                                                                            currentUserReference!.id),
                                                                        content: Text(userList5UsersRecord
                                                                            .reference
                                                                            .id),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed: () =>
                                                                                Navigator.pop(alertDialogContext),
                                                                            child:
                                                                                Text('Ok'),
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                                child:
                                                                    AppIconButton(
                                                                  borderColor:
                                                                      AppTheme.of(
                                                                              context)
                                                                          .primary,
                                                                  borderRadius:
                                                                      20.0,
                                                                  borderWidth:
                                                                      1.0,
                                                                  buttonSize:
                                                                      40.0,
                                                                  fillColor: Color(
                                                                      0xFF253551),
                                                                  icon: FaIcon(
                                                                    FontAwesomeIcons
                                                                        .facebookMessenger,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 18.0,
                                                                  ),
                                                                  onPressed:
                                                                      () async {
                                                                    await _openDirectChat(
                                                                        userList5UsersRecord);
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
