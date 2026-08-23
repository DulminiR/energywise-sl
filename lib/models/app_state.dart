import 'package:flutter/foundation.dart';

import 'household_appliance.dart';

/// Holds app-wide state that flows between screens.
/// Simple approach: just holds data, no fancy state management yet.
class AppState extends ChangeNotifier {
  // User's household selection
  String? selectedArchetype; // 'studio', 'standard_house', 'large_house'

  // User's appliance customizations
  List<HouseholdAppliance> householdAppliances = [];

  // Optional: user's actual bill for calibration
  double? actualMonthlyBill;

  // Current calculation results (from engines)
  double? totalMonthlyKwh;
  double? estimatedBillLkr;

  /// Set the selected household archetype
  void setArchetype(String archetype) {
    selectedArchetype = archetype;
    notifyListeners(); // Tell UI to rebuild
  }

  /// Update household appliances list
  void setHouseholdAppliances(List<HouseholdAppliance> appliances) {
    householdAppliances = appliances;
    notifyListeners();
  }

  /// Add or update a single appliance
  void updateAppliance(HouseholdAppliance appliance) {
    final index = householdAppliances.indexWhere(
      (a) => a.applianceId == appliance.applianceId,
    );
    if (index >= 0) {
      householdAppliances[index] = appliance;
    } else {
      householdAppliances.add(appliance);
    }
    notifyListeners();
  }

  /// Set the actual monthly bill (for calibration)
  void setActualBill(double amount) {
    actualMonthlyBill = amount;
    notifyListeners();
  }

  /// Set calculation results
  void setCalculationResults(double kwh, double bill) {
    totalMonthlyKwh = kwh;
    estimatedBillLkr = bill;
    notifyListeners();
  }

  /// Reset all state
  void reset() {
    selectedArchetype = null;
    householdAppliances = [];
    actualMonthlyBill = null;
    totalMonthlyKwh = null;
    estimatedBillLkr = null;
    notifyListeners();
  }

  @override
  String toString() =>
      'AppState(archetype: $selectedArchetype, appliances: ${householdAppliances.length}, bill: $estimatedBillLkr)';
}
