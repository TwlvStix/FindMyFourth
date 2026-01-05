import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/autocomplete_options_list.dart';
import '/core/button_tabbar.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/core/widgets/app_button.dart';
import '/core/random_data_util.dart' as random_data;
import '/chat_group/chat_2_details/chat2_details_widget.dart';
import '/profile/profile_user/profile_user_widget.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
  ChatsRecord? chatsChecker;
  ChatsRecord? chatsChecker2;
  ChatsRecord? chatroomReference;
  ChatsRecord? chatroomChecker;
  ChatsRecord? chatroomChecker2;
  ChatsRecord? chatroomReference2;

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
        body: SafeArea(
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
                            12.0, 0.0, 12.0, 0.0),
                        buttonMargin:
                            EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                        padding: EdgeInsets.all(4.0),
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
                                          16.0, 8.0, 16.0, 12.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(8.0, 0.0, 8.0, 0.0),
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
                                                    12.0, 0.0, 0.0, 0.0),
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
                                                print('IconButton pressed ...');
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          24.0, 0.0, 0.0, 0.0),
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
                                      stream: queryUsersRecord(),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: SpinKitWanderingCubes(
                                                color: Color(0xFF25504F),
                                                size: 50.0,
                                              ),
                                            ),
                                          );
                                        }
                                        List<UsersRecord>
                                            listViewUsersRecordList = snapshot
                                                .data!
                                                .where((u) =>
                                                    u.uid != currentUserUid)
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
                                          itemCount:
                                              listViewUsersRecordList.length,
                                          separatorBuilder: (_, __) =>
                                              SizedBox(height: 12.0),
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
                                                                    10.0,
                                                                    0.0),
                                                        child: AppButton(
                                                          onPressed: () async {
                                                            context.pushNamed(
                                                              ProfileUserWidget
                                                                  .routeName,
                                                              queryParameters: {
                                                                'userRef':
                                                                    serializeParam(
                                                                  listViewUsersRecord,
                                                                  ParamType
                                                                      .Document,
                                                                ),
                                                              }.withoutNulls,
                                                              extra: <String,
                                                                  dynamic>{
                                                                'userRef':
                                                                    listViewUsersRecord,
                                                                kTransitionInfoKey:
                                                                    TransitionInfo(
                                                                  hasTransition:
                                                                      true,
                                                                  transitionType:
                                                                      PageTransitionType
                                                                          .bottomToTop,
                                                                  duration: Duration(
                                                                      milliseconds:
                                                                          220),
                                                                ),
                                                              },
                                                            );
                                                          },
                                                          text: 'View',
                                                          options:
                                                              AppButtonOptions(
                                                            width: 51.0,
                                                            height: 36.0,
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            iconPadding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        0.0),
                                                            color: Color(
                                                                0xFF253551),
                                                            textStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .outfit(
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontStyle: AppTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                            elevation: 2.0,
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .transparent,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0),
                                                          ),
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
                                                              Color(0xFF253551),
                                                          icon: FaIcon(
                                                            FontAwesomeIcons
                                                                .facebookMessenger,
                                                            color: Colors.white,
                                                            size: 18.0,
                                                          ),
                                                          onPressed: () async {
                                                            addToFriendList(
                                                                currentUserReference!);
                                                            if (mounted) setState(() {});
                                                            addToFriendList(
                                                                listViewUsersRecord
                                                                    .reference);
                                                            if (mounted) setState(() {});
                                                            chatsChecker =
                                                                await queryChatsRecordOnce(
                                                              queryBuilder:
                                                                  (chatsRecord) =>
                                                                      chatsRecord
                                                                          .where(
                                                                            'user_a',
                                                                            isEqualTo:
                                                                                currentUserReference,
                                                                          )
                                                                          .where(
                                                                            'user_b',
                                                                            isEqualTo:
                                                                                listViewUsersRecord.reference,
                                                                          ),
                                                              singleRecord:
                                                                  true,
                                                            ).then((s) => s
                                                                    .firstOrNull);
                                                            if (chatsChecker !=
                                                                null) {
                                                              if (Navigator.of(
                                                                      context)
                                                                  .canPop()) {
                                                                context.pop();
                                                              }
                                                              context.pushNamed(
                                                                Chat2DetailsWidget
                                                                    .routeName,
                                                                queryParameters:
                                                                    {
                                                                  'chatRef':
                                                                      serializeParam(
                                                                    chatsChecker,
                                                                    ParamType
                                                                        .Document,
                                                                  ),
                                                                }.withoutNulls,
                                                                extra: <String,
                                                                    dynamic>{
                                                                  'chatRef':
                                                                      chatsChecker,
                                                                },
                                                              );
                                                            } else {
                                                              chatsChecker2 =
                                                                  await queryChatsRecordOnce(
                                                                queryBuilder:
                                                                    (chatsRecord) =>
                                                                        chatsRecord
                                                                            .where(
                                                                              'user_a',
                                                                              isEqualTo: listViewUsersRecord.reference,
                                                                            )
                                                                            .where(
                                                                              'user_b',
                                                                              isEqualTo: currentUserReference,
                                                                            ),
                                                                singleRecord:
                                                                    true,
                                                              ).then((s) => s
                                                                      .firstOrNull);
                                                              if (chatsChecker2 !=
                                                                  null) {
                                                                if (Navigator.of(
                                                                        context)
                                                                    .canPop()) {
                                                                  context.pop();
                                                                }
                                                                context
                                                                    .pushNamed(
                                                                  Chat2DetailsWidget
                                                                      .routeName,
                                                                  queryParameters:
                                                                      {
                                                                    'chatRef':
                                                                        serializeParam(
                                                                      chatsChecker2,
                                                                      ParamType
                                                                          .Document,
                                                                    ),
                                                                  }.withoutNulls,
                                                                  extra: <String,
                                                                      dynamic>{
                                                                    'chatRef':
                                                                        chatsChecker2,
                                                                  },
                                                                );
                                                              } else {
                                                                // newChat

                                                                var chatsRecordReference =
                                                                    ChatsRecord
                                                                        .collection
                                                                        .doc();
                                                                await chatsRecordReference
                                                                    .set({
                                                                  ...createChatsRecordData(
                                                                    userA:
                                                                        currentUserReference,
                                                                    userB: listViewUsersRecord
                                                                        .reference,
                                                                    lastMessage:
                                                                        '',
                                                                    lastMessageTime:
                                                                        getCurrentTimestamp,
                                                                    lastMessageSentBy:
                                                                        currentUserReference,
                                                                    groupChatId:
                                                                        random_data.randomInteger(
                                                                            1000000,
                                                                            9999999),
                                                                  ),
                                                                  ...mapToFirestore(
                                                                    {
                                                                      'users':
                                                                          friendList,
                                                                    },
                                                                  ),
                                                                });
                                                                chatroomReference =
                                                                    ChatsRecord
                                                                        .getDocumentFromData({
                                                                  ...createChatsRecordData(
                                                                    userA:
                                                                        currentUserReference,
                                                                    userB: listViewUsersRecord
                                                                        .reference,
                                                                    lastMessage:
                                                                        '',
                                                                    lastMessageTime:
                                                                        getCurrentTimestamp,
                                                                    lastMessageSentBy:
                                                                        currentUserReference,
                                                                    groupChatId:
                                                                        random_data.randomInteger(
                                                                            1000000,
                                                                            9999999),
                                                                  ),
                                                                  ...mapToFirestore(
                                                                    {
                                                                      'users':
                                                                          friendList,
                                                                    },
                                                                  ),
                                                                }, chatsRecordReference);
                                                                if (Navigator.of(
                                                                        context)
                                                                    .canPop()) {
                                                                  context.pop();
                                                                }
                                                                context
                                                                    .pushNamed(
                                                                  Chat2DetailsWidget
                                                                      .routeName,
                                                                  queryParameters:
                                                                      {
                                                                    'chatRef':
                                                                        serializeParam(
                                                                      chatroomReference,
                                                                      ParamType
                                                                          .Document,
                                                                    ),
                                                                  }.withoutNulls,
                                                                  extra: <String,
                                                                      dynamic>{
                                                                    'chatRef':
                                                                        chatroomReference,
                                                                  },
                                                                );
                                                              }
                                                            }

                                                            if (mounted) setState(() {});
                                                          },
                                                        ),
                                                      ),
                                                      Stack(
                                                        children: [
                                                          if (listViewUsersRecord
                                                                  .friendRequests
                                                                  .contains(
                                                                      currentUserReference) ||
                                                              (currentUserDocument
                                                                          ?.friendRequests
                                                                          .toList() ??
                                                                      [])
                                                                  .contains(
                                                                      listViewUsersRecord
                                                                          .reference))
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          5.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AuthUserStreamWidget(
                                                                builder:
                                                                    (context) =>
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
                                                              ),
                                                            ),
                                                          if (!listViewUsersRecord
                                                                  .friendRequests
                                                                  .contains(
                                                                      currentUserReference) &&
                                                              !(currentUserDocument
                                                                          ?.friendRequests
                                                                          .toList() ??
                                                                      [])
                                                                  .contains(
                                                                      listViewUsersRecord
                                                                          .reference))
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          5.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AuthUserStreamWidget(
                                                                builder:
                                                                    (context) =>
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
                                                                    Icons.add,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 18.0,
                                                                  ),
                                                                  onPressed:
                                                                      () async {
                                                                    await listViewUsersRecord
                                                                        .reference
                                                                        .update({
                                                                      ...mapToFirestore(
                                                                        {
                                                                          'friend_requests':
                                                                              FieldValue.arrayUnion([
                                                                            currentUserReference
                                                                          ]),
                                                                        },
                                                                      ),
                                                                    });
                                                                    addToReqUserList(
                                                                        valueOrDefault<
                                                                            String>(
                                                                      listViewUsersRecord
                                                                          .uid,
                                                                      '007',
                                                                    ));
                                                                    if (mounted) setState(
                                                                        () {});
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
                                                              ),
                                                            ),
                                                          if ((currentUserDocument
                                                                      ?.friends
                                                                      .toList() ??
                                                                  [])
                                                              .contains(
                                                                  listViewUsersRecord
                                                                      .reference))
                                                            Padding(
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          5.0,
                                                                          0.0,
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AuthUserStreamWidget(
                                                                builder:
                                                                    (context) =>
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
                                                                    Icons
                                                                        .people,
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
                                                              ),
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
                                    if (isiOS)
                                      StreamBuilder<List<FriendRequestRecord>>(
                                        stream: queryFriendRequestRecord(
                                          queryBuilder: (friendRequestRecord) =>
                                              friendRequestRecord.where(
                                            'receiver_id',
                                            isEqualTo: currentUserReference,
                                          ),
                                        ),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return Center(
                                              child: SizedBox(
                                                width: 50.0,
                                                height: 50.0,
                                                child: SpinKitWanderingCubes(
                                                  color: Color(0xFF25504F),
                                                  size: 50.0,
                                                ),
                                              ),
                                            );
                                          }
                                          List<FriendRequestRecord>
                                              listViewFriendRequestRecordList =
                                              snapshot.data!;
                                          if (listViewFriendRequestRecordList
                                              .isEmpty) {
                                            return Image.asset(
                                              'assets/images/Whitefixed.png',
                                            );
                                          }

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
                                            itemCount:
                                                listViewFriendRequestRecordList
                                                    .length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 12.0),
                                            itemBuilder:
                                                (context, listViewIndex) {
                                              final listViewFriendRequestRecord =
                                                  listViewFriendRequestRecordList[
                                                      listViewIndex];
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 12.0, 16.0, 12.0),
                                                child:
                                                    StreamBuilder<UsersRecord>(
                                                  stream: UsersRecord.getDocument(
                                                      listViewFriendRequestRecord
                                                          .requesterId!),
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
                                                                userList5UsersRecord
                                                                    .photoUrl,
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
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AppButton(
                                                                onPressed:
                                                                    () async {
                                                                  context
                                                                      .pushNamed(
                                                                    ProfileUserWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'userRef':
                                                                          serializeParam(
                                                                        userList5UsersRecord,
                                                                        ParamType
                                                                            .Document,
                                                                      ),
                                                                    }.withoutNulls,
                                                                    extra: <String,
                                                                        dynamic>{
                                                                      'userRef':
                                                                          userList5UsersRecord,
                                                                      kTransitionInfoKey:
                                                                          TransitionInfo(
                                                                        hasTransition:
                                                                            true,
                                                                        transitionType:
                                                                            PageTransitionType.bottomToTop,
                                                                        duration:
                                                                            Duration(milliseconds: 220),
                                                                      ),
                                                                    },
                                                                  );
                                                                },
                                                                text: 'View',
                                                                options:
                                                                    AppButtonOptions(
                                                                  width: 51.0,
                                                                  height: 36.0,
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  iconPadding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  color: Color(
                                                                      0xFF253551),
                                                                  textStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          fontStyle: AppTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            14.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                  elevation:
                                                                      2.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1.0,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.0),
                                                                ),
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
                                                                  await currentUserReference!
                                                                      .update({
                                                                    ...mapToFirestore(
                                                                      {
                                                                        'friends':
                                                                            FieldValue.arrayUnion([
                                                                          userList5UsersRecord
                                                                              .reference
                                                                        ]),
                                                                      },
                                                                    ),
                                                                  });
                                                                  await listViewFriendRequestRecord
                                                                      .reference
                                                                      .delete();
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
                                                                  Icons
                                                                      .not_interested,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 18.0,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  await listViewFriendRequestRecord
                                                                      .reference
                                                                      .delete();
                                                                },
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
                                    AuthUserStreamWidget(
                                      builder: (context) => Builder(
                                        builder: (context) {
                                          final friendRequestList =
                                              (currentUserDocument
                                                          ?.friendRequests
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
                                            itemCount: friendRequestList.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 12.0),
                                            itemBuilder: (context,
                                                friendRequestListIndex) {
                                              final friendRequestListItem =
                                                  friendRequestList[
                                                      friendRequestListIndex];
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 12.0, 16.0, 12.0),
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
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AppButton(
                                                                onPressed:
                                                                    () async {
                                                                  context
                                                                      .pushNamed(
                                                                    ProfileUserWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'userRef':
                                                                          serializeParam(
                                                                        userList5UsersRecord,
                                                                        ParamType
                                                                            .Document,
                                                                      ),
                                                                    }.withoutNulls,
                                                                    extra: <String,
                                                                        dynamic>{
                                                                      'userRef':
                                                                          userList5UsersRecord,
                                                                      kTransitionInfoKey:
                                                                          TransitionInfo(
                                                                        hasTransition:
                                                                            true,
                                                                        transitionType:
                                                                            PageTransitionType.bottomToTop,
                                                                        duration:
                                                                            Duration(milliseconds: 220),
                                                                      ),
                                                                    },
                                                                  );
                                                                },
                                                                text: 'View',
                                                                options:
                                                                    AppButtonOptions(
                                                                  width: 51.0,
                                                                  height: 36.0,
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  iconPadding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  color: Color(
                                                                      0xFF253551),
                                                                  textStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          fontStyle: AppTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            14.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                  elevation:
                                                                      2.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1.0,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.0),
                                                                ),
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
                                                                  await currentUserReference!
                                                                      .update({
                                                                    ...mapToFirestore(
                                                                      {
                                                                        'friends':
                                                                            FieldValue.arrayUnion([
                                                                          userList5UsersRecord
                                                                              .reference
                                                                        ]),
                                                                        'friend_requests':
                                                                            FieldValue.arrayRemove([
                                                                          userList5UsersRecord
                                                                              .reference
                                                                        ]),
                                                                      },
                                                                    ),
                                                                  });

                                                                  await userList5UsersRecord
                                                                      .reference
                                                                      .update({
                                                                    ...mapToFirestore(
                                                                      {
                                                                        'friends':
                                                                            FieldValue.arrayUnion([
                                                                          currentUserReference
                                                                        ]),
                                                                      },
                                                                    ),
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
                                                                  Icons
                                                                      .not_interested,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 18.0,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  await currentUserReference!
                                                                      .update({
                                                                    ...mapToFirestore(
                                                                      {
                                                                        'friend_requests':
                                                                            FieldValue.arrayRemove([
                                                                          userList5UsersRecord
                                                                              .reference
                                                                        ]),
                                                                      },
                                                                    ),
                                                                  });
                                                                },
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
                                                SizedBox(height: 12.0),
                                            itemBuilder:
                                                (context, friendsListIndex) {
                                              final friendsListItem =
                                                  friendsList[friendsListIndex];
                                              return Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 12.0, 16.0, 12.0),
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
                                                                          5.0,
                                                                          0.0),
                                                              child:
                                                                  AppButton(
                                                                onPressed:
                                                                    () async {
                                                                  context
                                                                      .pushNamed(
                                                                    ProfileUserWidget
                                                                        .routeName,
                                                                    queryParameters:
                                                                        {
                                                                      'userRef':
                                                                          serializeParam(
                                                                        userList5UsersRecord,
                                                                        ParamType
                                                                            .Document,
                                                                      ),
                                                                    }.withoutNulls,
                                                                    extra: <String,
                                                                        dynamic>{
                                                                      'userRef':
                                                                          userList5UsersRecord,
                                                                      kTransitionInfoKey:
                                                                          TransitionInfo(
                                                                        hasTransition:
                                                                            true,
                                                                        transitionType:
                                                                            PageTransitionType.bottomToTop,
                                                                        duration:
                                                                            Duration(milliseconds: 220),
                                                                      ),
                                                                    },
                                                                  );
                                                                },
                                                                text: 'View',
                                                                options:
                                                                    AppButtonOptions(
                                                                  width: 51.0,
                                                                  height: 36.0,
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  iconPadding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                  color: Color(
                                                                      0xFF253551),
                                                                  textStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .outfit(
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          fontStyle: AppTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            14.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: AppTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                  elevation:
                                                                      2.0,
                                                                  borderSide:
                                                                      BorderSide(
                                                                    color: Colors
                                                                        .transparent,
                                                                    width: 1.0,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.0),
                                                                ),
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
                                                                  await currentUserReference!
                                                                      .update({
                                                                    ...mapToFirestore(
                                                                      {
                                                                        'friends':
                                                                            FieldValue.arrayRemove([
                                                                          userList5UsersRecord
                                                                              .reference
                                                                        ]),
                                                                      },
                                                                    ),
                                                                  });

                                                                  await userList5UsersRecord
                                                                      .reference
                                                                      .update({
                                                                    ...mapToFirestore(
                                                                      {
                                                                        'friends':
                                                                            FieldValue.arrayRemove([
                                                                          currentUserReference
                                                                        ]),
                                                                      },
                                                                    ),
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
                                                                    addToFriendList(
                                                                        userList5UsersRecord
                                                                            .reference);
                                                                    if (mounted) setState(
                                                                        () {});
                                                                    chatroomChecker =
                                                                        await queryChatsRecordOnce(
                                                                      queryBuilder: (chatsRecord) => chatsRecord
                                                                          .where(
                                                                            'user_a',
                                                                            isEqualTo:
                                                                                userList5UsersRecord.reference,
                                                                          )
                                                                          .where(
                                                                            'user_b',
                                                                            isEqualTo:
                                                                                currentUserReference,
                                                                          ),
                                                                      singleRecord:
                                                                          true,
                                                                    ).then((s) =>
                                                                            s.firstOrNull);
                                                                    if (chatroomChecker !=
                                                                        null) {
                                                                      if (Navigator.of(
                                                                              context)
                                                                          .canPop()) {
                                                                        context
                                                                            .pop();
                                                                      }
                                                                      context
                                                                          .pushNamed(
                                                                        Chat2DetailsWidget
                                                                            .routeName,
                                                                        queryParameters:
                                                                            {
                                                                          'chatRef':
                                                                              serializeParam(
                                                                            chatroomChecker,
                                                                            ParamType.Document,
                                                                          ),
                                                                        }.withoutNulls,
                                                                        extra: <String,
                                                                            dynamic>{
                                                                          'chatRef':
                                                                              chatroomChecker,
                                                                        },
                                                                      );
                                                                    } else {
                                                                      chatroomChecker2 =
                                                                          await queryChatsRecordOnce(
                                                                        queryBuilder: (chatsRecord) => chatsRecord
                                                                            .where(
                                                                              'user_a',
                                                                              isEqualTo: currentUserReference,
                                                                            )
                                                                            .where(
                                                                              'user_b',
                                                                              isEqualTo: currentUserReference,
                                                                            ),
                                                                        singleRecord:
                                                                            true,
                                                                      ).then((s) =>
                                                                              s.firstOrNull);
                                                                      if (chatroomChecker2 !=
                                                                          null) {
                                                                        if (Navigator.of(context)
                                                                            .canPop()) {
                                                                          context
                                                                              .pop();
                                                                        }
                                                                        context
                                                                            .pushNamed(
                                                                          Chat2DetailsWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'chatRef':
                                                                                serializeParam(
                                                                              chatroomChecker2,
                                                                              ParamType.Document,
                                                                            ),
                                                                          }.withoutNulls,
                                                                          extra: <String,
                                                                              dynamic>{
                                                                            'chatRef':
                                                                                chatroomChecker2,
                                                                          },
                                                                        );
                                                                      } else {
                                                                        // newChat

                                                                        var chatsRecordReference = ChatsRecord
                                                                            .collection
                                                                            .doc();
                                                                        await chatsRecordReference
                                                                            .set({
                                                                          ...createChatsRecordData(
                                                                            userA:
                                                                                currentUserReference,
                                                                            userB:
                                                                                userList5UsersRecord.reference,
                                                                            lastMessage:
                                                                                '',
                                                                            lastMessageTime:
                                                                                getCurrentTimestamp,
                                                                            lastMessageSentBy:
                                                                                currentUserReference,
                                                                            groupChatId:
                                                                                random_data.randomInteger(1000000, 9999999),
                                                                          ),
                                                                          ...mapToFirestore(
                                                                            {
                                                                              'users': friendList,
                                                                            },
                                                                          ),
                                                                        });
                                                                        chatroomReference2 =
                                                                            ChatsRecord.getDocumentFromData({
                                                                          ...createChatsRecordData(
                                                                            userA:
                                                                                currentUserReference,
                                                                            userB:
                                                                                userList5UsersRecord.reference,
                                                                            lastMessage:
                                                                                '',
                                                                            lastMessageTime:
                                                                                getCurrentTimestamp,
                                                                            lastMessageSentBy:
                                                                                currentUserReference,
                                                                            groupChatId:
                                                                                random_data.randomInteger(1000000, 9999999),
                                                                          ),
                                                                          ...mapToFirestore(
                                                                            {
                                                                              'users': friendList,
                                                                            },
                                                                          ),
                                                                        }, chatsRecordReference);
                                                                        if (Navigator.of(context)
                                                                            .canPop()) {
                                                                          context
                                                                              .pop();
                                                                        }
                                                                        context
                                                                            .pushNamed(
                                                                          Chat2DetailsWidget
                                                                              .routeName,
                                                                          queryParameters:
                                                                              {
                                                                            'chatRef':
                                                                                serializeParam(
                                                                              chatroomReference2,
                                                                              ParamType.Document,
                                                                            ),
                                                                          }.withoutNulls,
                                                                          extra: <String,
                                                                              dynamic>{
                                                                            'chatRef':
                                                                                chatroomReference2,
                                                                          },
                                                                        );

                                                                        await showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (alertDialogContext) {
                                                                            return AlertDialog(
                                                                              content: Text('Create chatroom'),
                                                                              actions: [
                                                                                TextButton(
                                                                                  onPressed: () => Navigator.pop(alertDialogContext),
                                                                                  child: Text('Ok'),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        );
                                                                      }
                                                                    }

                                                                    if (mounted) setState(
                                                                        () {});
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
    );
  }
}
