import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_icon_button.dart';
import '/friends/components/empty_state.dart';
import '/friends/components/friend_card_skeleton.dart';
import '/friends/components/friend_filter_bottom_sheet.dart';
import '/friends/components/default_explore_content.dart';

typedef GolferSearchItemBuilder = Widget Function(
  BuildContext context,
  UsersRecord user,
);

typedef GolferSearchEmptyBuilder = Widget Function(VoidCallback clearSearch);

class GolferSearchSection extends StatefulWidget {
  const GolferSearchSection({
    super.key,
    required this.currentUserId,
    required this.itemBuilder,
    this.friendFilters,
    this.onFilterPressed,
    this.minimumSearchCharacters = 2,
    this.showDefaultsWhenBelowThreshold = false,
    this.searchDebounce = Duration.zero,
    this.showFocusHelperText = false,
    this.autofocus = false,
    this.resultsLabel = 'Search Results',
    this.emptyStateBuilder,
    this.loadingWidget,
    this.externalSearchTerm,
    this.hideInternalSearchBar = false,
  });

  final String currentUserId;
  final GolferSearchItemBuilder itemBuilder;
  final FriendFilters? friendFilters;
  final VoidCallback? onFilterPressed;
  final int minimumSearchCharacters;
  final bool showDefaultsWhenBelowThreshold;
  final Duration searchDebounce;
  final bool showFocusHelperText;
  final bool autofocus;
  final String resultsLabel;
  final GolferSearchEmptyBuilder? emptyStateBuilder;
  final Widget? loadingWidget;

  /// External search term provided by parent widget.
  /// When set, uses this instead of internal search state.
  final String? externalSearchTerm;

  /// When true, hides the internal search bar (use when parent provides search).
  final bool hideInternalSearchBar;

  @override
  State<GolferSearchSection> createState() => _GolferSearchSectionState();
}

class _GolferSearchSectionState extends State<GolferSearchSection> {
  final GlobalKey _textFieldKey = GlobalKey();
  FocusNode? _textFieldFocusNode;
  TextEditingController? _textController;
  late final ValueNotifier<String> _searchTerm;
  Timer? _debounceTimer;
  String _debouncedTerm = '';

  @override
  void initState() {
    super.initState();
    _searchTerm = ValueNotifier<String>('');
    _textController = TextEditingController();
    _textFieldFocusNode = FocusNode();
    _textFieldFocusNode!.addListener(_handleFocusChanged);
    _textController!.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _textController?.removeListener(_handleTextChanged);
    _textController?.dispose();
    _textFieldFocusNode?.removeListener(_handleFocusChanged);
    _textFieldFocusNode?.dispose();
    _debounceTimer?.cancel();
    _searchTerm.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTextChanged() {
    final text = _textController?.text ?? '';
    _searchTerm.value = text;
    final trimmed = text.trim();
    if (trimmed.length < widget.minimumSearchCharacters) {
      _debounceTimer?.cancel();
      if (_debouncedTerm.isNotEmpty) {
        setState(() {
          _debouncedTerm = '';
        });
      }
      return;
    }

    if (widget.searchDebounce == Duration.zero) {
      if (_debouncedTerm != trimmed) {
        setState(() {
          _debouncedTerm = trimmed;
        });
      }
    } else {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.searchDebounce, () {
        if (!mounted) return;
        final latest = _textController?.text.trim() ?? '';
        if (latest.length < widget.minimumSearchCharacters) {
          if (_debouncedTerm.isNotEmpty) {
            setState(() {
              _debouncedTerm = '';
            });
          }
          return;
        }
        if (_debouncedTerm != latest) {
          setState(() {
            _debouncedTerm = latest;
          });
        }
      });
    }
    if (kDebugMode) {
      debugPrint('🔍 UI: Golfer search text="${_searchTerm.value}"');
    }
  }

  void _clearSearch() {
    _textController?.clear();
    FocusScope.of(context).unfocus();
  }

