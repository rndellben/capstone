// Dosing Calculator service for pH and nutrient dosing
class DosingCalculator {
  // Default adjustment factors per liter - these could be configurable in the future
  static const double PH_UP_FACTOR_ML_PER_LITER = 0.5; // ml per liter for 0.5 pH point adjustment
  static const double PH_DOWN_FACTOR_ML_PER_LITER = 0.3; // ml per liter for 0.5 pH point adjustment
  static const double NUTRIENT_A_FACTOR_ML_PER_LITER = 2.0; // ml per liter for standard concentration
  static const double NUTRIENT_B_FACTOR_ML_PER_LITER = 2.0; // ml per liter for standard concentration
  static const double NUTRIENT_C_FACTOR_ML_PER_LITER = 1.0; // ml per liter for standard concentration
  
  // Maximum supported water volume in liters
  static const double MAX_SUPPORTED_VOLUME = 1000.0; // 1000L is a reasonable upper limit
  
  // Calculate pH Up dosing amount
  static double calculatePhUpDose({
    required double waterVolumeInLiters, 
    required double currentPh,
    required double targetPh,
  }) {
    if (waterVolumeInLiters <= 0 || currentPh >= targetPh) {
      return 0.0;
    }
    
    // Safety check for reasonable values
    if (waterVolumeInLiters > MAX_SUPPORTED_VOLUME) {
      return 0.0;
    }
    
    // Calculate required pH adjustment
    double pHAdjustment = targetPh - currentPh;
    
    // Calculate dosing amount based on adjustment
    double doseML = (pHAdjustment / 0.5) * PH_UP_FACTOR_ML_PER_LITER * waterVolumeInLiters;
    
    // Ensure we don't return negative values
    return doseML > 0 ? doseML : 0.0;
  }
  
  // Calculate pH Down dosing amount
  static double calculatePhDownDose({
    required double waterVolumeInLiters, 
    required double currentPh,
    required double targetPh,
  }) {
    if (waterVolumeInLiters <= 0 || currentPh <= targetPh) {
      return 0.0;
    }
    
    // Safety check for reasonable values
    if (waterVolumeInLiters > MAX_SUPPORTED_VOLUME) {
      return 0.0;
    }
    
    // Calculate required pH adjustment
    double pHAdjustment = currentPh - targetPh;
    
    // Calculate dosing amount based on adjustment
    double doseML = (pHAdjustment / 0.5) * PH_DOWN_FACTOR_ML_PER_LITER * waterVolumeInLiters;
    
    // Ensure we don't return negative values
    return doseML > 0 ? doseML : 0.0;
  }
  
  // Calculate Nutrient A dosing amount
  static double calculateNutrientADose({
    required double waterVolumeInLiters,
    required double currentEC,
    required double targetEC,
    double? customFactorPerLiter,
  }) {
    if (waterVolumeInLiters <= 0 || currentEC >= targetEC) {
      return 0.0;
    }
    
    // Safety check for reasonable values
    if (waterVolumeInLiters > MAX_SUPPORTED_VOLUME) {
      return 0.0;
    }
    
    // Calculate EC adjustment
    double ecAdjustment = targetEC - currentEC;
    
    // Use custom factor if provided, otherwise use default
    double factorPerLiter = customFactorPerLiter ?? NUTRIENT_A_FACTOR_ML_PER_LITER;
    
    // Calculate dosing amount based on EC adjustment
    // This is a simplified model - in reality, the relationship may be non-linear
    double doseML = (ecAdjustment / 0.1) * factorPerLiter * waterVolumeInLiters;
    
    // Ensure we don't return negative values
    return doseML > 0 ? doseML : 0.0;
  }
  
  // Calculate Nutrient B dosing amount
  static double calculateNutrientBDose({
    required double waterVolumeInLiters,
    required double currentEC,
    required double targetEC,
    double? customFactorPerLiter,
  }) {
    if (waterVolumeInLiters <= 0 || currentEC >= targetEC) {
      return 0.0;
    }
    
    // Safety check for reasonable values
    if (waterVolumeInLiters > MAX_SUPPORTED_VOLUME) {
      return 0.0;
    }
    
    // Calculate EC adjustment
    double ecAdjustment = targetEC - currentEC;
    
    // Use custom factor if provided, otherwise use default
    double factorPerLiter = customFactorPerLiter ?? NUTRIENT_B_FACTOR_ML_PER_LITER;
    
    // Calculate dosing amount based on EC adjustment
    // This is a simplified model - in reality, the relationship may be non-linear
    double doseML = (ecAdjustment / 0.1) * factorPerLiter * waterVolumeInLiters;
    
    // Ensure we don't return negative values
    return doseML > 0 ? doseML : 0.0;
  }
  
  // Calculate Nutrient C dosing amount
  static double calculateNutrientCDose({
    required double waterVolumeInLiters,
    required double currentEC,
    required double targetEC,
    double? customFactorPerLiter,
  }) {
    if (waterVolumeInLiters <= 0 || currentEC >= targetEC) {
      return 0.0;
    }
    
    // Safety check for reasonable values
    if (waterVolumeInLiters > MAX_SUPPORTED_VOLUME) {
      return 0.0;
    }
    
    // Calculate EC adjustment
    double ecAdjustment = targetEC - currentEC;
    
    // Use custom factor if provided, otherwise use default
    double factorPerLiter = customFactorPerLiter ?? NUTRIENT_C_FACTOR_ML_PER_LITER;
    
    // Calculate dosing amount based on EC adjustment
    // This is a simplified model - in reality, the relationship may be non-linear
    double doseML = (ecAdjustment / 0.1) * factorPerLiter * waterVolumeInLiters;
    
    // Ensure we don't return negative values
    return doseML > 0 ? doseML : 0.0;
  }
  
  // General dosing amount calculation
  static double calculateDosingAmount({
    required double waterVolumeInLiters,
    required double adjustmentFactorPerLiter,
  }) {
    if (waterVolumeInLiters <= 0 || adjustmentFactorPerLiter <= 0) {
      return 0.0;
    }
    
    // Safety check for reasonable values
    if (waterVolumeInLiters > MAX_SUPPORTED_VOLUME) {
      return 0.0;
    }
    
    // Calculate dosing amount based on water volume and factor
    return adjustmentFactorPerLiter * waterVolumeInLiters;
  }
} 