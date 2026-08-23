/// Represents a catalog-level appliance definition.
/// This is read-only and loaded from appliances.json.
class Appliance {
  final String id;
  final String name;
  final String physicsLoad; // 'constant', 'thermostatic', 'event'
  final String
  inputType; // 'always_on', 'daily_hours', 'weekly_hours', 'weekly_cycles'
  final List<String> allowedInputTypes;
  final double defaultWattage;
  final double defaultDutyCycle;
  final double? defaultDailyHours;
  final double? defaultWeeklyHours;
  final double? defaultWeeklyCycles;
  final double? avgHoursPerCycle;
  final bool requiresAgeToggle;
  final Map<String, double>
  ageMultipliers; // e.g., {"old": 1.35, "standard": 1.00, "inverter": 0.65}
  final String catalogGroup;

  Appliance({
    required this.id,
    required this.name,
    required this.physicsLoad,
    required this.inputType,
    required this.allowedInputTypes,
    required this.defaultWattage,
    required this.defaultDutyCycle,
    this.defaultDailyHours,
    this.defaultWeeklyHours,
    this.defaultWeeklyCycles,
    this.avgHoursPerCycle,
    required this.requiresAgeToggle,
    required this.ageMultipliers,
    required this.catalogGroup,
  });

  /// Factory constructor to create an Appliance from JSON.
  /// This is used when loading appliances.json.
  factory Appliance.fromJson(Map<String, dynamic> json) {
    return Appliance(
      id: json['id'] as String,
      name: json['name'] as String,
      physicsLoad: json['physics_load'] as String,
      inputType: json['input_type'] as String,
      allowedInputTypes: List<String>.from(
        json['allowed_input_types'] as List? ?? [],
      ),
      defaultWattage: ((json['default_wattage'] ?? 0) as num).toDouble(),
      defaultDutyCycle: ((json['default_duty_cycle'] ?? 0) as num).toDouble(),
      defaultDailyHours: json['default_daily_hours'] != null
          ? (json['default_daily_hours'] as num).toDouble()
          : null,
      defaultWeeklyHours: json['default_weekly_hours'] != null
          ? (json['default_weekly_hours'] as num).toDouble()
          : null,
      defaultWeeklyCycles: json['default_weekly_cycles'] != null
          ? (json['default_weekly_cycles'] as num).toDouble()
          : null,
      avgHoursPerCycle: json['avg_hours_per_cycle'] != null
          ? (json['avg_hours_per_cycle'] as num).toDouble()
          : null,
      requiresAgeToggle: json['requires_age_toggle'] as bool? ?? false,
      ageMultipliers: Map<String, double>.from(
        ((json['age_multipliers'] ?? {}) as Map).cast<String, num>().map(
          (k, v) => MapEntry(k, (v ?? 0).toDouble()),
        ),
      ),
      catalogGroup: json['catalog_group'] as String? ?? 'Other',
    );
  }

  /// Convert this Appliance back to JSON (for debugging/testing).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'physics_load': physicsLoad,
      'input_type': inputType,
      'allowed_input_types': allowedInputTypes,
      'default_wattage': defaultWattage,
      'default_duty_cycle': defaultDutyCycle,
      'default_daily_hours': defaultDailyHours,
      'default_weekly_hours': defaultWeeklyHours,
      'default_weekly_cycles': defaultWeeklyCycles,
      'avg_hours_per_cycle': avgHoursPerCycle,
      'requires_age_toggle': requiresAgeToggle,
      'age_multipliers': ageMultipliers,
      'catalog_group': catalogGroup,
    };
  }

  @override
  String toString() =>
      'Appliance(id: $id, name: $name, wattage: $defaultWattage)';
}
