import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_choice_chips.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/models/notification_preferences.dart';
import '/services/notification_permission_service.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPageWidget extends StatefulWidget {
  const NotificationPageWidget({super.key});

  static String routeName = 'NotificationPage';
  static String routePath = '/notificationPage';

  @override
  State<NotificationPageWidget> createState() =>
      _NotificationPageWidgetState();
}

class _NotificationPageWidgetState extends State<NotificationPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final NotificationPermissionService _notificationPermissionService =
      NotificationPermissionService();

  NotificationPreferences _prefs = NotificationPreferences.defaults();
  bool _permissionDenied = false;
  bool _initialized = false;
  FormFieldController<List<String>>? _gameStyleController;
  FormFieldController<List<String>>? _digestController;

  static const List<_ChoiceOption> _gameStyleOptions = [
    _ChoiceOption(value: 'money', label: 'Money'),
    _ChoiceOption(value: 'vegas', label: 'Vegas'),
    _ChoiceOption(value: 'competitive', label: 'Competitive'),
    _ChoiceOption(value: 'for_fun', label: 'For Fun'),
    _ChoiceOption(value: 'friends', label: 'Friends'),
    _ChoiceOption(value: 'member_discount', label: 'Member Discount'),
  ];

  static const List<_ChoiceOption> _digestOptions = [
    _ChoiceOption(value: 'instant', label: 'Instant'),
    _ChoiceOption(value: 'hourly', label: 'Hourly'),
    _ChoiceOption(value: 'daily', label: 'Daily'),
    _ChoiceOption(value: 'off', label: 'Off'),
  ];

  Future<bool> _ensureNotificationPermission() async {
    final status =
        await _notificationPermissionService.requestPermissionAndRegister();
    if (status == NotificationPermissionStatus.granted) {
      if (mounted) {
        setState(() => _permissionDenied = false);
      }
      return true;
    }
    if (status == NotificationPermissionStatus.denied && mounted) {
      setState(() => _permissionDenied = true);
    }
    if (status != NotificationPermissionStatus.denied && mounted) {
      setState(() => _permissionDenied = false);
    }
    return false;
  }

  void _ensureControllers() {
    _gameStyleController ??= FormFieldController<List<String>>(
      _labelsForValues(
        _gameStyleOptions,
        _prefs.gameAlerts.styles,
      ),
    );
    _digestController ??= FormFieldController<List<String>>([
      _labelForValue(_digestOptions, _prefs.digestMode),
    ]);
  }

  Future<void> _savePreferences() async {
    if (currentUserReference == null) {
      return;
    }
    final data = <String, dynamic>{
      'notification_prefs': _prefs.toFirestore(),
    };
    data.addAll(_legacyNotificationFields(_prefs));
    try {
      await currentUserReference!.set(
        data,
        SetOptions(merge: true),
      );
      if (mounted) {
        context.pop();
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to save notification settings (${error.code}).',
            ),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _legacyNotificationFields(
    NotificationPreferences prefs,
  ) {
    final pushEnabled = prefs.pushEnabled;
    final gameEnabled = pushEnabled && prefs.gameAlerts.enabled;
    final styles = prefs.gameAlerts.styles.toSet();
    return {
      'notify_off': !pushEnabled,
      'notify_all': pushEnabled,
      'notify_money_game': gameEnabled && styles.contains('money'),
      'notify_vegas_game': gameEnabled && styles.contains('vegas'),
      'notify_competitive_game': gameEnabled && styles.contains('competitive'),
      'notify_for_fun': gameEnabled && styles.contains('for_fun'),
      'notify_only_from_friends': gameEnabled && styles.contains('friends'),
      'notify_member_discount': gameEnabled && styles.contains('member_discount'),
    };
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialValue =
        isStart ? _prefs.quietHours.start : _prefs.quietHours.end;
    final initialTime = _parseTime(initialValue) ?? TimeOfDay(hour: 22, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) {
      return;
    }
    final formatted = _formatTime(picked);
    setState(() {
      _prefs = _prefs.copyWith(
        quietHours: _prefs.quietHours.copyWith(
          start: isStart ? formatted : _prefs.quietHours.start,
          end: isStart ? _prefs.quietHours.end : formatted,
        ),
      );
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.of(context).primaryBackground,
        automaticallyImplyLeading: false,
        leading: AppIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 46.0,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.of(context).primaryBtnText,
            size: 25.0,
          ),
          onPressed: () async {
            context.pop();
          },
        ),
        title: Text(
          'Notification Settings',
          style: AppTheme.of(context).headlineSmall.override(
                font: GoogleFonts.outfit(
                  fontWeight:
                      AppTheme.of(context).headlineSmall.fontWeight,
                  fontStyle:
                      AppTheme.of(context).headlineSmall.fontStyle,
                ),
                letterSpacing: 0.0,
                color: AppTheme.of(context).primaryBtnText,
                fontWeight:
                    AppTheme.of(context).headlineSmall.fontWeight,
                fontStyle:
                    AppTheme.of(context).headlineSmall.fontStyle,
              ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: StreamBuilder<UsersRecord>(
          stream: currentUserReference == null
              ? null
              : UsersRecord.getDocument(currentUserReference!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            if (!_initialized) {
              final prefsMap = data.snapshotData['notification_prefs'];
              _prefs = NotificationPreferences.fromMap(
                prefsMap is Map ? Map<String, dynamic>.from(prefsMap) : null,
              );
              _ensureControllers();
              _initialized = true;
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                Text(
                  'Manage push alerts and in-app notifications.',
                  style: AppTheme.of(context).labelMedium.override(
                        font: GoogleFonts.outfit(
                          fontWeight: AppTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: AppTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: AppTheme.of(context)
                            .labelMedium
                            .fontWeight,
                        fontStyle: AppTheme.of(context)
                            .labelMedium
                            .fontStyle,
                      ),
                ),
                SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  value: _prefs.pushEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final granted = await _ensureNotificationPermission();
                      if (!granted) {
                        return;
                      }
                    }
                    setState(() {
                      _prefs = _prefs.copyWith(pushEnabled: value);
                      if (!value) {
                        _permissionDenied = false;
                      }
                    });
                  },
                  title: Text(
                    'Push notifications',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                  subtitle: Text(
                    'Allow alerts for games and chats.',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: const Color(0xFF8B97A2),
                          letterSpacing: 0.0,
                          fontWeight: AppTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                if (_permissionDenied) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.sm,
                      top: AppSpacing.xs,
                    ),
                    child: Text(
                      'Push permissions are off in system settings.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Game alerts',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.onyx,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                SwitchListTile.adaptive(
                  value: _prefs.gameAlerts.enabled,
                  onChanged: (value) {
                    setState(() {
                      _prefs = _prefs.copyWith(
                        gameAlerts: _prefs.gameAlerts.copyWith(enabled: value),
                      );
                    });
                  },
                  title: Text(
                    'Enable game alerts',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                AppChoiceChips(
                  options: _gameStyleOptions
                      .map((option) => ChipData(option.label))
                      .toList(),
                  onChanged: (labels) {
                    final values =
                        _valuesForLabels(_gameStyleOptions, labels ?? []);
                    setState(() {
                      _prefs = _prefs.copyWith(
                        gameAlerts:
                            _prefs.gameAlerts.copyWith(styles: values),
                      );
                    });
                  },
                  controller: _gameStyleController!,
                  selectedChipStyle: ChipStyle(
                    backgroundColor: AppTheme.of(context).primary,
                    textStyle: AppTypography.labelSmall.copyWith(
                      color: AppColors.pure,
                      letterSpacing: AppTypography.letterSpacingNormal,
                    ),
                    borderColor: AppTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  unselectedChipStyle: ChipStyle(
                    backgroundColor: AppTheme.of(context).secondaryBackground,
                    textStyle: AppTypography.labelSmall.copyWith(
                      color: AppColors.stone,
                      letterSpacing: AppTypography.letterSpacingNormal,
                    ),
                    borderColor: AppTheme.of(context).alternate,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  chipSpacing: AppSpacing.sm,
                  rowSpacing: AppSpacing.xs,
                  multiselect: true,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Chat alerts',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.onyx,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                SwitchListTile.adaptive(
                  value: _prefs.chatAlerts.enabled,
                  onChanged: (value) {
                    setState(() {
                      _prefs = _prefs.copyWith(
                        chatAlerts:
                            _prefs.chatAlerts.copyWith(enabled: value),
                      );
                    });
                  },
                  title: Text(
                    'Enable chat alerts',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                SwitchListTile.adaptive(
                  value: _prefs.chatAlerts.direct,
                  onChanged: (value) {
                    setState(() {
                      _prefs = _prefs.copyWith(
                        chatAlerts: _prefs.chatAlerts.copyWith(direct: value),
                      );
                    });
                  },
                  title: Text(
                    'Direct messages',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyMedium.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
                SwitchListTile.adaptive(
                  value: _prefs.chatAlerts.group,
                  onChanged: (value) {
                    setState(() {
                      _prefs = _prefs.copyWith(
                        chatAlerts: _prefs.chatAlerts.copyWith(group: value),
                      );
                    });
                  },
                  title: Text(
                    'Group chats',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyMedium.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Quiet hours',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.onyx,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                SwitchListTile.adaptive(
                  value: _prefs.quietHours.enabled,
                  onChanged: (value) {
                    setState(() {
                      _prefs = _prefs.copyWith(
                        quietHours:
                            _prefs.quietHours.copyWith(enabled: value),
                      );
                    });
                  },
                  title: Text(
                    'Enable quiet hours',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                  tileColor: AppTheme.of(context).secondaryBackground,
                  activeColor: AppTheme.of(context).primary,
                  activeTrackColor: AppTheme.of(context).accent1,
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                ListTile(
                  title: Text(
                    'Start',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyMedium.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  trailing: Text(
                    _prefs.quietHours.start,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.stone,
                    ),
                  ),
                  onTap: () => _pickTime(isStart: true),
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
                ListTile(
                  title: Text(
                    'End',
                    style: AppTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyMedium.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  trailing: Text(
                    _prefs.quietHours.end,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.stone,
                    ),
                  ),
                  onTap: () => _pickTime(isStart: false),
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Digest mode',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.onyx,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                AppChoiceChips(
                  options: _digestOptions
                      .map((option) => ChipData(option.label))
                      .toList(),
                  onChanged: (labels) {
                    final label =
                        labels != null && labels.isNotEmpty
                            ? labels.first
                            : 'Instant';
                    final value = _valueForLabel(_digestOptions, label);
                    setState(() {
                      _prefs = _prefs.copyWith(digestMode: value);
                    });
                  },
                  controller: _digestController!,
                  selectedChipStyle: ChipStyle(
                    backgroundColor: AppTheme.of(context).primary,
                    textStyle: AppTypography.labelSmall.copyWith(
                      color: AppColors.pure,
                      letterSpacing: AppTypography.letterSpacingNormal,
                    ),
                    borderColor: AppTheme.of(context).primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  unselectedChipStyle: ChipStyle(
                    backgroundColor: AppTheme.of(context).secondaryBackground,
                    textStyle: AppTypography.labelSmall.copyWith(
                      color: AppColors.stone,
                      letterSpacing: AppTypography.letterSpacingNormal,
                    ),
                    borderColor: AppTheme.of(context).alternate,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  chipSpacing: AppSpacing.sm,
                  rowSpacing: AppSpacing.xs,
                  multiselect: false,
                ),
                SizedBox(height: AppSpacing.lg),
                ListTile(
                  title: Text(
                    'Muted threads',
                    style: AppTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.outfit(
                            fontWeight: AppTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: AppTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              AppTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              AppTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                  subtitle: Text(
                    '${_prefs.mutedThreads.length} muted',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.stone,
                    ),
                  ),
                  trailing: Text(
                    'Manage',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.stone,
                    ),
                  ),
                  contentPadding: AppSpacing.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                AppButtonEnhanced(
                  text: 'Save settings',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  onPressed: _savePreferences,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChoiceOption {
  const _ChoiceOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

String _labelForValue(List<_ChoiceOption> options, String value) {
  return options.firstWhere(
    (option) => option.value == value,
    orElse: () => options.first,
  ).label;
}

String _valueForLabel(List<_ChoiceOption> options, String label) {
  return options.firstWhere(
    (option) => option.label == label,
    orElse: () => options.first,
  ).value;
}

List<String> _labelsForValues(
  List<_ChoiceOption> options,
  List<String> values,
) {
  return options
      .where((option) => values.contains(option.value))
      .map((option) => option.label)
      .toList();
}

List<String> _valuesForLabels(
  List<_ChoiceOption> options,
  List<String> labels,
) {
  return options
      .where((option) => labels.contains(option.label))
      .map((option) => option.value)
      .toList();
}
