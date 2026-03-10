import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/core/utils/app_log.dart';
import '/main_function/create_game/models/create_game_form_data.dart';

/// Service for creating games in Firestore.
///
/// Follows the service pattern with injectable Firestore instance.
class CreateGameService {
  CreateGameService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  FirebaseAuth get _resolvedAuth => _auth ?? FirebaseAuth.instance;

  FirebaseFirestore get _resolvedFirestore =>
      _firestore ?? FirebaseFirestore.instance;

  /// Creates a new game document and returns its reference.
  ///
  /// Parameters:
  /// - [formData]: The form data containing all game fields
  /// - [uid]: The creating user's UID
  /// - [userRef]: DocumentReference to the creating user
  /// - [chatRef]: DocumentReference to the game chat (optional)
  ///
  /// Throws [FirebaseException] on failure.
  Future<DocumentReference> createGame({
    required CreateGameFormData formData,
    required String uid,
    required DocumentReference userRef,
    DocumentReference? chatRef,
  }) async {
    final gameRef = _resolvedFirestore.collection('games').doc();
    return createGameWithRef(
      gameRef: gameRef,
      formData: formData,
      uid: uid,
      userRef: userRef,
      chatRef: chatRef,
    );
  }

  /// Creates a game at an existing reference.
  ///
  /// This is used when the ID must be generated before persistence
  /// (e.g. chat creation needs game ID first).
  Future<DocumentReference> createGameWithRef({
    required DocumentReference gameRef,
    required CreateGameFormData formData,
    required String uid,
    required DocumentReference userRef,
    DocumentReference? chatRef,
  }) async {
    AppLog.d('🎮 CREATE GAME SERVICE: Creating game ${gameRef.id}');

    try {
      await gameRef.set(formData.toFirestoreMap(
        uid: uid,
        userRef: userRef,
        chatRef: chatRef,
      ));
      AppLog.d('✅ CREATE GAME SERVICE: Game created ${gameRef.path}');

      // Create game_participants doc for the host
      try {
        await _resolvedFirestore.collection('game_participants').add({
          'game_ref': gameRef,
          'user_ref': userRef,
          'role': 'host',
          'status': 'joined',
          'joined_at': FieldValue.serverTimestamp(),
        });
        AppLog.d('✅ CREATE GAME SERVICE: Host participant doc created');
      } on FirebaseException catch (e) {
        AppLog.d(
            '❌ CREATE GAME SERVICE: participant doc failed: ${e.code}');
      }

      return gameRef;
    } on FirebaseException catch (e) {
      AppLog.d('❌ CREATE GAME SERVICE: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Generates a new game reference without creating the document.
  ///
  /// Useful for getting the game ID before creating the chat.
  DocumentReference generateGameRef() {
    return _resolvedFirestore.collection('games').doc();
  }

  /// Returns a typed user document reference for the given uid.
  DocumentReference userRefForUid(String uid) {
    return _resolvedFirestore.collection('users').doc(uid);
  }

  /// Returns the current authenticated user's UID, or null if not authenticated.
  String? getCurrentUserId() {
    return _resolvedAuth.currentUser?.uid;
  }
}
