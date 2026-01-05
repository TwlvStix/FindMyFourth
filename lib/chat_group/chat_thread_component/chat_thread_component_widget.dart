import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/chat_group/chat_thread_update/chat_thread_update_widget.dart';
import '/chat_group/empty_state_simple/empty_state_simple_widget.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/media_display.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/core/video_player.dart';
import '/core/upload_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatThreadComponentWidget extends StatefulWidget {
  const ChatThreadComponentWidget({
    super.key,
    this.chatRef,
  });

  final ChatsRecord? chatRef;

  @override
  State<ChatThreadComponentWidget> createState() =>
      _ChatThreadComponentWidgetState();
}

class _ChatThreadComponentWidgetState extends State<ChatThreadComponentWidget> {
  List<DocumentReference> lastSeenBy = [];
  void addToLastSeenBy(DocumentReference item) => lastSeenBy.add(item);
  void removeFromLastSeenBy(DocumentReference item) =>
      lastSeenBy.remove(item);
  void removeAtIndexFromLastSeenBy(int index) => lastSeenBy.removeAt(index);
  void insertAtIndexInLastSeenBy(int index, DocumentReference item) =>
      lastSeenBy.insert(index, item);
  void updateLastSeenByAtIndex(
          int index, Function(DocumentReference) updateFn) =>
      lastSeenBy[index] = updateFn(lastSeenBy[index]);

  List<String> imagesUploaded = [];
  void addToImagesUploaded(String item) => imagesUploaded.add(item);
  void removeFromImagesUploaded(String item) => imagesUploaded.remove(item);
  void removeAtIndexFromImagesUploaded(int index) =>
      imagesUploaded.removeAt(index);
  void insertAtIndexInImagesUploaded(int index, String item) =>
      imagesUploaded.insert(index, item);
  void updateImagesUploadedAtIndex(int index, Function(String) updateFn) =>
      imagesUploaded[index] = updateFn(imagesUploaded[index]);

