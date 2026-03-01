import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';
import '/models/user_profile.dart';
import '/services/game_eligibility_service.dart';
import '/services/player_search_service.dart';

class PlayerSlotSelection {
  const PlayerSlotSelection({
    required this.uid,
    required this.name,
    required this.isGuest,
    this.photoUrl,
    this.gender,
  });

  final String uid;
  final String name;
  final bool isGuest;
  final String? photoUrl;
  final String? gender;
}

class PlayerSearchState {
  const PlayerSearchState({
    required this.activeQuery,
    required this.isSearching,
    required this.hasMoreResults,
    required this.lastDocument,
    required this.results,
  });

  factory PlayerSearchState.initial() {
    return const PlayerSearchState(
      activeQuery: '',
      isSearching: false,
      hasMoreResults: false,
      lastDocument: null,
      results: <UserProfile>[],
    );
  }

  final String activeQuery;
  final bool isSearching;
  final bool hasMoreResults;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final List<UserProfile> results;
}

enum AddPlayerBlockReason {
  none,
  alreadyInGame,
  alreadySelected,
  ineligible,
  invalidUser,
}

class AddPlayerDecision {
  const AddPlayerDecision({
    required this.canAdd,
    this.subtitle,
    this.reason = AddPlayerBlockReason.none,
  });

  final bool canAdd;
  final String? subtitle;
  final AddPlayerBlockReason reason;
}

class AddPlayerAttemptResult {
  const AddPlayerAttemptResult({
    required this.added,
    this.errorMessage,
  });

  final bool added;
  final String? errorMessage;

  factory AddPlayerAttemptResult.success() {
    return const AddPlayerAttemptResult(added: true);
  }

  factory AddPlayerAttemptResult.failure(String message) {
    return AddPlayerAttemptResult(
      added: false,
      errorMessage: message,
    );
  }
}

class SubmissionPayload {
  const SubmissionPayload({
    required this.joinedPlayerUids,
    required this.guestPlayers,
  });

  final List<String> joinedPlayerUids;
  final List<String> guestPlayers;

  int get totalToAdd => joinedPlayerUids.length + guestPlayers.length;
}

class SubmissionValidation {
  const SubmissionValidation({
    required this.isValid,
    this.errorMessage,
  });

  final bool isValid;
  final String? errorMessage;

  factory SubmissionValidation.valid() {
    return const SubmissionValidation(isValid: true);
  }

  factory SubmissionValidation.invalid(String message) {
    return SubmissionValidation(
      isValid: false,
      errorMessage: message,
    );
  }
}

class PlayerSubmitResult {
  const PlayerSubmitResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;

  factory PlayerSubmitResult.ok() {
    return const PlayerSubmitResult(success: true);
  }

  factory PlayerSubmitResult.error(String message) {
    return PlayerSubmitResult(
      success: false,
      errorMessage: message,
    );
  }
}

class PlayerListController {
  PlayerListController({
    PlayerSearchService? playerSearchService,
  }) : _playerSearchService = playerSearchService ?? PlayerSearchService();

  static const String guestOptionValue = 'guest';
  static const int minSearchChars = 2;
  static const int pageSize = 25;

  final PlayerSearchService _playerSearchService;
  final Map<int, PlayerSlotSelection> _playerSlots =
      <int, PlayerSlotSelection>{};

  Timer? _searchDebounce;
  int _searchToken = 0;
  PlayerSearchState _searchState = PlayerSearchState.initial();

  PlayerSearchState get searchState => _searchState;

  Map<int, PlayerSlotSelection> get playerSlots =>
      Map<int, PlayerSlotSelection>.unmodifiable(_playerSlots);

  Set<String> get selectedPlayerIds => _playerSlots.values
      .where((slot) => !slot.isGuest)
      .map((slot) => slot.uid)
      .toSet();

  PlayerSlotSelection? slotForIndex(int slotIndex) => _playerSlots[slotIndex];

  void dispose() {
    _searchDebounce?.cancel();
    _searchToken += 1;
  }

  void removePlayerFromSlot(int slotIndex) {
    _playerSlots.remove(slotIndex);
  }

  void resetSearchState() {
    _searchDebounce?.cancel();
    _searchToken += 1;
    _searchState = PlayerSearchState.initial();
  }

