import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/utils/app_log.dart';
import '/models/course.dart';

/// Service for accessing course data from Firestore.
///
/// Follows the service pattern with injectable Firestore instance.
class CourseService {
  CourseService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _resolvedFirestore =>
      _firestore ?? FirebaseFirestore.instance;

  /// Loads all courses ordered by name.
  ///
  /// Used by game_alerts_page_widget for course filtering.
  /// Throws [FirebaseException] on failure.
  Future<List<Course>> loadAllCourses() async {
    try {
      final snapshot = await _resolvedFirestore
          .collection('course')
          .orderBy('name')
          .get();
      AppLog.d('📖 CourseService: Loaded ${snapshot.docs.length} courses');
      return snapshot.docs.map((doc) => Course.fromDoc(doc)).toList();
    } on FirebaseException catch (e) {
      AppLog.d('❌ CourseService.loadAllCourses: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Streams all courses ordered by name.
  ///
  /// Used by create_game_widget for real-time course dropdown.
  Stream<List<Course>> streamAllCourses() {
    return _resolvedFirestore
        .collection('course')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Course.fromDoc(doc)).toList());
  }
}
