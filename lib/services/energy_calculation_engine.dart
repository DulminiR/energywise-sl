import '../models/appliance.dart';
import '../models/household_appliance.dart';

/// Calculates total monthly kWh from household appliances.
/// Pure deterministic service—no UI dependency.
class EnergyCalculationEngine {
  /// Main calculation method.
  /// Takes a list of household appliances and returns total monthly kWh.
  double calculateTotalMonthlyKwh(
    List<HouseholdAppliance> householdAppliances,
    Map<String, Appliance> catalogMap,
  ) {
    double totalKwh = 0.0;

    for (final ha in householdAppliances) {
      // Skip disabled appliances
      if (!ha.isEnabled) continue;

      // Look up the catalog appliance
      final catalogAppliance = catalogMap[ha.applianceId];
      if (catalogAppliance == null) {
        throw Exception('Appliance not found in catalog: ${ha.applianceId}');
      }

      // Calculate kWh for this appliance
      final kwhForThisAppliance = _calculateApplianceKwh(ha, catalogAppliance);
      totalKwh += kwhForThisAppliance;
    }

    return totalKwh;
  }

  /// Calculate kWh for a single appliance.
  /// Handles different input types and applies multipliers.
  double _calculateApplianceKwh(
    HouseholdAppliance householdAppliance,
    Appliance catalogAppliance,
  ) {
    final wattage = catalogAppliance.defaultWattage;
    final dutyCycle = catalogAppliance.defaultDutyCycle;
    final quantity = householdAppliance.quantity;

    // Get the age multiplier
    final ageMultiplier =
        catalogAppliance.ageMultipliers[householdAppliance.ageSelection] ?? 1.0;

    double monthlyKwh = 0.0;

    // Route based on input type
    switch (catalogAppliance.inputType) {
      case 'always_on':
        monthlyKwh = _calculateAlwaysOn(
          wattage,
          dutyCycle,
          quantity,
          ageMultiplier,
        );
        break;

      case 'daily_hours':
        final hours =
            householdAppliance.dailyHours ??
            catalogAppliance.defaultDailyHours ??
            0;
        monthlyKwh = _calculateDailyHours(
          wattage,
          hours,
          dutyCycle,
          quantity,
          ageMultiplier,
        );
        break;

      case 'weekly_hours':
        final hours =
            householdAppliance.weeklyHours ??
            catalogAppliance.defaultWeeklyHours ??
            0;
        monthlyKwh = _calculateWeeklyHours(
          wattage,
          hours,
          dutyCycle,
          quantity,
          ageMultiplier,
        );
        break;

      case 'weekly_cycles':
        final cycles =
            householdAppliance.weeklyCycles ??
            catalogAppliance.defaultWeeklyCycles ??
            0;
        final hoursPerCycle = catalogAppliance.avgHoursPerCycle ?? 1.0;
        monthlyKwh = _calculateWeeklyCycles(
          wattage,
          cycles,
          hoursPerCycle,
          quantity,
          ageMultiplier,
        );
        break;

      default:
        throw Exception('Unknown input type: ${catalogAppliance.inputType}');
    }

    return monthlyKwh;
  }

  /// Formula: wattage × 24 × 30 × duty_cycle × age_multiplier ÷ 1000
  /// Example: Refrigerator always on
  double _calculateAlwaysOn(
    double wattage,
    double dutyCycle,
    double quantity,
    double ageMultiplier,
  ) {
    return (wattage * 24 * 30 * dutyCycle * quantity * ageMultiplier) / 1000;
  }

  /// Formula: wattage × daily_hours × 30 × duty_cycle × age_multiplier ÷ 1000
  /// Example: Fan used 8 hours per day
  double _calculateDailyHours(
    double wattage,
    double dailyHours,
    double dutyCycle,
    double quantity,
    double ageMultiplier,
  ) {
    return (wattage * dailyHours * 30 * dutyCycle * quantity * ageMultiplier) /
        1000;
  }

  /// Formula: wattage × weekly_hours × (52/12) × duty_cycle × age_multiplier ÷ 1000
  /// Example: AC used 5 hours per week
  /// (52/12) converts weeks to months on average
  double _calculateWeeklyHours(
    double wattage,
    double weeklyHours,
    double dutyCycle,
    double quantity,
    double ageMultiplier,
  ) {
    const weeksPerMonth = 52 / 12;
    return (wattage *
            weeklyHours *
            weeksPerMonth *
            dutyCycle *
            quantity *
            ageMultiplier) /
        1000;
  }

  /// Formula: wattage × hours_per_cycle × cycles_per_week × (52/12) × age_multiplier ÷ 1000
  /// Example: Washing machine 3 cycles/week, 1 hour each
  /// Note: Event appliances typically don't use duty_cycle (duty_cycle = 1.0)
  double _calculateWeeklyCycles(
    double wattage,
    double weeklyCycles,
    double hoursPerCycle,
    double quantity,
    double ageMultiplier,
  ) {
    const weeksPerMonth = 52 / 12;
    return (wattage *
            weeklyCycles *
            hoursPerCycle *
            weeksPerMonth *
            quantity *
            ageMultiplier) /
        1000;
  }
}