  void onSearchChanged(
    String rawValue, {
    required VoidCallback onStateChanged,
    void Function(String message)? onError,
  }) {
    final query = rawValue.trim().toLowerCase();
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length < minSearchChars) {
        _searchState = PlayerSearchState(
          activeQuery: query,
          isSearching: false,
          hasMoreResults: false,
          lastDocument: null,
          results: const <UserProfile>[],
        );
        onStateChanged();
        return;
      }

      runSearch(
        query: query,
        reset: true,
        onStateChanged: onStateChanged,
        onError: onError,
      );
    });
  }

  Future<void> runSearch({
    required String query,
    required bool reset,
    required VoidCallback onStateChanged,
    void Function(String message)? onError,
  }) async {
    final searchToken = ++_searchToken;

    _searchState = PlayerSearchState(
      activeQuery: query,
      isSearching: true,
      hasMoreResults: reset ? false : _searchState.hasMoreResults,
      lastDocument: reset ? null : _searchState.lastDocument,
      results: reset ? _searchState.results : _searchState.results,
    );
    onStateChanged();

    AppLog.d(
      '🔍 AddPlayer search: query="$query" length=${query.length} reset=$reset',
    );

    try {
      final page = await _playerSearchService.searchPlayers(
        query: query,
        pageSize: pageSize,
        startAfter: reset ? null : _searchState.lastDocument,
      );

      if (searchToken != _searchToken) {
        return;
      }

      final nextResults = reset
          ? page.results
          : _mergeWithoutDuplicates(
              existing: _searchState.results,
              incoming: page.results,
            );

      _searchState = PlayerSearchState(
        activeQuery: query,
        isSearching: false,
        hasMoreResults: page.hasMoreResults,
        lastDocument: page.lastDocument,
        results: nextResults,
      );
      onStateChanged();
    } catch (e) {
      if (searchToken != _searchToken) {
        return;
      }

      _searchState = PlayerSearchState(
        activeQuery: query,
        isSearching: false,
        hasMoreResults: false,
        lastDocument: reset ? null : _searchState.lastDocument,
        results: reset ? const <UserProfile>[] : _searchState.results,
      );
      onStateChanged();
      onError?.call('Error searching players: $e');
    }
  }

  Future<void> loadMore({
    required VoidCallback onStateChanged,
    void Function(String message)? onError,
  }) async {
    if (_searchState.isSearching || !_searchState.hasMoreResults) {
      return;
    }

    if (_searchState.activeQuery.length < minSearchChars) {
      return;
    }

    await runSearch(
      query: _searchState.activeQuery,
      reset: false,
      onStateChanged: onStateChanged,
      onError: onError,
    );
  }

  AddPlayerDecision evaluateCandidate({
    required UserProfile profile,
    required Set<String> joinedPlayerIds,
    required PlayerEligibility eligibility,
  }) {
    if (joinedPlayerIds.contains(profile.uid)) {
      return const AddPlayerDecision(
        canAdd: false,
        subtitle: 'Already in game',
        reason: AddPlayerBlockReason.alreadyInGame,
      );
    }

    if (selectedPlayerIds.contains(profile.uid)) {
      return const AddPlayerDecision(
        canAdd: false,
        subtitle: 'Already selected',
        reason: AddPlayerBlockReason.alreadySelected,
      );
    }

    final eligibilityResult = checkPlayerEligibility(
      eligibility: eligibility,
      userGender: profile.gender,
    );

    if (!eligibilityResult.allowed) {
      return AddPlayerDecision(
        canAdd: false,
        subtitle: eligibility == PlayerEligibility.womenOnly
            ? 'Women only round'
            : 'Men only round',
        reason: AddPlayerBlockReason.ineligible,
      );
    }

    return const AddPlayerDecision(canAdd: true);
  }

  AddPlayerAttemptResult addGuestToSlot({
    required int slotIndex,
  }) {
    _playerSlots[slotIndex] = const PlayerSlotSelection(
      uid: guestOptionValue,
      name: 'Guest',
      isGuest: true,
    );

    return AddPlayerAttemptResult.success();
  }

  AddPlayerAttemptResult addProfileToSlot({
    required int slotIndex,
    required UserProfile? profile,
    required Set<String> joinedPlayerIds,
    required PlayerEligibility eligibility,
  }) {
    if (profile == null || profile.uid.isEmpty) {
      return AddPlayerAttemptResult.failure('Unable to add this player.');
    }

    final decision = evaluateCandidate(
      profile: profile,
      joinedPlayerIds: joinedPlayerIds,
      eligibility: eligibility,
    );

    if (!decision.canAdd) {
      return switch (decision.reason) {
        AddPlayerBlockReason.alreadySelected =>
          AddPlayerAttemptResult.failure('Player already selected.'),
        AddPlayerBlockReason.ineligible => AddPlayerAttemptResult.failure(
            eligibility == PlayerEligibility.womenOnly
                ? 'This round is open to women only'
                : 'This round is open to men only',
          ),
        AddPlayerBlockReason.alreadyInGame =>
          AddPlayerAttemptResult.failure('Player is already in this game.'),
        _ => AddPlayerAttemptResult.failure('Unable to add this player.'),
      };
    }

    _playerSlots[slotIndex] = PlayerSlotSelection(
      uid: profile.uid,
      name: profile.displayName.isNotEmpty ? profile.displayName : 'Player',
      isGuest: false,
      photoUrl: profile.photoUrl,
      gender: profile.gender,
    );

    return AddPlayerAttemptResult.success();
  }

  SubmissionPayload buildSubmissionPayload({
    required Game game,
  }) {
    final orderedSlots = _playerSlots.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final joinedPlayerUidsToAdd = <String>[];
    final guestPlayersToAdd = <String>[];

    for (final entry in orderedSlots) {
      final slot = entry.value;
      if (slot.isGuest) {
        guestPlayersToAdd.add(
            'Guest ${game.guestPlayers.length + guestPlayersToAdd.length + 1}');
      } else if (slot.uid.isNotEmpty) {
        joinedPlayerUidsToAdd.add(slot.uid);
      }
    }

    return SubmissionPayload(
      joinedPlayerUids: joinedPlayerUidsToAdd,
      guestPlayers: guestPlayersToAdd,
    );
  }

  SubmissionValidation validateSubmission({
    required Game game,
    required SubmissionPayload payload,
  }) {
    final currentPlayerCount =
        game.joinedPlayers.length + game.guestPlayers.length;

    if (currentPlayerCount >= game.maxPlayers) {
      return SubmissionValidation.invalid(
        'Game is already full (${game.maxPlayers} players)',
      );
    }

    final newPlayerCount = currentPlayerCount + payload.totalToAdd;
    if (newPlayerCount > game.maxPlayers) {
      return SubmissionValidation.invalid(
        'Cannot add ${payload.totalToAdd} players - would exceed max (${game.maxPlayers})',
      );
    }

    if (game.playerEligibility == PlayerEligibility.openToAll) {
      return SubmissionValidation.valid();
    }

    for (final slot in _playerSlots.values) {
      if (slot.isGuest) {
        continue;
      }

      final eligibilityResult = checkPlayerEligibility(
        eligibility: game.playerEligibility,
        userGender: slot.gender,
      );

      if (!eligibilityResult.allowed) {
        final restrictionType =
            game.playerEligibility == PlayerEligibility.womenOnly
                ? 'women'
                : 'men';
        return SubmissionValidation.invalid(
          '${slot.name} cannot join - this round is open to $restrictionType only',
        );
      }
    }

    return SubmissionValidation.valid();
  }

  Future<PlayerSubmitResult> submitSelections({
    required Game game,
    required DocumentReference gameRef,
  }) async {
    final payload = buildSubmissionPayload(game: game);
    final validation = validateSubmission(game: game, payload: payload);

    if (!validation.isValid) {
      return PlayerSubmitResult.error(
        validation.errorMessage ?? 'Unable to submit players.',
      );
    }

    try {
      if (payload.totalToAdd > 0) {
        await _playerSearchService.addPlayersToGame(
          gameRef: gameRef,
          joinedPlayerUids: payload.joinedPlayerUids,
          guestPlayers: payload.guestPlayers,
        );
      }
      return PlayerSubmitResult.ok();
    } catch (e) {
      return PlayerSubmitResult.error('Error adding players: $e');
    }
  }

  List<UserProfile> _mergeWithoutDuplicates({
    required List<UserProfile> existing,
    required List<UserProfile> incoming,
  }) {
    final existingIds = existing.map((profile) => profile.uid).toSet();
    return <UserProfile>[
      ...existing,
      ...incoming.where((profile) => !existingIds.contains(profile.uid)),
    ];
  }
}
