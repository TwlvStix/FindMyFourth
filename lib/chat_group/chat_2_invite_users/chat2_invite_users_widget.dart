import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/chat_group/empty_state_simple/empty_state_simple_widget.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/design_tokens/spacing.dart';
import '/core/widgets/fairway_background.dart';
import '/core/random_data_util.dart' as random_data;
import '/chat_group/chat_2_details/chat2_details_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class Chat2InviteUsersWidget extends StatefulWidget {
  const Chat2InviteUsersWidget({
    super.key,
    this.chatRef,
  });

  final ChatsRecord? chatRef;

  static String routeName = 'chat_2_InviteUsers';
  static String routePath = '/chat2InviteUsers';

  @override
  State<Chat2InviteUsersWidget> createState() => _Chat2InviteUsersWidgetState();
}

class _Chat2InviteUsersWidgetState extends State<Chat2InviteUsersWidget> {
  List<DocumentReference> friendsList = [];
  void addToFriendsList(DocumentReference item) => friendsList.add(item);
  void removeFromFriendsList(DocumentReference item) =>
      friendsList.remove(item);
  void removeAtIndexFromFriendsList(int index) => friendsList.removeAt(index);
  void insertAtIndexInFriendsList(int index, DocumentReference item) =>
      friendsList.insert(index, item);
  void updateFriendsListAtIndex(
          int index, Function(DocumentReference) updateFn) =>
      friendsList[index] = updateFn(friendsList[index]);

  PagingController<DocumentSnapshot?, UsersRecord>? listViewPagingController;
  Query? listViewPagingQuery;
  Map<UsersRecord, bool> checkboxListTileValueMap = {};
  List<UsersRecord> get checkboxListTileCheckedItems =>
      checkboxListTileValueMap.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

  ChatsRecord? updatedChatThread;
  ChatsRecord? newChatThread;

  PagingController<DocumentSnapshot?, UsersRecord> setListViewController(
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    listViewPagingController ??= _createListViewController(query, parent);
    if (listViewPagingQuery != query) {
      listViewPagingQuery = query;
      listViewPagingController?.refresh();
    }
    return listViewPagingController!;
  }

