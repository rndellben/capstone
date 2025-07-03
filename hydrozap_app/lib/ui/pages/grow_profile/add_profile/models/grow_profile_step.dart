enum GrowProfileStep {
  selectPlant,
  transplantingStage,
  vegetativeStage,
  maturationStage,
  finalizeProfile,
}

extension GrowProfileStepExtension on GrowProfileStep {
  String get title {
    switch (this) {
      case GrowProfileStep.selectPlant:
        return "Select Plant Profile";
      case GrowProfileStep.transplantingStage:
        return "Transplanting Stage";
      case GrowProfileStep.vegetativeStage:
        return "Vegetative Stage";
      case GrowProfileStep.maturationStage:
        return "Maturation Stage";
      case GrowProfileStep.finalizeProfile:
        return "Finalize Profile";
    }
  }

  String getTitleForMode(String mode) {
    if (this == GrowProfileStep.transplantingStage && mode == 'simple') {
      return "Optimal Conditions";
    }
    return title;
  }

  int get stepNumber {
    switch (this) {
      case GrowProfileStep.selectPlant:
        return 1;
      case GrowProfileStep.transplantingStage:
        return 2;
      case GrowProfileStep.vegetativeStage:
        return 3;
      case GrowProfileStep.maturationStage:
        return 4;
      case GrowProfileStep.finalizeProfile:
        return 5;
    }
  }

  static List<GrowProfileStep> stepsForMode(String mode) {
    if (mode == 'simple') {
      return [
        GrowProfileStep.selectPlant,
        GrowProfileStep.transplantingStage,
        GrowProfileStep.finalizeProfile,
      ];
    } else {
      return GrowProfileStep.values;
    }
  }

  static int totalStepsForMode(String mode) => stepsForMode(mode).length;
} 