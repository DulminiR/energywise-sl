import '../models/household_appliance.dart';

/// Archetype presets based on real Sri Lankan consumption data.
/// Studio: 75 kWh/month (1-2 people)
/// Standard: 130 kWh/month (3-4 people)
/// Large: 220 kWh/month (5-6 people)
class ArchetypePresetService {
  List<HouseholdAppliance> getPresetAppliances(String archetype) {
    switch (archetype) {
      case 'studio':
        return _getStudioPresets();
      case 'standard_house':
        return _getStandardPresets();
      case 'large_house':
        return _getLargePresets();
      default:
        return _getStandardPresets();
    }
  }

  /// Studio Apartment (1-2 people, ~75 kWh/month)
  List<HouseholdAppliance> _getStudioPresets() {
    return [
      HouseholdAppliance(
        applianceId: 'refrigerator',
        name: 'Refrigerator (Double Door / Single)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
      ),
      HouseholdAppliance(
        applianceId: 'led_bulb',
        name: 'LED Light Bulb (9W)',
        ageSelection: 'standard',
        quantity: 2,
        isEnabled: true,
        dailyHours: 5,
      ),
      HouseholdAppliance(
        applianceId: 'ceiling_fan',
        name: 'Ceiling Fan',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 6,
      ),
      HouseholdAppliance(
        applianceId: 'led_tv',
        name: 'Television (42-inch LED)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 4,
      ),
      HouseholdAppliance(
        applianceId: 'wifi_router',
        name: 'Wi-Fi Router',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
      ),
      HouseholdAppliance(
        applianceId: 'device_chargers',
        name: 'Phone / Laptop Chargers (Bundle)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 2,
      ),
      HouseholdAppliance(
        applianceId: 'electric_kettle',
        name: 'Electric Kettle / Jug',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 7,
      ),
      HouseholdAppliance(
        applianceId: 'microwave_oven',
        name: 'Microwave Oven',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 3,
      ),
    ];
  }

  /// Standard House (3-4 people, ~130 kWh/month)
  List<HouseholdAppliance> _getStandardPresets() {
    return [
      HouseholdAppliance(
        applianceId: 'refrigerator',
        name: 'Refrigerator (Double Door / Single)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
      ),
      HouseholdAppliance(
        applianceId: 'led_bulb',
        name: 'LED Light Bulb (9W)',
        ageSelection: 'standard',
        quantity: 4,
        isEnabled: true,
        dailyHours: 5,
      ),
      HouseholdAppliance(
        applianceId: 'ceiling_fan',
        name: 'Ceiling Fan',
        ageSelection: 'standard',
        quantity: 2,
        isEnabled: true,
        dailyHours: 7,
      ),
      HouseholdAppliance(
        applianceId: 'air_conditioner_12k',
        name: 'Air Conditioner (12,000 BTU)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 4,
      ),
      HouseholdAppliance(
        applianceId: 'led_tv',
        name: 'Television (42-inch LED)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 5,
      ),
      HouseholdAppliance(
        applianceId: 'wifi_router',
        name: 'Wi-Fi Router',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
      ),
      HouseholdAppliance(
        applianceId: 'device_chargers',
        name: 'Phone / Laptop Chargers (Bundle)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 3,
      ),
      HouseholdAppliance(
        applianceId: 'washing_machine',
        name: 'Washing Machine',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 3,
      ),
      HouseholdAppliance(
        applianceId: 'hot_water_shower',
        name: 'Hot Water Shower Heater',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 10,
      ),
      HouseholdAppliance(
        applianceId: 'microwave_oven',
        name: 'Microwave Oven',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 5,
      ),
      HouseholdAppliance(
        applianceId: 'electric_kettle',
        name: 'Electric Kettle / Jug',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 10,
      ),
    ];
  }

  /// Large House (5-6 people, ~220 kWh/month)
  List<HouseholdAppliance> _getLargePresets() {
    return [
      HouseholdAppliance(
        applianceId: 'refrigerator',
        name: 'Refrigerator (Double Door / Single)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
      ),
      HouseholdAppliance(
        applianceId: 'led_bulb',
        name: 'LED Light Bulb (9W)',
        ageSelection: 'standard',
        quantity: 6,
        isEnabled: true,
        dailyHours: 6,
      ),
      HouseholdAppliance(
        applianceId: 'ceiling_fan',
        name: 'Ceiling Fan',
        ageSelection: 'standard',
        quantity: 3,
        isEnabled: true,
        dailyHours: 8,
      ),
      HouseholdAppliance(
        applianceId: 'air_conditioner_12k',
        name: 'Air Conditioner (12,000 BTU)',
        ageSelection: 'standard',
        quantity: 2,
        isEnabled: true,
        dailyHours: 6,
      ),
      HouseholdAppliance(
        applianceId: 'led_tv',
        name: 'Television (42-inch LED)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 5,
      ),
      HouseholdAppliance(
        applianceId: 'wifi_router',
        name: 'Wi-Fi Router',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
      ),
      HouseholdAppliance(
        applianceId: 'device_chargers',
        name: 'Phone / Laptop Chargers (Bundle)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 4,
      ),
      HouseholdAppliance(
        applianceId: 'washing_machine',
        name: 'Washing Machine',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 5,
      ),
      HouseholdAppliance(
        applianceId: 'hot_water_shower',
        name: 'Hot Water Shower Heater',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 14,
      ),
      HouseholdAppliance(
        applianceId: 'microwave_oven',
        name: 'Microwave Oven',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 7,
      ),
      HouseholdAppliance(
        applianceId: 'electric_kettle',
        name: 'Electric Kettle / Jug',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 14,
      ),
      HouseholdAppliance(
        applianceId: 'induction_cooker',
        name: 'Electric / Induction Cooker',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        dailyHours: 1,
      ),
      HouseholdAppliance(
        applianceId: 'water_pump',
        name: 'Water Pump (1.0 HP)',
        ageSelection: 'standard',
        quantity: 1,
        isEnabled: true,
        weeklyCycles: 5,
      ),
    ];
  }
}
