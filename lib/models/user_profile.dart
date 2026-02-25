import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  UserProfile({
    required this.reference,
    required this.displayName,
    required this.photoUrl,
    required this.friends,
    required this.uid,
    required this.gender,
  });

  final DocumentReference reference;
  final String displayName;
  final String photoUrl;
  final List<DocumentReference> friends;
  final String uid;
  final String gender;

  static UserProfile fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return UserProfile(
      reference: doc.reference,
      displayName: (data['display_name'] as String?) ?? '',
      photoUrl: (data['photo_url'] as String?) ?? '',
      friends: (data['friends'] as List<dynamic>?)
              ?.whereType<DocumentReference>()
              .toList() ??
          [],
      uid: (data['uid'] as String?) ?? doc.id,
      gender: (data['gender'] as String?) ?? '',
    );
  }
}
