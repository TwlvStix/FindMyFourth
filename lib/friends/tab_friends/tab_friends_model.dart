import '/backend/backend.dart';
import '/core/app_util.dart';
import '/index.dart';
import 'tab_friends_widget.dart' show TabFriendsWidget;
import 'package:flutter/material.dart';

class TabFriendsModel extends AppModel<TabFriendsWidget> {
  ///  Local state fields for this page.

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

  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // State field(s) for TextField widget.
  final textFieldKey = GlobalKey();
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? textFieldSelectedOption;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Firestore Query - Query a collection] action in IconButton widget.
  ChatsRecord? chatsChecker;
  // Stores action output result for [Firestore Query - Query a collection] action in IconButton widget.
  ChatsRecord? chatsChecker2;
  // Stores action output result for [Backend Call - Create Document] action in IconButton widget.
  ChatsRecord? chatroomReference;
  // Stores action output result for [Firestore Query - Query a collection] action in IconButton widget.
  ChatsRecord? chatroomChecker;
  // Stores action output result for [Firestore Query - Query a collection] action in IconButton widget.
  ChatsRecord? chatroomChecker2;
  // Stores action output result for [Backend Call - Create Document] action in IconButton widget.
  ChatsRecord? chatroomReference2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
    textFieldFocusNode?.dispose();
  }
}
