import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

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
import '/providers/notification_provider.dart';
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

  NotificationPreferences? _prefs; // Working copy for form
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

  void _ensureControllers(NotificationPreferences prefs) {
    _gameStyleController ??= FormFieldController<List<String>>(
      _labelsForValues(
        _gameStyleOptions,
        prefs.gameAlerts.styles,
      ),
    );
    _digestController ??= FormFieldController<List<String>>([
      _labelForValue(_digestOptions, prefs.digestMode),
    ]);
  }

  Future<void> _savePreferences(NotificationProvider provider) async {
    if (currentUserReference == null || _prefs == null) {
      return;
    }

    // Save the local working copy to the provider
    await provider.updatePreferences(_prefs!);

    // Only pop if successfully synced (not offline)
    if (mounted && provider.syncStatus != SyncStatus.offline) {
      context.pop();
    } else if (mounted && provider.syncStatus == SyncStatus.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved offline. Will sync when connected.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (mounted && provider.syncStatus == SyncStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: ${provider.errorMessage ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialValue =
        isStart ? _prefs!.quietHours.start : _prefs!.quietHours.end;
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
      _prefs = _prefs!.copyWith(
        quietHours: _prefs!.quietHours.copyWith(
          start: isStart ? formatted : _prefs!.quietHours.start,
          end: isStart ? _prefs!.quietHours.end : formatted,
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

  Widget _buildPremiumPanel(
    BuildContext context, {
    String? title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.fairway.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
              thickness: 1,
            ),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildPremiumRow(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.white.withValues(alpha: 0.5);
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.sunsetGold;
              }
              return Colors.white.withValues(alpha: 0.2);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context, {
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              time,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.saving:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      case SyncStatus.synced:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(Icons.cloud_done, color: Colors.green, size: 24),
        );
      case SyncStatus.offline:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(Icons.cloud_off, color: Colors.orange, size: 24),
        );
      case SyncStatus.error:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(Icons.error, color: Colors.red, size: 24),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        return Scaffold(
          key: scaffoldKey,
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            elevation: 0.0,
            leading: GestureDetector(
              onTap: () async {
                context.pop();
              },
              child: Container(
                margin: EdgeInsets.only(left: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.fairway.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 28.0,
                ),
              ),
            ),
            title: Text(
              'Notification Settings',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              _buildSyncStatus(notificationProvider.syncStatus),
            ],
            centerTitle: false,
          ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
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
                // Initialize from provider (which loads from Firestore)
                _prefs = notificationProvider.preferences;
                _ensureControllers(_prefs!);
                _initialized = true;
              }

              // Safety check
              if (_prefs == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xxxl,
                ),
                children: [
                Text(
                  'Manage push alerts and in-app notifications.',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.0,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // PUSH NOTIFICATIONS PANEL
                _buildPremiumPanel(
                  context,
                  children: [
                    _buildPremiumRow(
                      context,
                      title: 'Push notifications',
                      subtitle: 'Allow alerts for games and chats',
                      value: _prefs!.pushEnabled,
                      onChanged: (value) async {
                        if (value) {
                          final granted = await _ensureNotificationPermission();
                          if (!granted) {
                            return;
                          }
                        }
                        setState(() {
                          _prefs = _prefs!.copyWith(pushEnabled: value);
                          if (!value) {
                            _permissionDenied = false;
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_permissionDenied) ...[
                  SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      'Push permissions are off in system settings.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: AppSpacing.lg),

                // GAME ALERTS PANEL
                _buildPremiumPanel(
                  context,
                  title: 'Game alerts',
                  children: [
                    _buildPremiumRow(
                      context,
                      title: 'Enable game alerts',
                      value: _prefs!.gameAlerts.enabled,
                      onChanged: (value) {
                        setState(() {
                          _prefs = _prefs!.copyWith(
                            gameAlerts: _prefs!.gameAlerts.copyWith(enabled: value),
                          );
                        });
                      },
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      height: 1,
                      thickness: 1,
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alert types',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
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
                                _prefs = _prefs!.copyWith(
                                  gameAlerts:
                                      _prefs!.gameAlerts.copyWith(styles: values),
                                );
                              });
                            },
                            controller: _gameStyleController!,
                            selectedChipStyle: ChipStyle(
                              backgroundColor: AppColors.sunsetGold,
                              textStyle: AppTypography.labelSmall.copyWith(
                                color: AppColors.fairwayDark,
                                fontWeight: FontWeight.w600,
                                letterSpacing: AppTypography.letterSpacingNormal,
                              ),
                              borderColor: AppColors.sunsetGold,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            unselectedChipStyle: ChipStyle(
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              textStyle: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: AppTypography.letterSpacingNormal,
                              ),
                              borderColor: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            chipSpacing: AppSpacing.sm,
                            rowSpacing: AppSpacing.xs,
                            multiselect: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                // CHAT ALERTS PANEL
                _buildPremiumPanel(
                  context,
                  title: 'Chat alerts',
                  children: [
                    _buildPremiumRow(
                      context,
                      title: 'Enable chat alerts',
                      value: _prefs!.chatAlerts.enabled,
                      onChanged: (value) {
                        setState(() {
                          _prefs = _prefs!.copyWith(
                            chatAlerts:
                                _prefs!.chatAlerts.copyWith(enabled: value),
                          );
                        });
                      },
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      height: 1,
                      thickness: 1,
                    ),
                    _buildPremiumRow(
                      context,
                      title: 'Direct messages',
                      value: _prefs!.chatAlerts.direct,
                      onChanged: (value) {
                        setState(() {
                          _prefs = _prefs!.copyWith(
                            chatAlerts: _prefs!.chatAlerts.copyWith(direct: value),
                          );
                        });
                      },
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      height: 1,
                      thickness: 1,
                    ),
                    _buildPremiumRow(
                      context,
                      title: 'Group chats',
                      value: _prefs!.chatAlerts.group,
                      onChanged: (value) {
                        setState(() {
                          _prefs = _prefs!.copyWith(
                            chatAlerts: _prefs!.chatAlerts.copyWith(group: value),
                          );
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                // QUIET HOURS PANEL
                _buildPremiumPanel(
                  context,
                  title: 'Quiet hours',
                  children: [
                    _buildPremiumRow(
                      context,
                      title: 'Enable quiet hours',
                      value: _prefs!.quietHours.enabled,
                      onChanged: (value) {
                        setState(() {
                          _prefs = _prefs!.copyWith(
                            quietHours:
                                _prefs!.quietHours.copyWith(enabled: value),
                          );
                        });
                      },
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      height: 1,
                      thickness: 1,
                    ),
                    _buildTimeRow(
                      context,
                      label: 'Start',
                      time: _prefs!.quietHours.start,
                      onTap: () => _pickTime(isStart: true),
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      height: 1,
                      thickness: 1,
                    ),
                    _buildTimeRow(
                      context,
                      label: 'End',
                      time: _prefs!.quietHours.end,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                // DIGEST MODE PANEL
                _buildPremiumPanel(
                  context,
                  title: 'Digest mode',
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: AppChoiceChips(
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
                            _prefs = _prefs!.copyWith(digestMode: value);
                          });
                        },
                        controller: _digestController!,
                        selectedChipStyle: ChipStyle(
                          backgroundColor: AppColors.sunsetGold,
                          textStyle: AppTypography.labelSmall.copyWith(
                            color: AppColors.fairwayDark,
                            fontWeight: FontWeight.w600,
                            letterSpacing: AppTypography.letterSpacingNormal,
                          ),
                          borderColor: AppColors.sunsetGold,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        unselectedChipStyle: ChipStyle(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          textStyle: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: AppTypography.letterSpacingNormal,
                          ),
                          borderColor: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        chipSpacing: AppSpacing.sm,
                        rowSpacing: AppSpacing.xs,
                        multiselect: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),

                // MUTED THREADS PANEL
                _buildPremiumPanel(
                  context,
                  children: [
                    InkWell(
                      onTap: () {
                        // TODO: Navigate to muted threads management
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Muted threads',
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${_prefs!.mutedThreads.length} muted',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xl),
                AppButtonEnhanced(
                  text: 'Save settings',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  onPressed: () => _savePreferences(notificationProvider),
                ),
              ],
            );
          },
        ),
        ),
      ),
        );
      },
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
