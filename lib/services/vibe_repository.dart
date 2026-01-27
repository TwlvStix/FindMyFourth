import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/backend/schema/util/firestore_util.dart';
import '/models/vibe_profile.dart';

class VibeRepository {
  VibeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static VibeProfile? _cachedMyVibes;
  static String? _cachedMyVibesUid;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _currentUserRef() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('no_user');
    }
    return _firestore.collection('users').doc(user.uid);
  }

  Future<VibeProfile> getMyVibes() async {
    return getMyVibesCached();
  }

  Future<VibeProfile> getMyVibesCached({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('no_user');
    }
    if (!forceRefresh &&
        _cachedMyVibes != null &&
        _cachedMyVibesUid == user.uid) {
      return _cachedMyVibes!;
    }
    final snapshot = await _currentUserRef().get();
    final profile = profileFromSnapshot(snapshot);
    _cachedMyVibes = profile;
    _cachedMyVibesUid = user.uid;
    return profile;
  }

  void clearMyVibesCache() {
    _cachedMyVibes = null;
    _cachedMyVibesUid = null;
  }

  void _updateCachedPreference(
    VibeCategory category, {
    int? value,
    bool? dealbreaker,
    bool? isDefault,
  }) {
    final user = _auth.currentUser;
    if (user == null ||
        _cachedMyVibes == null ||
        _cachedMyVibesUid != user.uid) {
      return;
    }

    final updatedPrefs =
        Map<VibeCategory, VibePreference>.from(_cachedMyVibes!.prefs);
    final current = updatedPrefs[category] ?? VibePreference.defaults();
    updatedPrefs[category] = current.copyWith(
      value: value ?? current.value,
      dealbreaker: dealbreaker ?? current.dealbreaker,
      isDefault: isDefault ?? current.isDefault,
    );
    _cachedMyVibes = _cachedMyVibes!.copyWith(prefs: updatedPrefs);
    _cachedMyVibesUid = user.uid;
  }

  void _updateCachedImportance(
    Map<VibeCategory, VibeImportance> importance, {
    DateTime? updatedAt,
    int? version,
  }) {
    final user = _auth.currentUser;
    if (user == null ||
        _cachedMyVibes == null ||
        _cachedMyVibesUid != user.uid) {
      return;
    }
    _cachedMyVibes = _cachedMyVibes!.copyWith(
      importance: importance,
      importanceUpdatedAt: updatedAt ?? _cachedMyVibes!.importanceUpdatedAt,
      importanceVersion: version ?? _cachedMyVibes!.importanceVersion,
    );
    _cachedMyVibesUid = user.uid;
  }

  VibeProfile profileFromSnapshot(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      return VibeProfile.defaults();
    }
    final raw = snapshot.data();
    if (raw is! Map<String, dynamic>) {
      return VibeProfile.defaults();
    }
    return profileFromData(Map<String, dynamic>.from(raw));
  }

  VibeProfile profileFromData(Map<String, dynamic> raw) {
    final data = mapFromFirestore(Map<String, dynamic>.from(raw));
    final vibeProfileRaw = data['vibe_profile'];
    final vibeProfileMap = vibeProfileRaw is Map
        ? Map<String, dynamic>.from(vibeProfileRaw)
        : null;
    return VibeProfile.fromFirestore(vibeProfileMap);
  }

  Future<void> updateCategory(VibeCategory category, int value) async {
    final normalizedValue = VibePreference.normalizeValue(value);
    await _currentUserRef().set(
      {
        'vibe_profile': {
          'prefs': {
            category.key: {
              'value': normalizedValue,
              'is_default': false,
            },
          },
        },
      },
      SetOptions(merge: true),
    );
    _updateCachedPreference(
      category,
      value: normalizedValue,
      isDefault: false,
    );
  }

  Future<void> toggleDealbreaker(
    VibeCategory category,
    bool dealbreaker,
  ) async {
    await _currentUserRef().set(
      {
        'vibe_profile': {
          'prefs': {
            category.key: {
              'dealbreaker': dealbreaker,
              'is_default': false,
            },
          },
        },
      },
      SetOptions(merge: true),
    );
    _updateCachedPreference(
      category,
      dealbreaker: dealbreaker,
      isDefault: false,
    );
  }

  Future<void> confirmVibes({VibeProfile? profile}) async {
    final confirmed =
        (profile ?? await getMyVibes()).confirmed(DateTime.now());
    await _currentUserRef().set(
      {'vibe_profile': confirmed.toFirestore()},
      SetOptions(merge: true),
    );
    _cachedMyVibes = confirmed;
    _cachedMyVibesUid = _auth.currentUser?.uid;
  }

  Future<void> saveProfile(VibeProfile profile) async {
    await _currentUserRef().set(
      {'vibe_profile': profile.toFirestore()},
      SetOptions(merge: true),
    );
    _cachedMyVibes = profile;
    _cachedMyVibesUid = _auth.currentUser?.uid;
  }

  Future<void> updateImportance(
    Map<VibeCategory, VibeImportance> importance, {
    int version = 1,
  }) async {
    final importanceMap = <String, dynamic>{
      for (final entry in importance.entries) entry.key.key: entry.value.key,
    };
    await _currentUserRef().set(
      {
        'vibe_profile.importance': importanceMap,
        'vibe_profile.importance_version': version,
        'vibe_profile.importance_updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _updateCachedImportance(
      importance,
      updatedAt: DateTime.now(),
      version: version,
    );
  }

  Future<void> setDefaults() async {
    await saveProfile(VibeProfile.defaults());
  }
}
