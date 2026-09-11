enum PresenceState {
  idle,
  listening,
  thinking,
  speaking,
  error,
}

enum InteractionType {
  general,
  emotional,
  philosophical,
  technical,
  command,
}

enum ConversationalProtocol {
  direct,
  empathic,
  manifesto,
  reflective,
}

abstract class IPresenceVault {
  PresenceState get currentState;
  Stream<PresenceState> get stateStream;
  void updateState(PresenceState newState);
}
