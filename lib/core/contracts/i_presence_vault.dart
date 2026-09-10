import 'package:geneview_mobile/core/contracts/i_presence_vault.dart';

class HologramPresenceVault implements IPresenceVault {
  PresenceState _currentState = PresenceState.idle;

  @override
  PresenceState get currentState => _currentState;

  @override
  void updateState(PresenceState state) {
    _currentState = state;
  }
}