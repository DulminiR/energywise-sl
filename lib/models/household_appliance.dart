/// Represents a user-specific instance of an appliance in their household.
/// This is mutable and can be customized by the user.
class HouseholdAppliance {
  final String applianceId; // Reference to catalog appliance ID
  final String name; // Display name (from catalog)
  String
  ageSelection; // 'new', 'standard', 'old', 'inverter' (affects efficiency)
  double quantity; // How many of this appliance (e.g., 2 ceiling fans)
  bool isEnabled; // Is this appliance part of the calculation?

  /// Usage values — exactly one will be used based on input_type
  double? dailyHours; // For 'daily_hours' input type
  double? weeklyHours; // For 'weekly_hours' input type
  double? weeklyCycles; // For 'weekly_cycles' input type

  HouseholdAppliance({
    required this.applianceId,
    required this.name,
    this.ageSelection = 'standard',
    this.quantity = 1,
    this.isEnabled = true,
    this.dailyHours,
    this.weeklyHours,
    this.weeklyCycles,
  });

  /// Factory constructor to create from JSON (for saving/loading user data).
  factory HouseholdAppliance.fromJson(Map<String, dynamic> json) {
    return HouseholdAppliance(
      applianceId: json['appliance_id'] as String,
      name: json['name'] as String,
      ageSelection: json['age_selection'] as String? ?? 'standard',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      isEnabled: json['is_enabled'] as bool? ?? true,
      dailyHours: json['daily_hours'] != null
          ? (json['daily_hours'] as num).toDouble()
          : null,
      weeklyHours: json['weekly_hours'] != null
          ? (json['weekly_hours'] as num).toDouble()
          : null,
      weeklyCycles: json['weekly_cycles'] != null
          ? (json['weekly_cycles'] as num).toDouble()
          : null,
    );
  }

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'appliance_id': applianceId,
      'name': name,
      'age_selection': ageSelection,
      'quantity': quantity,
      'is_enabled': isEnabled,
      'daily_hours': dailyHours,
      'weekly_hours': weeklyHours,
      'weekly_cycles': weeklyCycles,
    };
  }

  @override
  String toString() =>
      'HouseholdAppliance(id: $applianceId, name: $name, qty: $quantity, age: $ageSelection)';
}
