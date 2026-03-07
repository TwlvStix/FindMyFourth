import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/course_record.dart';
import '/models/lat_lng.dart';

class Course {
  Course({
    required this.reference,
    required this.name,
    this.latLng,
  });

  final DocumentReference reference;
  final String name;
  final LatLng? latLng;

  static Course fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final geoPoint = data['location'] as GeoPoint?;
    return Course(
      reference: doc.reference,
      name: (data['name'] as String?) ?? '',
      latLng: geoPoint != null
          ? LatLng(geoPoint.latitude, geoPoint.longitude)
          : null,
    );
  }

  static Course fromRecord(CourseRecord record) => Course(
        reference: record.reference,
        name: record.name,
        latLng: record.location,
      );
}
