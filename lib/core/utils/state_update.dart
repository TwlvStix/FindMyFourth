import 'package:flutter/widgets.dart';

void updateState(State state, VoidCallback mutation) {
  if (!state.mounted) {
    return;
  }
  final dynamic mutableState = state;
  mutableState.setState(mutation);
}
