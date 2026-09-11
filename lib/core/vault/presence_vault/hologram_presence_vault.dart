import '../../contracts/presence_contract.dart';
import '../../contracts/i_presence_vault.dart';

class HologramPresenceVault implements IPresenceVaultContract {
  PresenceState _state = PresenceState.idle;

  @override
  PresenceState get state => _state;

  @override
  void setPresence(PresenceState state) {
    _state = state;
  }
}
