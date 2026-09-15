enum OnboardingPhase { greeting, hardwareVerification, networkSetup, complete }

class FirstRunDialogue {
  OnboardingPhase currentPhase = OnboardingPhase.greeting;

  void advance() {
    if (currentPhase == OnboardingPhase.greeting) {
      currentPhase = OnboardingPhase.hardwareVerification;
    } else if (currentPhase == OnboardingPhase.hardwareVerification) {
      currentPhase = OnboardingPhase.networkSetup;
    } else {
      currentPhase = OnboardingPhase.complete;
    }
  }

  bool isCompleted() => currentPhase == OnboardingPhase.complete;
}