  final formKey = GlobalKey<FormState>();
  List<ChatMessagesRecord>? listViewPreviousSnapshot;
  bool isDataUploadingUploadDataJub4 = false;
  FFUploadedFile uploadedLocalFileUploadDataJub4 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrlUploadDataJub4 = '';

  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  ChatMessagesRecord? newChatMessage;
  ChatMessagesRecord? newChat;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    textFieldFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.of(context).primaryBackground,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessagesRecord>>(
              stream: queryChatMessagesRecord(
                queryBuilder: (chatMessagesRecord) => chatMessagesRecord
                    .where(
                      'chat',
                      isEqualTo: widget.chatRef?.reference,
                    )
                    .orderBy('timestamp', descending: true),
                limit: 200,
              )..listen((snapshot) {
                  List<ChatMessagesRecord> listViewChatMessagesRecordList =
                      snapshot;
                  if (listViewPreviousSnapshot != null &&
                      !const ListEquality(ChatMessagesRecordDocumentEquality())
                          .equals(listViewChatMessagesRecordList,
                              listViewPreviousSnapshot)) {
                    () async {
                      if (!widget.chatRef!.lastMessageSeenBy
                          .contains(currentUserReference)) {
                        await widget.chatRef!.reference.update({
                          ...mapToFirestore(
                            {
                              'last_message_seen_by':
                                  FieldValue.arrayUnion([currentUserReference]),
                            },
                          ),
                        });
                      }

                      if (mounted) setState(() {});
                    }();
                  }
                  listViewPreviousSnapshot = snapshot;
                }),
              builder: (context, snapshot) {
                // Customize what your widget looks like when it's loading.
                if (!snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 50.0,
                        height: 50.0,
                        child: SpinKitWanderingCubes(
                          color: Color(0xFF25504F),
                          size: 50.0,
                        ),
                      ),
                    ),
                  );
                }
                List<ChatMessagesRecord> listViewChatMessagesRecordList =
                    snapshot.data!;
                if (listViewChatMessagesRecordList.isEmpty) {
                  return EmptyStateSimpleWidget(
                    icon: Icon(
                      Icons.forum_outlined,
                      color: AppTheme.of(context).primary,
                      size: 90.0,
                    ),
                    title: 'No Messages',
                    body: 'You have not sent any messages in this chat yet.',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    12.0,
                    0,
                    24.0,
                  ),
                  reverse: true,
                  scrollDirection: Axis.vertical,
                  itemCount: listViewChatMessagesRecordList.length,
                  itemBuilder: (context, listViewIndex) {
                    final listViewChatMessagesRecord =
                        listViewChatMessagesRecordList[listViewIndex];
                    return Container(
                      decoration: BoxDecoration(),
                      child: ChatThreadUpdateWidget(
                        key: Key(
                          'Key0rl_${listViewChatMessagesRecord.reference.id}',
                        ),
                        chatMessagesRef: listViewChatMessagesRecord,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.of(context).secondaryBackground,
              boxShadow: [
                BoxShadow(
                  blurRadius: 3.0,
                  color: Color(0x33000000),
                  offset: Offset(
                    0.0,
                    -2.0,
                  ),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (uploadedFileUrlUploadDataJub4 != '')
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 12.0, 0.0, 0.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MediaDisplay(
                                  path: uploadedFileUrlUploadDataJub4,
                                  imageBuilder: (path) => ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: CachedNetworkImage(
                                      fadeInDuration:
                                          Duration(milliseconds: 500),
                                      fadeOutDuration:
                                          Duration(milliseconds: 500),
                                      imageUrl: path,
                                      width: 120.0,
                                      height: 100.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  videoPlayerBuilder: (path) =>
                                      AppVideoPlayer(
                                    path: path,
                                    width: 300.0,
                                    autoPlay: false,
                                    looping: true,
                                    showControls: true,
                                    allowFullScreen: true,
                                    allowPlaybackSpeedMenu: false,
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional(-1.0, -1.0),
                                  child: AppIconButton(
                                    borderColor:
                                        AppTheme.of(context).error,
                                    borderRadius: 20.0,
                                    borderWidth: 2.0,
                                    buttonSize: 40.0,
                                    fillColor: AppTheme.of(context)
                                        .primaryBackground,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppTheme.of(context).error,
                                      size: 24.0,
                                    ),
                                    onPressed: () async {
                                      if (mounted) setState(() {
                                        isDataUploadingUploadDataJub4 =
                                            false;
                                        uploadedLocalFileUploadDataJub4 =
                                            FFUploadedFile(
                                                bytes: Uint8List.fromList([]),
                                                originalFilename: '');
                                        uploadedFileUrlUploadDataJub4 =
                                            '';
                                      });
                                    },
                                  ),
                                ),
                              ]
                                  .divide(SizedBox(width: 8.0))
                                  .addToStart(SizedBox(width: 16.0))
                                  .addToEnd(SizedBox(width: 16.0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppIconButton(
                          borderColor: AppTheme.of(context).alternate,
                          borderRadius: 60.0,
                          borderWidth: 1.0,
                          buttonSize: 40.0,
                          fillColor:
                              AppTheme.of(context).secondaryBackground,
                          icon: Icon(
                            Icons.add_rounded,
                            color: AppTheme.of(context).secondaryText,
                            size: 24.0,
                          ),
                          onPressed: () async {
                            final selectedMedia =
                                await selectMediaWithSourceBottomSheet(
                              context: context,
                              allowPhoto: true,
                              allowVideo: true,
                              backgroundColor: AppTheme.of(context)
                                  .secondaryBackground,
                              textColor:
                                  AppTheme.of(context).primaryText,
                              pickerFontFamily: 'Outfit',
                            );
                            if (selectedMedia != null &&
                                selectedMedia.every((m) => validateFileFormat(
                                    m.storagePath, context))) {
                              if (mounted) setState(() =>
                                  isDataUploadingUploadDataJub4 = true);
                              var selectedUploadedFiles = <FFUploadedFile>[];

                              var downloadUrls = <String>[];
                              try {
                                showUploadMessage(
                                  context,
                                  'Uploading file...',
                                  showLoading: true,
                                );
                                selectedUploadedFiles = selectedMedia
                                    .map((m) => FFUploadedFile(
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
                                    (m) async => await uploadData(
                                        m.storagePath, m.bytes),
                                  ),
                                ))
                                    .where((u) => u != null)
                                    .map((u) => u!)
                                    .toList();
                              } finally {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                isDataUploadingUploadDataJub4 = false;
                              }
                              if (selectedUploadedFiles.length ==
                                      selectedMedia.length &&
                                  downloadUrls.length == selectedMedia.length) {
                                if (mounted) setState(() {
                                  uploadedLocalFileUploadDataJub4 =
                                      selectedUploadedFiles.first;
                                  uploadedFileUrlUploadDataJub4 =
                                      downloadUrls.first;
                                });
                                showUploadMessage(context, 'Success!');
                              } else {
                                if (mounted) setState(() {});
                                showUploadMessage(
                                    context, 'Failed to upload data');
                                return;
                              }
                            }

                            if (uploadedFileUrlUploadDataJub4 != '') {
                              addToImagesUploaded(
                                  uploadedFileUrlUploadDataJub4);
                              if (mounted) setState(() {});
                            }
                          },
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    8.0, 0.0, 0.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  child: TextFormField(
                                    controller: textController,
                                    focusNode: textFieldFocusNode,
                                    onFieldSubmitted: (_) async {
                                      if (formKey.currentState == null ||
                                          !formKey.currentState!
                                              .validate()) {
                                        return;
                                      }
                                      // newChatMessage

                                      var chatMessagesRecordReference =
                                          ChatMessagesRecord.collection.doc();
                                      await chatMessagesRecordReference
                                          .set(createChatMessagesRecordData(
                                        user: currentUserReference,
                                        chat: widget.chatRef?.reference,
                                        text: textController.text,
                                        timestamp: getCurrentTimestamp,
                                        image: uploadedFileUrlUploadDataJub4,
                                      ));
                                      newChatMessage = ChatMessagesRecord
                                          .getDocumentFromData(
                                              createChatMessagesRecordData(
                                                user: currentUserReference,
                                                chat:
                                                    widget.chatRef?.reference,
                                                text:
                                                    textController.text,
                                                timestamp: getCurrentTimestamp,
                                                image:
                                                    uploadedFileUrlUploadDataJub4,
                                              ),
                                              chatMessagesRecordReference);
                                      // clearUsers
                                      lastSeenBy = [];
                                      // In order to add a single user reference to a list of user references we are adding our current user reference to a page state.
                                      //
                                      // We will then set the value of the user reference list from this page state.
                                      // addMyUserToList
                                      addToLastSeenBy(
                                          currentUserReference!);
                                      // updateChatDocument

                                      await widget.chatRef!.reference.update({
                                        ...createChatsRecordData(
                                          lastMessageTime: getCurrentTimestamp,
                                          lastMessageSentBy:
                                              currentUserReference,
                                          lastMessage:
                                              textController.text,
                                        ),
                                        ...mapToFirestore(
                                          {
                                            'last_message_seen_by':
                                                lastSeenBy,
                                          },
                                        ),
                                      });
                                      // clearUsers
                                      lastSeenBy = [];
                                      if (mounted) setState(() {
                                        textController?.clear();
                                      });
                                      if (mounted) setState(() {
                                        isDataUploadingUploadDataJub4 =
                                            false;
                                        uploadedLocalFileUploadDataJub4 =
                                            FFUploadedFile(
                                                bytes: Uint8List.fromList([]),
                                                originalFilename: '');
                                        uploadedFileUrlUploadDataJub4 =
                                            '';
                                      });

                                      imagesUploaded = [];
                                      if (mounted) setState(() {});

                                      if (mounted) setState(() {});
                                    },
                                    autofocus: true,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    textInputAction: TextInputAction.send,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      labelStyle: AppTheme.of(context)
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
                                      hintText: 'Start typing here...',
                                      hintStyle: AppTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .labelSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTheme.of(context)
                                                    .labelSmall
                                                    .fontWeight,
                                            fontStyle:
                                                AppTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                          ),
                                      errorStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: AppTheme.of(context)
                                                .error,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppTheme.of(context)
                                              .alternate,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppTheme.of(context)
                                              .primary,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                      ),
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              16.0, 16.0, 56.0, 16.0),
                                    ),
                                    style: AppTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight:
                                                AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    maxLines: 12,
                                    minLines: 1,
                                    cursorColor:
                                        AppTheme.of(context).primary,
                                    validator: textControllerValidator
                                        .asValidator(context),
                                    inputFormatters: [
                                      if (!isAndroid && !isiOS)
                                        TextInputFormatter.withFunction(
                                            (oldValue, newValue) {
                                          return TextEditingValue(
                                            selection: newValue.selection,
                                            text: newValue.text
                                                .toCapitalization(
                                                    TextCapitalization
                                                        .sentences),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 4.0, 6.0, 4.0),
                                  child: AppIconButton(
                                    borderColor: AppTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: 20.0,
                                    borderWidth: 1.0,
                                    buttonSize: 40.0,
                                    fillColor:
                                        AppTheme.of(context).accent1,
                                    icon: Icon(
                                      Icons.send_rounded,
                                      color:
                                          AppTheme.of(context).primary,
                                      size: 20.0,
                                    ),
                                    onPressed: () async {
                                      final firestoreBatch =
                                          FirebaseFirestore.instance.batch();
                                      try {
                                        if (formKey.currentState ==
                                                null ||
                                            !formKey.currentState!
                                                .validate()) {
                                          return;
                                        }
                                        // newChatMessage

                                        var chatMessagesRecordReference =
                                            ChatMessagesRecord.collection.doc();
                                        firestoreBatch.set(
                                            chatMessagesRecordReference,
                                            createChatMessagesRecordData(
                                              user: currentUserReference,
                                              chat: widget.chatRef?.reference,
                                              text: textController.text,
                                              timestamp: getCurrentTimestamp,
                                              image:
                                                  uploadedFileUrlUploadDataJub4,
                                            ));
                                        newChat = ChatMessagesRecord
                                            .getDocumentFromData(
                                                createChatMessagesRecordData(
                                                  user: currentUserReference,
                                                  chat: widget
                                                      .chatRef?.reference,
                                                  text: textController.text,
                                                  timestamp:
                                                      getCurrentTimestamp,
                                                  image:
                                                      uploadedFileUrlUploadDataJub4,
                                                ),
                                                chatMessagesRecordReference);
                                        // clearUsers
                                        lastSeenBy = [];
                                        // In order to add a single user reference to a list of user references we are adding our current user reference to a page state.
                                        //
                                        // We will then set the value of the user reference list from this page state.
                                        // addMyUserToList
                                        addToLastSeenBy(
                                            currentUserReference!);
                                        // updateChatDocument

                                        firestoreBatch.update(
                                            widget.chatRef!.reference, {
                                          ...createChatsRecordData(
                                            lastMessageTime:
                                                getCurrentTimestamp,
                                            lastMessageSentBy:
                                                currentUserReference,
                                            lastMessage:
                                                textController.text,
                                          ),
                                          ...mapToFirestore(
                                            {
                                              'last_message_seen_by':
                                                  lastSeenBy,
                                            },
                                          ),
                                        });
                                        // clearUsers
                                        lastSeenBy = [];
                                        if (mounted) setState(() {
                                          textController?.clear();
                                        });
                                        if (mounted) setState(() {
                                          isDataUploadingUploadDataJub4 =
                                              false;
                                          uploadedLocalFileUploadDataJub4 =
                                              FFUploadedFile(
                                                  bytes: Uint8List.fromList([]),
                                                  originalFilename: '');
                                          uploadedFileUrlUploadDataJub4 =
                                              '';
                                        });

                                        imagesUploaded = [];
                                        if (mounted) setState(() {});
                                      } finally {
                                        await firestoreBatch.commit();
                                      }

                                      if (mounted) setState(() {});
                                    },
                                  ),
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
          ),
        ],
      ),
    );
  }
}
