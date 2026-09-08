import 'package:flutter/foundation.dart';
import '../../core/contracts/i_presence_vault.dart';

class HologramPresenceVault extends ChangeNotifier implements IPresenceVault {
  PresenceState _currentState = PresenceState.idle;

  @override
  PresenceState get currentState => _currentState;

  @override
  void updateState(PresenceState state) {
    if (_currentState != state) {
      _currentState = state;
      notifyListeners();
    }
  }
}