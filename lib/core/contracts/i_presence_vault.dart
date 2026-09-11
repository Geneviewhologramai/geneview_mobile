import 'presence_contract.dart';

abstract class IPresenceVaultContract {
  PresenceState get state;
  void setPresence(PresenceState state);
}
