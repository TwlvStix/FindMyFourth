import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  Course({
    required this.reference,
    required this.name,
  });

  final DocumentReference reference;
  final String name;

  static Course fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Course(
      reference: doc.reference,
      name: (data['name'] as String?) ?? '',
    );
  }
}
