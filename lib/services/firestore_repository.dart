import 'package:cloud_firestore/cloud_firestore.dart';

import '/utils/app_util.dart';
import '/backend/schema/util/firestore_util.dart';

class FirestorePage<T> {
  final List<T> data;
  final Stream<List<T>>? dataStream;
  final QueryDocumentSnapshot? nextPageMarker;

  FirestorePage(this.data, this.dataStream, this.nextPageMarker);
}

class FirestoreRepository {
  const FirestoreRepository();

  Future<FirestorePage<T>> queryCollectionPage<T>(
    Query collection,
    RecordBuilder<T> recordBuilder, {
    Query Function(Query)? queryBuilder,
    DocumentSnapshot? nextPageMarker,
    required int pageSize,
    required bool isStream,
  }) async {
    final builder = queryBuilder ?? (q) => q;
    var query = builder(collection).limit(pageSize);
    if (nextPageMarker != null) {
      query = query.startAfterDocument(nextPageMarker);
    }
    Stream<QuerySnapshot>? docSnapshotStream;
    QuerySnapshot docSnapshot;
    if (isStream) {
      docSnapshotStream = query.snapshots();
      docSnapshot = await docSnapshotStream.first;
    } else {
      docSnapshot = await query.get();
    }
    final getDocs = (QuerySnapshot s) => s.docs
        .map(
          (d) => safeGet(
            () => recordBuilder(d),
            (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
          ),
        )
        .where((d) => d != null)
        .map((d) => d!)
        .toList();
    final data = getDocs(docSnapshot);
    final dataStream = docSnapshotStream?.map(getDocs);
    final nextPageToken = docSnapshot.docs.isEmpty ? null : docSnapshot.docs.last;
    return FirestorePage(data, dataStream, nextPageToken);
  }
}