  PagingController<DocumentSnapshot?, UsersRecord> _createListViewController(
    Query query,
    DocumentReference<Object?>? parent,
  ) {
    final controller =
        PagingController<DocumentSnapshot?, UsersRecord>(firstPageKey: null);
    return controller
      ..addPageRequestListener(
        (nextPageMarker) => queryUsersRecordPage(
          queryBuilder: (_) => listViewPagingQuery ??= query,
          nextPageMarker: nextPageMarker,
          controller: controller,
          pageSize: 16,
          isStream: false,
        ),
      );
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.chatRef != null) {
        // addChatUsers_ToList
        friendsList =
            widget.chatRef!.users.toList().cast<DocumentReference>();
        if (mounted) setState(() {});
      } else {
        // addUser_ToList
        addToFriendsList(currentUserReference!);
        if (mounted) setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    listViewPagingController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: FairwayBackgroundLight(
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite to Chat',
                style: AppTheme.of(context).headlineSmall.override(
                      font: GoogleFonts.outfit(
                        fontWeight: AppTheme.of(context)
                            .headlineSmall
                            .fontWeight,
                        fontStyle: AppTheme.of(context)
                            .headlineSmall
                            .fontStyle,
                      ),
                      color: AppTheme.of(context).primary,
                      letterSpacing: 0.0,
                      fontWeight:
                          AppTheme.of(context).headlineSmall.fontWeight,
                      fontStyle:
                          AppTheme.of(context).headlineSmall.fontStyle,
                    ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, AppSpacing.xxs, 0.0, 0.0),
                child: Text(
                  'Select users from below to start a chat.',
                  style: AppTheme.of(context).labelSmall.override(
                        font: GoogleFonts.outfit(
                          fontWeight: AppTheme.of(context)
                              .labelSmall
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).labelSmall.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).labelSmall.fontWeight,
                        fontStyle:
                            AppTheme.of(context).labelSmall.fontStyle,
                      ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, AppSpacing.xs, AppSpacing.sm, AppSpacing.xxs),
              child: AppIconButton(
                borderColor: AppTheme.of(context).alternate,
                borderRadius: 12.0,
                borderWidth: 1.0,
                buttonSize: 44.0,
                fillColor: AppTheme.of(context).secondaryBackground,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppTheme.of(context).secondaryText,
                  size: 24.0,
                ),
                onPressed: () async {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go('/');
                  }
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, AppSpacing.md, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              AppSpacing.md, AppSpacing.sm, 0.0, 0.0),
                          child: Text(
                            'Invite Players',
                            style: AppTheme.of(context)
                                .labelMedium
                                .override(
                                  font: GoogleFonts.outfit(
                                    fontWeight: AppTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: AppTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: AppTheme.of(context)
                                      .labelMedium
                                      .fontWeight,
                                  fontStyle: AppTheme.of(context)
                                      .labelMedium
                                      .fontStyle,
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.md, AppSpacing.sm, 0.0, 0.0),
                        child: Text(
                          ((valueOrDefault<int>(
                                    friendsList.length,
                                    0,
                                  ) -
                                  1))
                              .toString(),
                          style:
                              AppTheme.of(context).bodyMedium.override(
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
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(AppSpacing.xxs / 2, AppSpacing.sm, 0.0, 0.0),
                        child: Text(
                          'Selected',
                          style:
                              AppTheme.of(context).bodyMedium.override(
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
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, AppSpacing.sm, 0.0, 0.0),
                    child:
                        PagedListView<DocumentSnapshot<Object?>?, UsersRecord>(
                      pagingController: setListViewController(
                        UsersRecord.collection.orderBy('display_name'),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        160.0,
                      ),
                      reverse: false,
                      scrollDirection: Axis.vertical,
                      builderDelegate: PagedChildBuilderDelegate<UsersRecord>(
                        // Customize what your widget looks like when it's loading the first page.
                        firstPageProgressIndicatorBuilder: (_) => Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: SpinKitWanderingCubes(
                              color: AppTheme.of(context).secondary,
                              size: 50.0,
                            ),
                          ),
                        ),
                        // Customize what your widget looks like when it's loading another page.
                        newPageProgressIndicatorBuilder: (_) => Center(
                          child: SizedBox(
                            width: 50.0,
                            height: 50.0,
                            child: SpinKitWanderingCubes(
                              color: AppTheme.of(context).secondary,
                              size: 50.0,
                            ),
                          ),
                        ),
                        noItemsFoundIndicatorBuilder: (_) =>
                            EmptyStateSimpleWidget(
                          icon: Icon(
                            Icons.groups_outlined,
                            color: AppTheme.of(context).primary,
                            size: 90.0,
                          ),
                          title: 'No Friends',
                          body: 'No users exist to create a chat with.',
                        ),
                        itemBuilder: (context, _, listViewIndex) {
                          final listViewUsersRecord = listViewPagingController!
                              .itemList![listViewIndex];
                          return Visibility(
                            visible: listViewUsersRecord.reference !=
                                currentUserReference,
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  AppSpacing.md, 0.0, AppSpacing.md, AppSpacing.xs),
                              child: Container(
                                width: 100.0,
                                height: 70.0,
                                decoration: BoxDecoration(
                                  color: friendsList.contains(
                                          listViewUsersRecord.reference)
                                      ? AppTheme.of(context).accent1
                                      : AppTheme.of(context)
                                          .secondaryBackground,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: friendsList.contains(
                                            listViewUsersRecord.reference)
                                        ? AppTheme.of(context).primary
                                        : AppTheme.of(context)
                                            .alternate,
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          AppSpacing.sm, 0.0, 0.0, 0.0),
                                      child: Container(
                                        width: 44.0,
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: AppTheme.of(context)
                                              .accent1,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          border: Border.all(
                                            color: AppTheme.of(context)
                                                .primary,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(2.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: CachedNetworkImage(
                                              fadeInDuration:
                                                  Duration(milliseconds: 200),
                                              fadeOutDuration:
                                                  Duration(milliseconds: 200),
                                              imageUrl: valueOrDefault<String>(
                                                listViewUsersRecord.photoUrl,
                                                'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                              ),
                                              width: 44.0,
                                              height: 44.0,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, error,
                                                      stackTrace) =>
                                                  Image.asset(
                                                'assets/images/error_image.png',
                                                width: 44.0,
                                                height: 44.0,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor:
                                                AppTheme.of(context)
                                                    .secondaryText,
                                          ),
                                          child: CheckboxListTile(
                                            value:
                                                checkboxListTileValueMap[
                                                        listViewUsersRecord] ??=
                                                    friendsList.contains(
                                                            listViewUsersRecord
                                                                .reference) ==
                                                        true,
                                            onChanged: (newValue) async {
                                              if (mounted) setState(() =>
                                                  checkboxListTileValueMap[
                                                          listViewUsersRecord] =
                                                      newValue!);
                                              if (newValue!) {
                                                // addUser
                                                addToFriendsList(
                                                    listViewUsersRecord
                                                        .reference);
                                                if (mounted) setState(() {});
                                              } else {
                                                // removeUsser
                                                removeFromFriendsList(
                                                    listViewUsersRecord
                                                        .reference);
                                                if (mounted) setState(() {});
                                              }
                                            },
                                            title: Text(
                                              valueOrDefault<String>(
                                                listViewUsersRecord.displayName,
                                                'Ghost User',
                                              ),
                                              style:
                                                  AppTheme.of(context)
                                                      .bodyLarge
                                                      .override(
                                                        font:
                                                            GoogleFonts.outfit(
                                                          fontWeight:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            AppTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            AppTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                        lineHeight: 2.0,
                                                      ),
                                            ),
                                            subtitle: Text(
                                              valueOrDefault<String>(
                                                listViewUsersRecord.email,
                                                'casper@ghost.io',
                                              ),
                                              style: AppTheme.of(
                                                      context)
                                                  .labelSmall
                                                  .override(
                                                    font: GoogleFonts.outfit(
                                                      fontWeight:
                                                          AppTheme.of(
                                                                  context)
                                                              .labelSmall
                                                              .fontWeight,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .labelSmall
                                                              .fontStyle,
                                                    ),
                                                    color: AppTheme.of(
                                                            context)
                                                        .secondary,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        AppTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                            tileColor:
                                                AppTheme.of(context)
                                                    .secondaryBackground,
                                            activeColor:
                                                AppTheme.of(context)
                                                    .primary,
                                            checkColor: Colors.white,
                                            dense: false,
                                            controlAffinity:
                                                ListTileControlAffinity
                                                    .trailing,
                                            contentPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    AppSpacing.sm, 0.0, AppSpacing.xs, 0.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                        ),
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
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Container(
                width: double.infinity,
                height: 140.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.of(context).accent4,
                      AppTheme.of(context).secondaryBackground
                    ],
                    stops: [0.0, 1.0],
                    begin: AlignmentDirectional(0.0, -1.0),
                    end: AlignmentDirectional(0, 1.0),
                  ),
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(AppSpacing.md, 0.0, AppSpacing.md, 0.0),
                  child: AppButtonEnhanced(
                    text: widget.chatRef != null
                        ? 'Add to Chat'
                        : 'Start to Chat',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    onPressed: () async {
                      if (friendsList.length >= 2) {
                        if (widget.chatRef != null) {
                          // updateChat

                          await widget.chatRef!.reference.update({
                            ...mapToFirestore(
                              {
                                'users': friendsList,
                              },
                            ),
                          });
                          // updateChat
                          updatedChatThread = await queryChatsRecordOnce(
                            queryBuilder: (chatsRecord) => chatsRecord.where(
                              'group_chat_id',
                              isEqualTo: widget.chatRef?.groupChatId,
                            ),
                            singleRecord: true,
                          ).then((s) => s.firstOrNull);
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                          }
                          context.pushNamed(
                            Chat2DetailsWidget.routeName,
                            queryParameters: {
                              'chatRef': serializeParam(
                                updatedChatThread,
                                ParamType.Document,
                              ),
                            }.withoutNulls,
                            extra: <String, dynamic>{
                              'chatRef': updatedChatThread,
                            },
                          );
                        } else {
                          // newChat

                          var chatsRecordReference =
                              ChatsRecord.collection.doc();
                          await chatsRecordReference.set({
                            ...createChatsRecordData(
                              userA: currentUserReference,
                              userB: friendsList.elementAtOrNull(1),
                              lastMessage: '',
                              lastMessageTime: getCurrentTimestamp,
                              lastMessageSentBy: currentUserReference,
                              groupChatId:
                                  random_data.randomInteger(1000000, 9999999),
                            ),
                            ...mapToFirestore(
                              {
                                'users': friendsList,
                              },
                            ),
                          });
                          newChatThread =
                              ChatsRecord.getDocumentFromData({
                            ...createChatsRecordData(
                              userA: currentUserReference,
                              userB: friendsList.elementAtOrNull(1),
                              lastMessage: '',
                              lastMessageTime: getCurrentTimestamp,
                              lastMessageSentBy: currentUserReference,
                              groupChatId:
                                  random_data.randomInteger(1000000, 9999999),
                            ),
                            ...mapToFirestore(
                              {
                                'users': friendsList,
                              },
                            ),
                          }, chatsRecordReference);
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                          }
                          context.pushNamed(
                            Chat2DetailsWidget.routeName,
                            queryParameters: {
                              'chatRef': serializeParam(
                                newChatThread,
                                ParamType.Document,
                              ),
                            }.withoutNulls,
                            extra: <String, dynamic>{
                              'chatRef': newChatThread,
                            },
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You must select at least one other user to start a chat.',
                              style: AppTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: AppTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: AppTheme.of(context).info,
                                    letterSpacing: 0.0,
                                    fontWeight: AppTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: AppTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                            ),
                            duration: Duration(milliseconds: 3000),
                            backgroundColor:
                                AppTheme.of(context).primary,
                          ),
                        );
                      }

                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