  Widget _buildLoading() {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md),
      child: widget.loadingWidget ??
          Column(
            children: [
              FriendCardSkeleton(),
              FriendCardSkeleton(),
              FriendCardSkeleton(),
            ],
          ),
    );
  }

  List<UsersRecord> _filterResults(
    List<UsersRecord> users, {
    String? searchTerm,
  }) {
    final filters = widget.friendFilters;
    return users
        .where((user) => user.reference.id != widget.currentUserId)
        .where((user) {
          if (searchTerm == null || searchTerm.isEmpty) {
            return true;
          }
          final displayName = user.displayName.toLowerCase();
          final firstName = user.firstName.toLowerCase();
          final lastName = user.lastName.toLowerCase();
          return displayName.contains(searchTerm) ||
              firstName.contains(searchTerm) ||
              lastName.contains(searchTerm);
        })
        .where((user) => filters == null || filters.matchesUser(user))
        .toList();
  }

  Widget _buildResultsList(List<UsersRecord> results) {
    if (results.isEmpty) {
      return widget.emptyStateBuilder?.call(_clearSearch) ??
          FriendsEmptyState(
            type: FriendsEmptyStateType.noSearchResults,
            onActionPressed: _clearSearch,
          );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        0,
        AppSpacing.xs,
        0,
        AppSpacing.xxl,
      ),
      primary: false,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: results.length,
      separatorBuilder: (_, __) => SizedBox(height: 0),
      itemBuilder: (context, index) {
        final user = results[index];
        return widget.itemBuilder(context, user);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use external search term if provided, otherwise use internal state
    final useExternalSearch = widget.externalSearchTerm != null;
    final effectiveSearchTerm = useExternalSearch
        ? widget.externalSearchTerm!.trim()
        : _searchTerm.value.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show internal search bar if not hidden
        if (!widget.hideInternalSearchBar)
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: TextFormField(
                      key: _textFieldKey,
                      controller: _textController,
                      focusNode: _textFieldFocusNode,
                      autofocus: widget.autofocus,
                      obscureText: false,
                      decoration: InputDecoration(
                        helperText: null,
                        helperStyle: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                        labelStyle: AppTheme.of(context).labelMedium.override(
                              font: TextStyle(fontFamily: 'Manrope',
                                fontWeight:
                                    AppTheme.of(context).labelMedium.fontWeight,
                                fontStyle:
                                    AppTheme.of(context).labelMedium.fontStyle,
                              ),
                              color: AppTheme.of(context).primaryBtnText,
                              letterSpacing: 0.0,
                              fontWeight:
                                  AppTheme.of(context).labelMedium.fontWeight,
                              fontStyle:
                                  AppTheme.of(context).labelMedium.fontStyle,
                            ),
                        hintStyle: AppTheme.of(context).labelMedium.override(
                              font: TextStyle(fontFamily: 'Manrope',
                                fontWeight:
                                    AppTheme.of(context).labelMedium.fontWeight,
                                fontStyle:
                                    AppTheme.of(context).labelMedium.fontStyle,
                              ),
                              color: AppTheme.of(context).primaryBtnText,
                              letterSpacing: 0.0,
                              fontWeight:
                                  AppTheme.of(context).labelMedium.fontWeight,
                              fontStyle:
                                  AppTheme.of(context).labelMedium.fontStyle,
                            ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppTheme.of(context).primaryBtnText,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppTheme.of(context).primaryBtnText,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppTheme.of(context).error,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppTheme.of(context).error,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.of(context).primaryBtnText,
                        ),
                      ),
                      style: AppTheme.of(context).bodyMedium.override(
                            font: TextStyle(fontFamily: 'Manrope',
                              fontWeight:
                                  AppTheme.of(context).bodyMedium.fontWeight,
                              fontStyle:
                                  AppTheme.of(context).bodyMedium.fontStyle,
                            ),
                            color: AppTheme.of(context).secondaryBackground,
                            letterSpacing: 0.0,
                            fontWeight:
                                AppTheme.of(context).bodyMedium.fontWeight,
                            fontStyle:
                                AppTheme.of(context).bodyMedium.fontStyle,
                          ),
                    ),
                  ),
                ),
                if (widget.onFilterPressed != null) ...[
                  Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm),
                    child: AppIconButton(
                      borderColor: widget.friendFilters?.hasActiveFilters == true
                          ? AppColors.fairway.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: 30.0,
                      borderWidth:
                          widget.friendFilters?.hasActiveFilters == true ? 2.0 : 1.0,
                      buttonSize: 44.0,
                      fillColor: widget.friendFilters?.hasActiveFilters == true
                          ? AppColors.fairway.withOpacity(0.1)
                          : Colors.transparent,
                      tooltip: 'Filters',
                      icon: Icon(
                        Icons.tune_rounded,
                        color: widget.friendFilters?.hasActiveFilters == true
                            ? AppColors.fairway
                            : AppTheme.of(context).primaryBtnText,
                        size: 24.0,
                      ),
                      onPressed: widget.onFilterPressed,
                    ),
                  ),
                ],
                Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: AppIconButton(
                    borderColor: Colors.transparent,
                    borderRadius: 30.0,
                    borderWidth: 1.0,
                    buttonSize: 44.0,
                    tooltip: 'Clear search',
                    icon: Icon(
                      Icons.clear_sharp,
                      color: AppTheme.of(context).primaryBtnText,
                      size: 24.0,
                    ),
                    onPressed: _clearSearch,
                  ),
                ),
              ],
            ),
          ),
        // Content based on search term
        _buildContent(context, effectiveSearchTerm, useExternalSearch),
      ],
    );
  }

  Widget _buildContent(BuildContext context, String searchTerm, bool useExternal) {
    // For external search, use the term directly
    if (useExternal) {
      final meetsThreshold = searchTerm.length >= widget.minimumSearchCharacters;

      if (!meetsThreshold) {
        if (!widget.showDefaultsWhenBelowThreshold) {
          return SizedBox.shrink();
        }
        return DefaultExploreContent(
          currentUserId: widget.currentUserId,
          itemBuilder: widget.itemBuilder,
        );
      }

      return _buildSearchResults(searchTerm);
    }

    // For internal search, use ValueListenableBuilder
    return ValueListenableBuilder<String>(
      valueListenable: _searchTerm,
      builder: (context, term, _) {
        final inputTerm = term.trim();
        final meetsThreshold =
            inputTerm.length >= widget.minimumSearchCharacters;

        if (!meetsThreshold) {
          if (!widget.showDefaultsWhenBelowThreshold) {
            return SizedBox.shrink();
          }
          // Show explore content with VIBE recommendations + recently joined
          return DefaultExploreContent(
            currentUserId: widget.currentUserId,
            itemBuilder: widget.itemBuilder,
          );
        }

        // Show "Search Results" label for active searches
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                widget.resultsLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppTheme.of(context).primaryBtnText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            _buildSearchResults(inputTerm),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(String inputTerm) {
    final debouncedTerm = _debouncedTerm.trim();
    final readyForSearch = debouncedTerm == inputTerm;

    if (!readyForSearch) {
      return _buildLoading();
    }

    final searchTerm = debouncedTerm.toLowerCase();
    if (kDebugMode) {
      debugPrint(
        '🔍 Golfer search: query="$searchTerm" length=${searchTerm.length}',
      );
    }
    return StreamBuilder<List<UsersRecord>>(
      stream: queryUsersRecord(
        queryBuilder: (usersRecord) => usersRecord
            .orderBy('display_name_lowercase')
            .startAt([searchTerm])
            .endAt(['${searchTerm}\uf8ff'])
            .limit(25),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoading();
        }

        final results = _filterResults(
          snapshot.data!,
          searchTerm: searchTerm,
        );
        return _buildResultsList(results);
      },
    );
  }
}
