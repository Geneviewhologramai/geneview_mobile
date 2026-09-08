enum PresenceState { idle, listening, thinking, speaking }

abstract class IPresenceVault {
  PresenceState get currentState;
  void updateState(PresenceState state);
}