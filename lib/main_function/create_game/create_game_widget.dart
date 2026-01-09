import '/core/widgets/app_count_controller.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/form_field_controller.dart';
import '/core/random_data_util.dart' as random_data;
import '/main_function/games_list/games_list_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/providers/provider_extensions.dart';
import '/models/course.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';

class CreateGameWidget extends StatefulWidget {
  const CreateGameWidget({super.key});

  static String routeName = 'CreateGame';
  static String routePath = '/createGame';

  @override
  State<CreateGameWidget> createState() => _CreateGameWidgetState();
}

class _CreateGameWidgetState extends State<CreateGameWidget> {
  final formKey = GlobalKey<FormState>();
  FocusNode? gameNameFocusNode;
  TextEditingController? gameNameTextController;
  String? Function(BuildContext, String?)? gameNameTextControllerValidator;
  String? _gameNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Field is required';
    }

    return null;
  }

  DateTime? datePicked;
  String? friendsValue;
  FormFieldController<String>? friendsValueController;
  String? courseValue;
  FormFieldController<String>? courseValueController;
  Course? selectedCourse;
  String? memberValue;
  FormFieldController<String>? memberValueController;
  int? countControllerValue;
  String? rulesSetValue;
  FormFieldController<String>? rulesSetValueController;
  String? styleGameValue;
  FormFieldController<String>? styleGameValueController;
  String? gameTypeValue;
  FormFieldController<String>? gameTypeValueController;
  String? scoringValue;
  FormFieldController<String>? scoringValueController;
  DocumentReference? chatRef;
  DocumentReference? gameRef;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    gameNameTextController = TextEditingController(
        text: '${displayName}${formatNumber(
      random_data.randomInteger(0, 1000),
      formatType: FormatType.compact,
    )}');
    gameNameFocusNode = FocusNode();
    gameNameTextControllerValidator = _gameNameTextControllerValidator;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    gameNameFocusNode?.dispose();
    gameNameTextController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.of(context).primary,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: AppIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 55.0,
            icon: Icon(
              Icons.arrow_back_sharp,
              color: AppTheme.of(context).primary,
              size: 25.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Create Game',
            style: AppTheme.of(context).headlineLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                  ),
                  color: AppTheme.of(context).primary,
                  fontSize: 24.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                ),
          ),
          centerTitle: false,
          elevation: 10.0,
        ),
        body: SafeArea(
          top: true,
          child: FairwayBackgroundDark(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: double.infinity,
                      child: Form(
                        key: formKey,
                        autovalidateMode: AutovalidateMode.always,
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              AppSpacing.sm, 0.0, AppSpacing.sm, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 10.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      'Game Name',
                                      style: AppTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 5.0, 0.0, 0.0),
                                child: TextFormField(
                                  controller: gameNameTextController,
                                  focusNode: gameNameFocusNode,
                                  onChanged: (_) => EasyDebounce.debounce(
                                    'gameNameTextController',
                                    Duration(milliseconds: 2000),
                                    () {
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                  autofocus: true,
                                  textCapitalization: TextCapitalization.none,
                                  textInputAction: TextInputAction.next,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelStyle: AppTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .labelMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .labelMedium
                                              .fontStyle,
                                        ),
                                    hintStyle: AppTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                          color: Colors.white,
                                          fontSize: 15.0,
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .labelMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .labelMedium
                                              .fontStyle,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppTheme.of(context).primary,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppTheme.of(context).error,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppTheme.of(context).error,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    suffixIcon: gameNameTextController!
                                            .text.isNotEmpty
                                        ? InkWell(
                                            onTap: () async {
                                              gameNameTextController?.clear();
                                              if (mounted) {
                                                setState(() {});
                                              }
                                            },
                                            child: Icon(
                                              Icons.clear,
                                              color: Colors.white,
                                              size: 20.0,
                                            ),
                                          )
                                        : null,
                                  ),
                                  style:
                                      AppTheme.of(context).bodyMedium.override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w500,
                                              fontStyle: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                            ),
                                            color: Colors.white,
                                            fontSize: 15.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                  maxLength: 200,
                                  maxLengthEnforcement:
                                      MaxLengthEnforcement.enforced,
                                  buildCounter: (context,
                                          {required currentLength,
                                          required isFocused,
                                          maxLength}) =>
                                      null,
                                  cursorColor: Colors.white,
                                  validator: gameNameTextControllerValidator
                                      .asValidator(context),
                                  inputFormatters: [
                                    if (!isAndroid && !isiOS)
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        return TextEditingValue(
                                          selection: newValue.selection,
                                          text: newValue.text.toCapitalization(
                                              TextCapitalization.none),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 5.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      'Game Day',
                                      style: AppTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 15.0),
                                  child: Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height: 100.0,
                                    decoration: BoxDecoration(
                                      color: AppTheme.of(context).tertiary,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, AppSpacing.sm, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    AppSpacing.sm,
                                                    0.0,
                                                    0.0,
                                                    0.0),
                                            child: Container(
                                              width: MediaQuery.sizeOf(context)
                                                      .width *
                                                  0.65,
                                              height: 85.0,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFA0A0A0),
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(15.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          valueOrDefault<
                                                              String>(
                                                            dateTimeFormat(
                                                                "MMM",
                                                                datePicked),
                                                            'Jan',
                                                          ),
                                                          style: AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                fontSize: 22.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                        Text(
                                                          valueOrDefault<
                                                              String>(
                                                            dateTimeFormat("d",
                                                                datePicked),
                                                            '22',
                                                          ),
                                                          style: AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                fontSize: 26.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 20.0,
                                                    child: VerticalDivider(
                                                      thickness: 1.0,
                                                      color:
                                                          AppTheme.of(context)
                                                              .accent4,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(10.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          valueOrDefault<
                                                              String>(
                                                            dateTimeFormat(
                                                                "EEEE",
                                                                datePicked),
                                                            'Friday',
                                                          ),
                                                          style: AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                fontSize: 22.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                        Text(
                                                          valueOrDefault<
                                                              String>(
                                                            dateTimeFormat("jm",
                                                                datePicked),
                                                            '09:00am',
                                                          ),
                                                          style: AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                fontSize: 22.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    AppSpacing.sm,
                                                    0.0,
                                                    0.0,
                                                    0.0),
                                            child: InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                final _datePickedDate =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate:
                                                      getCurrentTimestamp,
                                                  firstDate:
                                                      getCurrentTimestamp,
                                                  lastDate: DateTime(2050),
                                                  builder: (context, child) {
                                                    return wrapInMaterialDatePickerTheme(
                                                      context,
                                                      child!,
                                                      headerBackgroundColor:
                                                          AppTheme.of(context)
                                                              .primary,
                                                      headerForegroundColor:
                                                          AppTheme.of(context)
                                                              .info,
                                                      headerTextStyle:
                                                          AppTheme.of(context)
                                                              .headlineLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .headlineLarge
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 32.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .headlineLarge
                                                                    .fontStyle,
                                                              ),
                                                      pickerBackgroundColor:
                                                          AppTheme.of(context)
                                                              .secondaryBackground,
                                                      pickerForegroundColor:
                                                          AppTheme.of(context)
                                                              .primaryText,
                                                      selectedDateTimeBackgroundColor:
                                                          AppTheme.of(context)
                                                              .primary,
                                                      selectedDateTimeForegroundColor:
                                                          AppTheme.of(context)
                                                              .info,
                                                      actionButtonForegroundColor:
                                                          AppTheme.of(context)
                                                              .primaryText,
                                                      iconSize: 24.0,
                                                    );
                                                  },
                                                );

                                                TimeOfDay? _datePickedTime;
                                                if (_datePickedDate != null) {
                                                  _datePickedTime =
                                                      await showTimePicker(
                                                    context: context,
                                                    initialTime:
                                                        TimeOfDay.fromDateTime(
                                                            getCurrentTimestamp),
                                                    builder: (context, child) {
                                                      return wrapInMaterialTimePickerTheme(
                                                        context,
                                                        child!,
                                                        headerBackgroundColor:
                                                            AppTheme.of(context)
                                                                .primary,
                                                        headerForegroundColor:
                                                            AppTheme.of(context)
                                                                .info,
                                                        headerTextStyle:
                                                            AppTheme.of(context)
                                                                .headlineLarge
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontStyle: AppTheme.of(
                                                                            context)
                                                                        .headlineLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  fontSize:
                                                                      32.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .headlineLarge
                                                                      .fontStyle,
                                                                ),
                                                        pickerBackgroundColor:
                                                            AppTheme.of(context)
                                                                .secondaryBackground,
                                                        pickerForegroundColor:
                                                            AppTheme.of(context)
                                                                .primaryText,
                                                        selectedDateTimeBackgroundColor:
                                                            AppTheme.of(context)
                                                                .primary,
                                                        selectedDateTimeForegroundColor:
                                                            AppTheme.of(context)
                                                                .info,
                                                        actionButtonForegroundColor:
                                                            AppTheme.of(context)
                                                                .primaryText,
                                                        iconSize: 24.0,
                                                      );
                                                    },
                                                  );
                                                }

                                                if (_datePickedDate != null &&
                                                    _datePickedTime != null) {
                                                  if (mounted)
                                                    setState(() {
                                                      datePicked = DateTime(
                                                        _datePickedDate.year,
                                                        _datePickedDate.month,
                                                        _datePickedDate.day,
                                                        _datePickedTime!.hour,
                                                        _datePickedTime.minute,
                                                      );
                                                    });
                                                } else if (datePicked != null) {
                                                  if (mounted)
                                                    setState(() {
                                                      datePicked =
                                                          getCurrentTimestamp;
                                                    });
                                                }
                                              },
                                              child: Icon(
                                                Icons.date_range,
                                                color: AppTheme.of(context)
                                                    .primaryBtnText,
                                                size: 36.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: Text(
                                    'Friends Only?',
                                    style: AppTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .labelMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .labelMedium
                                              .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: AppDropDown<String>(
                                    controller: friendsValueController ??=
                                        FormFieldController<String>(null),
                                    options: ['Friends', 'Public'],
                                    onChanged: (val) {
                                      if (mounted) {
                                        setState(() => friendsValue = val);
                                      }
                                    },
                                    width: 300.0,
                                    height: 50.0,
                                    textStyle: AppTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .bodyMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .bodyMedium
                                              .fontStyle,
                                        ),
                                    hintText: 'Please select...',
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.of(context).secondaryText,
                                      size: 24.0,
                                    ),
                                    fillColor: AppTheme.of(context)
                                        .secondaryBackground,
                                    elevation: 2.0,
                                    borderColor: AppTheme.of(context).primary,
                                    borderWidth: 1.0,
                                    borderRadius: 8.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        AppSpacing.md, 4.0, AppSpacing.md, 4.0),
                                    hidesUnderline: true,
                                    isOverButton: true,
                                    isSearchable: false,
                                    isMultiSelect: false,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 5.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 5.0, 0.0, 0.0),
                                      child: Text(
                                        'Course',
                                        style: AppTheme.of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                              ),
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance
                                        .collection('course')
                                        .orderBy('name')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      // Customize what your widget looks like when it's loading.
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: SizedBox(
                                            width: 50.0,
                                            height: 50.0,
                                            child: SpinKitWanderingCubes(
                                              color: AppTheme.of(context)
                                                  .secondary,
                                              size: 50.0,
                                            ),
                                          ),
                                        );
                                      }
                                      final courseCourseRecordList = snapshot
                                          .data!.docs
                                          .map((doc) => Course.fromDoc(doc))
                                          .toList();

                                      return AppDropDown<String>(
                                        controller: courseValueController ??=
                                            FormFieldController<String>(null),
                                        options: courseCourseRecordList
                                            .map((e) => e.name)
                                            .toList(),
                                        onChanged: (val) async {
                                          if (mounted)
                                            setState(() => courseValue = val);
                                          selectedCourse =
                                              courseCourseRecordList
                                                  .firstWhereOrNull((course) =>
                                                      course.name == val);

                                          if (mounted) setState(() {});
                                        },
                                        width: 300.0,
                                        height: 50.0,
                                        searchHintTextStyle: AppTheme.of(
                                                context)
                                            .labelMedium
                                            .override(
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
                                        searchTextStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                            ),
                                        textStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                            ),
                                        hintText: 'Where are you playing?',
                                        searchHintText: 'Find your course',
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppTheme.of(context)
                                              .secondaryText,
                                          size: 24.0,
                                        ),
                                        fillColor: AppTheme.of(context)
                                            .secondaryBackground,
                                        elevation: 2.0,
                                        borderColor:
                                            AppTheme.of(context).primary,
                                        borderWidth: 1.0,
                                        borderRadius: 10.0,
                                        margin: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 4.0, 16.0, 4.0),
                                        hidesUnderline: true,
                                        isOverButton: true,
                                        isSearchable: true,
                                        isMultiSelect: false,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 15.0, 0.0, 0.0),
                                  child: Text(
                                    'Member Perk',
                                    style: AppTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .labelMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .labelMedium
                                              .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: AppDropDown<String>(
                                    controller: memberValueController ??=
                                        FormFieldController<String>(null),
                                    options: ['Yes', 'No'],
                                    onChanged: (val) {
                                      if (mounted) {
                                        setState(() => memberValue = val);
                                      }
                                    },
                                    width: 300.0,
                                    height: 50.0,
                                    searchHintTextStyle: AppTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .labelMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .labelMedium
                                              .fontStyle,
                                        ),
                                    searchTextStyle: AppTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .bodyMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .bodyMedium
                                              .fontStyle,
                                        ),
                                    textStyle: AppTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .bodyMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .bodyMedium
                                              .fontStyle,
                                        ),
                                    hintText:
                                        'Is there a Member Guest Discount?',
                                    searchHintText: 'Find your course',
                                    searchCursorColor: Colors.white,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.of(context).secondaryText,
                                      size: 24.0,
                                    ),
                                    fillColor: AppTheme.of(context)
                                        .secondaryBackground,
                                    elevation: 2.0,
                                    borderColor: AppTheme.of(context).primary,
                                    borderWidth: 1.0,
                                    borderRadius: 10.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        AppSpacing.md, 4.0, AppSpacing.md, 4.0),
                                    hidesUnderline: true,
                                    isOverButton: true,
                                    isSearchable: true,
                                    isMultiSelect: false,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 5.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: Text(
                                        'Number of Players Needed?',
                                        style: AppTheme.of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                              ),
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: Container(
                                    width: 160.0,
                                    height: 50.0,
                                    decoration: BoxDecoration(
                                      color: AppTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: AppTheme.of(context).primary,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: AppCountController(
                                      decrementIconBuilder: (enabled) => FaIcon(
                                        FontAwesomeIcons.minus,
                                        color: enabled
                                            ? AppTheme.of(context).secondaryText
                                            : AppTheme.of(context).alternate,
                                        size: 20.0,
                                      ),
                                      incrementIconBuilder: (enabled) => FaIcon(
                                        FontAwesomeIcons.plus,
                                        color: enabled
                                            ? AppTheme.of(context).primary
                                            : AppTheme.of(context).alternate,
                                        size: 20.0,
                                      ),
                                      countBuilder: (count) => Text(
                                        count.toString(),
                                        style: AppTheme.of(context)
                                            .titleLarge
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .titleLarge
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .titleLarge
                                                    .fontStyle,
                                              ),
                                              fontSize: 18.0,
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .titleLarge
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                            ),
                                      ),
                                      count: countControllerValue ??= 1,
                                      updateCount: (count) {
                                        if (mounted) {
                                          setState(() =>
                                              countControllerValue = count);
                                        }
                                      },
                                      stepSize: 1,
                                      minimum: 1,
                                      maximum: 3,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 15.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      'Rules Settings',
                                      style: AppTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: AppDropDown<String>(
                                    controller: rulesSetValueController ??=
                                        FormFieldController<String>(null),
                                    options: [
                                      'Strict',
                                      'Relaxed',
                                      'Open to Discuss'
                                    ],
                                    onChanged: (val) {
                                      if (mounted) {
                                        setState(() => rulesSetValue = val);
                                      }
                                    },
                                    width: 300.0,
                                    height: 50.0,
                                    textStyle: AppTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .bodyMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .bodyMedium
                                              .fontStyle,
                                        ),
                                    hintText: 'Please select...',
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.of(context).secondaryText,
                                      size: 24.0,
                                    ),
                                    fillColor: AppTheme.of(context)
                                        .secondaryBackground,
                                    elevation: 2.0,
                                    borderColor: AppTheme.of(context).primary,
                                    borderWidth: 1.0,
                                    borderRadius: 8.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        AppSpacing.md, 4.0, AppSpacing.md, 4.0),
                                    hidesUnderline: true,
                                    isOverButton: true,
                                    isSearchable: false,
                                    isMultiSelect: false,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 20.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 5.0, 0.0, 0.0),
                                        child: Text(
                                          'Style of Game',
                                          style: AppTheme.of(context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight:
                                                      AppTheme.of(context)
                                                          .labelMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      AppTheme.of(context)
                                                          .labelMedium
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight: AppTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: AppDropDown<String>(
                                    controller: styleGameValueController ??=
                                        FormFieldController<String>(null),
                                    options: [
                                      'Money Game',
                                      'All Fun',
                                      'Open to Discuss'
                                    ],
                                    onChanged: (val) {
                                      if (mounted) {
                                        setState(() => styleGameValue = val);
                                      }
                                    },
                                    width: 300.0,
                                    height: 50.0,
                                    textStyle: AppTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .bodyMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .bodyMedium
                                              .fontStyle,
                                        ),
                                    hintText: 'What are we playing for?',
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.of(context).secondaryText,
                                      size: 24.0,
                                    ),
                                    fillColor: AppTheme.of(context)
                                        .secondaryBackground,
                                    elevation: 2.0,
                                    borderColor: AppTheme.of(context).primary,
                                    borderWidth: 1.0,
                                    borderRadius: 8.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        AppSpacing.md, 4.0, AppSpacing.md, 4.0),
                                    hidesUnderline: true,
                                    isOverButton: true,
                                    isSearchable: false,
                                    isMultiSelect: false,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 20.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      'Game Type',
                                      style: AppTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: AppDropDown<String>(
                                    controller: gameTypeValueController ??=
                                        FormFieldController<String>(null),
                                    options: [
                                      'Match Play',
                                      'Stroke Play',
                                      'Stableford',
                                      'Vegas',
                                      'Skins',
                                      'For Fun',
                                      'Open to Discuss'
                                    ],
                                    onChanged: (val) {
                                      if (mounted) {
                                        setState(() => gameTypeValue = val);
                                      }
                                    },
                                    width: 300.0,
                                    height: 50.0,
                                    textStyle: AppTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .bodyMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .bodyMedium
                                              .fontStyle,
                                        ),
                                    hintText: 'Pick Your Poison...',
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.of(context).secondaryText,
                                      size: 24.0,
                                    ),
                                    fillColor: AppTheme.of(context)
                                        .secondaryBackground,
                                    elevation: 2.0,
                                    borderColor: AppTheme.of(context).primary,
                                    borderWidth: 1.0,
                                    borderRadius: 10.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        AppSpacing.md, 4.0, AppSpacing.md, 4.0),
                                    hidesUnderline: true,
                                    isOverButton: true,
                                    isSearchable: false,
                                    isMultiSelect: false,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 20.0, 0.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      'Scoring',
                                      style: AppTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                            fontWeight: AppTheme.of(context)
                                                .labelMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .labelMedium
                                                .fontStyle,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 5.0, 0.0, 0.0),
                                  child: AppDropDown<String>(
                                    controller: scoringValueController ??=
                                        FormFieldController<String>(null),
                                    options: [
                                      'Gross',
                                      'Net',
                                      'Both',
                                      'Game',
                                      'FUN'
                                    ],
                                    onChanged: (val) {
                                      if (mounted) {
                                        setState(() => scoringValue = val);
                                      }
                                    },
                                    width: 300.0,
                                    height: 50.0,
                                    textStyle: AppTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: AppTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                            fontStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: AppTheme.of(context)
                                              .bodyMedium
                                              .fontWeight,
                                          fontStyle: AppTheme.of(context)
                                              .bodyMedium
                                              .fontStyle,
                                        ),
                                    hintText: 'How we add up the #\'s',
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.of(context).secondaryText,
                                      size: 24.0,
                                    ),
                                    fillColor: AppTheme.of(context)
                                        .secondaryBackground,
                                    elevation: 2.0,
                                    borderColor: AppTheme.of(context).primary,
                                    borderWidth: 1.0,
                                    borderRadius: 10.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        AppSpacing.md, 4.0, AppSpacing.md, 4.0),
                                    hidesUnderline: true,
                                    isOverButton: true,
                                    isSearchable: false,
                                    isMultiSelect: false,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 30.0, 0.0, 0.0),
                                child: AppButtonEnhanced(
                                  text: 'Submit Game',
                                  variant: AppButtonVariant.primary,
                                  size: AppButtonSize.large,
                                  onPressed: () async {
                                    debugPrint('🎮 CREATE GAME: Submit button clicked');

                                    if (formKey.currentState == null ||
                                        !formKey.currentState!.validate()) {
                                      debugPrint('❌ CREATE GAME: Form validation failed');
                                      return;
                                    }
                                    debugPrint('✅ CREATE GAME: Form validation passed');

                                    if (courseValue == null) {
                                      debugPrint('❌ CREATE GAME: courseValue is null');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please select a course'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    if (friendsValue == null) {
                                      debugPrint('❌ CREATE GAME: friendsValue is null');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please select Friends or Public game'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    if (rulesSetValue == null) {
                                      debugPrint('❌ CREATE GAME: rulesSetValue is null');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please select a rules setting'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    if (styleGameValue == null) {
                                      debugPrint('❌ CREATE GAME: styleGameValue is null');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please select a game style'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    if (gameTypeValue == null) {
                                      debugPrint('❌ CREATE GAME: gameTypeValue is null');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please select a game type'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    debugPrint('✅ CREATE GAME: All dropdown values present');

                                    if (datePicked == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Please select a date and time.',
                                            style: AppTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  font: GoogleFonts.outfit(
                                                    fontWeight:
                                                        AppTheme.of(context)
                                                            .titleMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .titleMedium
                                                            .fontStyle,
                                                  ),
                                                  color: AppTheme.of(context)
                                                      .secondaryBackground,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      AppTheme.of(context)
                                                          .titleMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      AppTheme.of(context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          duration:
                                              Duration(milliseconds: 4000),
                                          backgroundColor:
                                              AppTheme.of(context).primary,
                                        ),
                                      );
                                      return;
                                    }

                                    debugPrint('✅ CREATE GAME: Date validation passed');

                                    debugPrint('🎮 CREATE GAME: Starting game creation...');
                                    debugPrint('🎮 CREATE GAME: Game name: ${gameNameTextController.text}');
                                    debugPrint('🎮 CREATE GAME: Course: $courseValue');
                                    debugPrint('🎮 CREATE GAME: Date: $datePicked');
                                    debugPrint('🎮 CREATE GAME: Style: $styleGameValue');
                                    debugPrint('🎮 CREATE GAME: Type: $gameTypeValue');
                                    debugPrint('🎮 CREATE GAME: Friends: $friendsValue');
                                    debugPrint('🎮 CREATE GAME: Rules: $rulesSetValue');
                                    debugPrint('🎮 CREATE GAME: Player count: ${countControllerValue ?? 0}');

                                    try {
                                      debugPrint('🎮 CREATE GAME: Checking authentication...');
                                      final currentUser =
                                          FirebaseAuth.instance.currentUser;
                                      if (currentUser == null) {
                                        debugPrint('❌ CREATE GAME: User not authenticated');

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please sign in to create a game.',
                                              style: AppTheme.of(context)
                                                  .titleMedium
                                                  .override(
                                                    font: GoogleFonts.outfit(
                                                      fontWeight:
                                                          AppTheme.of(context)
                                                              .titleMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .titleMedium
                                                              .fontStyle,
                                                    ),
                                                    color: AppTheme.of(context)
                                                        .secondaryBackground,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        AppTheme.of(context)
                                                            .titleMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .titleMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                            duration:
                                                Duration(milliseconds: 4000),
                                            backgroundColor:
                                                AppTheme.of(context).primary,
                                          ),
                                        );
                                        return;
                                      }
                                      debugPrint('✅ CREATE GAME: User authenticated: ${currentUser.uid}');

                                      final currentUserRef = FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(currentUser.uid);
                                      final numPlayers =
                                          countControllerValue ?? 0;
                                      // Golf games are always 4 players total
                                      // Formula: 1 (creator) + existing friends + numPlayers (randoms) = 4
                                      final maxPlayers = 4;
                                      debugPrint(
                                        'CreateGame: creating game ${gameNameTextController.text}',
                                      );
                                      debugPrint(
                                        'CreateGame: numPlayers=$numPlayers (randoms needed), maxPlayers=$maxPlayers',
                                      );
                                      // Create game doc reference first (before creating chat)
                                      final gamesRecordReference =
                                          FirebaseFirestore.instance
                                              .collection('games')
                                              .doc();

                                      // Create chat with gameId
                                      debugPrint('🎮 CREATE GAME: Creating game chat...');
                                      debugPrint('🎮 CREATE GAME: Game ID: ${gamesRecordReference.id}');
                                      debugPrint('🎮 CREATE GAME: Creator UID: ${currentUser.uid}');

                                      try {
                                        final chatsRecordReference =
                                            await context
                                                .read<ChatProvider>()
                                                .createGameChat(
                                                  createdByUid: currentUser.uid,
                                                  gameId: gamesRecordReference.id,
                                                );
                                        chatRef = chatsRecordReference;
                                        debugPrint('✅ CREATE GAME: Game chat created: ${chatsRecordReference.id}');
                                      } catch (chatError, chatStackTrace) {
                                        debugPrint('❌ CREATE GAME: Chat creation failed!');
                                        debugPrint('❌ CREATE GAME: Error type: ${chatError.runtimeType}');
                                        debugPrint('❌ CREATE GAME: Error: $chatError');
                                        debugPrintStack(stackTrace: chatStackTrace);
                                        throw Exception('Failed to create game chat: $chatError');
                                      }

                                      // Now set game data
                                      debugPrint('🎮 CREATE GAME: Saving game to Firestore...');
                                      debugPrint('🎮 CREATE GAME: Path: ${gamesRecordReference.path}');

                                      try {
                                        await gamesRecordReference.set({
                                        'name_game':
                                            gameNameTextController.text,
                                        'date': datePicked,
                                        'num_players': numPlayers,
                                        'style_game': styleGameValue,
                                        'game_type': gameTypeValue,
                                        'course_play': courseValue,
                                        'member_discount': memberValue,
                                        'scoring': scoringValue,
                                        'friend_game': friendsValue,
                                        'max_players': maxPlayers,
                                        'rules_setting': rulesSetValue,
                                        'created_time': DateTime.now(),
                                        'chatRef': chatRef,
                                        'userRef': currentUserRef,
                                        'courseRef': selectedCourse?.reference,
                                        'isCancelled': false,
                                        'joined_players': [currentUserRef],
                                        'guest_players': [],
                                        'uid': currentUser.uid,
                                      });
                                        gameRef = gamesRecordReference;
                                        debugPrint('✅ CREATE GAME: Game saved to Firestore successfully');
                                        debugPrint('CreateGame: game saved ${gamesRecordReference.path}');
                                      } catch (saveError, saveStackTrace) {
                                        debugPrint('❌ CREATE GAME: Game save failed!');
                                        debugPrint('❌ CREATE GAME: Error type: ${saveError.runtimeType}');
                                        debugPrint('❌ CREATE GAME: Error: $saveError');
                                        debugPrintStack(stackTrace: saveStackTrace);
                                        throw Exception('Failed to save game data: $saveError');
                                      }
                                      await Future.wait([
                                        Future(() async {
                                          context.userProvider
                                              .refreshAvailableGames();
                                          context.userProvider.refreshMyGames();
                                          debugPrint(
                                            'CreateGame: refreshed game caches',
                                          );

                                          // Calculate number of existing friends to add
                                          // Formula: 4 - numPlayers - 1 (creator)
                                          final numExistingFriends =
                                              4 - numPlayers - 1;

                                          debugPrint(
                                            'CreateGame: numPlayers=$numPlayers, existingFriends=$numExistingFriends',
                                          );

                                          // If no existing friends to add (playing solo, looking for 3 randoms), go to Game List
                                          if (numExistingFriends <= 0) {
                                            debugPrint(
                                              'CreateGame: No existing friends, skipping Player List',
                                            );
                                            context.pushNamed(
                                                GamesListWidget.routeName);
                                          } else {
                                            // Otherwise go to Player List to add existing friends
                                            debugPrint(
                                              'CreateGame: Has $numExistingFriends existing friends, showing Player List',
                                            );
                                            context.pushNamed(
                                              PlayerListWidget.routeName,
                                              extra: <String, dynamic>{
                                                'gameRef': gamesRecordReference,
                                                kTransitionInfoKey:
                                                    TransitionInfo(
                                                  hasTransition: true,
                                                  transitionType:
                                                      PageTransitionType
                                                          .bottomToTop,
                                                  duration: Duration(
                                                      milliseconds: 220),
                                                ),
                                              },
                                            );
                                          }

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'You have created a game!',
                                                style: AppTheme.of(context)
                                                    .titleMedium
                                                    .override(
                                                      font: GoogleFonts.outfit(
                                                        fontWeight:
                                                            AppTheme.of(context)
                                                                .titleMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            AppTheme.of(context)
                                                                .titleMedium
                                                                .fontStyle,
                                                      ),
                                                      color: AppTheme.of(
                                                              context)
                                                          .secondaryBackground,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          AppTheme.of(context)
                                                              .titleMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .titleMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                              duration:
                                                  Duration(milliseconds: 4000),
                                              backgroundColor:
                                                  AppTheme.of(context).primary,
                                            ),
                                          );
                                        }),
                                      ]);
                                    } catch (error, stackTrace) {
                                      debugPrint('❌ CREATE GAME: FAILED TO CREATE GAME');
                                      debugPrint('❌ CREATE GAME: Error type: ${error.runtimeType}');
                                      debugPrint('❌ CREATE GAME: Error message: $error');
                                      debugPrint('❌ CREATE GAME: Stack trace:');
                                      debugPrintStack(stackTrace: stackTrace);

                                      // Extract meaningful error message
                                      String errorMsg = error.toString();
                                      if (errorMsg.length > 100) {
                                        errorMsg = errorMsg.substring(0, 100) + '...';
                                      }

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to create game: $errorMsg',
                                            style: AppTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  font: GoogleFonts.outfit(
                                                    fontWeight:
                                                        AppTheme.of(context)
                                                            .titleMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .titleMedium
                                                            .fontStyle,
                                                  ),
                                                  color: Colors.white,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      AppTheme.of(context)
                                                          .titleMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      AppTheme.of(context)
                                                          .titleMedium
                                                          .fontStyle,
                                                ),
                                          ),
                                          duration:
                                              Duration(milliseconds: 6000), // Longer to read error
                                          backgroundColor: Colors.red, // Red for errors
                                        ),
                                      );
                                      return;
                                    }

                                    if (mounted) setState(() {});
                                  },
                                ),
                              ),
                            ]
                                .divide(SizedBox(height: AppSpacing.xs))
                                .addToStart(SizedBox(height: AppSpacing.xs))
                                .addToEnd(SizedBox(height: AppSpacing.xs)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
