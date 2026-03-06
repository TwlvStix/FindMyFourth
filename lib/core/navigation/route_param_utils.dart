import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '/utils/serialization_util.dart';
import '/core/navigation/transition_standards.dart' show kTransitionInfoKey, TransitionInfo;
import '/vibe/premium_vibe_page/premium_vibe_page_data.dart';

/// Collects all parameters from path, query, and extra into a single map.
Map<String, dynamic> allRouteParams(GoRouterState state) {
  final params = <String, dynamic>{}
    ..addAll(state.pathParameters)
    ..addAll(state.uri.queryParameters);
  if (state.extra is Map<String, dynamic>) {
    params.addAll(state.extra as Map<String, dynamic>);
  }
  return params;
}

/// Gets a single parameter value by name from all available sources.
dynamic paramValue(GoRouterState state, String name) =>
    allRouteParams(state)[name];

/// Deserializes a route parameter to a typed value.
///
/// Handles the parameter as-is if it's not a String, otherwise uses
/// [deserializeParam] from serialization_util.
T? deserializeRouteParam<T>(
  GoRouterState state,
  String name,
  ParamType type, {
  bool isList = false,
  List<String>? collectionNamePath,
}) {
  final param = paramValue(state, name);
  if (param == null) {
    return null;
  }
  if (param is! String) {
    return param as T?;
  }
  return deserializeParam<T>(
    param,
    type,
    isList,
    collectionNamePath: collectionNamePath,
  ) as T?;
}

/// Returns true if route state has no meaningful parameters.
///
/// Empty means either no params at all, or only the transition info key.
bool isEmptyStateParams(GoRouterState state) {
  final params = allRouteParams(state);
  if (params.isEmpty) {
    return true;
  }
  return params.length == 1 && params.containsKey(kTransitionInfoKey);
}

/// Extracts TransitionInfo from route state, or returns default.
TransitionInfo transitionInfoFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is Map<String, dynamic> && extra.containsKey(kTransitionInfoKey)) {
    return extra[kTransitionInfoKey] as TransitionInfo;
  }
  return TransitionInfo.appDefault();
}

/// Extracts a game DocumentReference from route state.
///
/// Checks in order:
/// 1. Direct DocumentReference in extra
/// 2. 'gameRef' key in extra Map
/// 3. Query parameter deserialization with 'games' collection path
DocumentReference? gameRefFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is DocumentReference) {
    return extra;
  }
  if (extra is Map && extra['gameRef'] is DocumentReference) {
    return extra['gameRef'] as DocumentReference;
  }
  final fromQuery = deserializeRouteParam(
    state,
    'gameRef',
    ParamType.DocumentReference,
    collectionNamePath: ['games'],
  );
  if (fromQuery is DocumentReference) {
    return fromQuery;
  }
  return null;
}

/// Extracts a user DocumentReference from route state.
///
/// Checks in order:
/// 1. Direct DocumentReference in extra
/// 2. 'userRef' key in extra Map
/// 3. Query parameter deserialization with 'users' collection path
DocumentReference? userRefFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is DocumentReference) {
    return extra;
  }
  if (extra is Map && extra['userRef'] is DocumentReference) {
    return extra['userRef'] as DocumentReference;
  }
  final fromQuery = deserializeRouteParam(
    state,
    'userRef',
    ParamType.DocumentReference,
    collectionNamePath: ['users'],
  );
  if (fromQuery is DocumentReference) {
    return fromQuery;
  }
  return null;
}

/// Extracts isEditMode boolean from route state.
/// Defaults to false if not present.
bool isEditModeFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is Map && extra['isEditMode'] is bool) {
    return extra['isEditMode'] as bool;
  }
  return false;
}

/// Extracts PremiumVibePageData from route state.
///
/// Returns null if extra is not of the expected type (e.g., deep links
/// or malformed navigation).
PremiumVibePageData? premiumVibeDataFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is PremiumVibePageData) {
    return extra;
  }
  return null;
}
