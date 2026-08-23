import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appliance.dart';
import '../models/household_appliance.dart';
import '../models/app_state.dart';
import '../routes/app_routes.dart';
import '../services/appliance_service.dart';
import '../services/archetype_preset_service.dart';
import '../services/energy_calculation_engine.dart';
import '../services/tariff_engine.dart';
import '../widgets/reusable_components.dart';

/// Appliance tuning screen with archetype-based presets.
class ApplianceTuningScreen extends StatefulWidget {
  const ApplianceTuningScreen({Key? key}) : super(key: key);

  @override
  State<ApplianceTuningScreen> createState() => _ApplianceTuningScreenState();
}

class _ApplianceTuningScreenState extends State<ApplianceTuningScreen> {
  final ApplianceService _applianceService = ApplianceService();
  final ArchetypePresetService _presetService = ArchetypePresetService();
  final EnergyCalculationEngine _energyEngine = EnergyCalculationEngine();
  final TariffEngine _tariffEngine = TariffEngine();

  late List<HouseholdAppliance> _householdAppliances;
  List<HouseholdAppliance> _customAppliances = [];
  Map<String, Appliance> _catalogMap = {};
  List<Appliance> _allCatalogAppliances = [];
  bool _isLoading = true;

  // For custom appliance form
  TextEditingController _customNameController = TextEditingController();
  TextEditingController _customWattageController = TextEditingController();
  double _customDailyHours = 4;

  @override
  void initState() {
    super.initState();
    _loadAppliances();
  }

  /// Load appliances and initialize presets based on archetype
  Future<void> _loadAppliances() async {
    try {
      final appState = context.read<AppState>();
      final archetype = appState.selectedArchetype ?? 'standard_house';

      // Load catalog
      final allAppliances = await _applianceService.loadAppliances();
      _allCatalogAppliances = allAppliances;
      _catalogMap = {for (var a in allAppliances) a.id: a};

      // Get preset appliances for this archetype
      _householdAppliances = _presetService.getPresetAppliances(archetype);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get unused appliances from catalog
  List<Appliance> _getUnusedAppliances() {
    final usedIds = <String>{
      ..._householdAppliances.map((a) => a.applianceId),
      ..._customAppliances.map((a) => a.applianceId),
    };

    return _allCatalogAppliances.where((a) => !usedIds.contains(a.id)).toList();
  }

  /// Add appliance from catalog
  void _addAppliance(Appliance appliance) {
    setState(() {
      _householdAppliances.add(
        HouseholdAppliance(
          applianceId: appliance.id,
          name: appliance.name,
          ageSelection: 'standard',
          quantity: 1,
          isEnabled: true,
          dailyHours: appliance.defaultDailyHours,
          weeklyHours: appliance.defaultWeeklyHours,
          weeklyCycles: appliance.defaultWeeklyCycles,
        ),
      );
    });
  }

  /// Remove appliance
  void _removeAppliance(int index) {
    setState(() {
      _householdAppliances.removeAt(index);
    });
  }

  /// Remove custom appliance
  void _removeCustomAppliance(int index) {
    setState(() {
      _customAppliances.removeAt(index);
    });
  }

  /// Update appliance
  void _updateAppliance(int index, HouseholdAppliance updated) {
    setState(() {
      _householdAppliances[index] = updated;
    });
  }

  /// Update custom appliance
  void _updateCustomAppliance(int index, HouseholdAppliance updated) {
    setState(() {
      _customAppliances[index] = updated;
    });
  }

  /// Add custom appliance
  void _addCustomAppliance() {
    final name = _customNameController.text.trim();
    final wattage = double.tryParse(_customWattageController.text) ?? 100;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter appliance name')),
      );
      return;
    }

    setState(() {
      _customAppliances.add(
        HouseholdAppliance(
          applianceId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          ageSelection: 'standard',
          quantity: 1,
          isEnabled: true,
          dailyHours: _customDailyHours,
        ),
      );
    });

    _customNameController.clear();
    _customWattageController.clear();
    _customDailyHours = 4;

    Navigator.pop(context);
  }

  /// Proceed to next screen
  Future<void> _proceedToNextScreen() async {
    final allAppliances = [..._householdAppliances, ..._customAppliances];
    context.read<AppState>().setHouseholdAppliances(allAppliances);
    Navigator.pushNamed(context, AppRoutes.billCalibration);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: CustomAppBar(
          title: 'Step 2 of 6',
          showBackButton: true,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F54)),
          ),
        ),
      );
    }

    final unusedAppliances = _getUnusedAppliances();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Step 2 of 6',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us how you use your appliances',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ve preset common appliances for your home. Adjust usage, add more, or customize as needed.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // YOUR APPLIANCES
              const Text(
                'YOUR APPLIANCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF999999),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ..._householdAppliances.asMap().entries.map((entry) {
                return _buildApplianceCard(entry.key, entry.value);
              }).toList(),

              // CUSTOM APPLIANCES
              if (_customAppliances.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'CUSTOM APPLIANCES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF999999),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ..._customAppliances.asMap().entries.map((entry) {
                  return _buildCustomApplianceCard(entry.key, entry.value);
                }).toList(),
              ],

              // ADD MORE FROM CATALOG
              if (unusedAppliances.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ADD MORE FROM CATALOG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF999999),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${unusedAppliances.length} available',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...unusedAppliances.map((appliance) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _addAppliance(appliance),
                      child: CustomCard(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: const Color(0xFFF8F9FA),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                appliance.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF212121),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF005F54),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFF005F54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],

              const SizedBox(height: 24),

              // ADD CUSTOM BUTTON
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: '+ Add Custom Appliance',
                  onPressed: _showCustomApplianceDialog,
                ),
              ),

              const SizedBox(height: 24),

              // Info
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These are realistic defaults for your home type. Adjust quantities, usage, or add appliances based on your actual situation.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: PrimaryButton(
          label: 'See My Energy',
          onPressed: _proceedToNextScreen,
        ),
      ),
    );
  }

  /// Build appliance card with sliders and controls
  Widget _buildApplianceCard(int index, HouseholdAppliance ha) {
    final appliance = _catalogMap[ha.applianceId];
    if (appliance == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with remove button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ha.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeAppliance(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quantity controls (COMPACT)
            Row(
              children: [
                const Text(
                  'Qty:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: ha.quantity > 1
                      ? () => _updateAppliance(
                          index,
                          ha.copyWith(quantity: ha.quantity - 1),
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: const Icon(Icons.remove, size: 12),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 25,
                  child: Text(
                    '${ha.quantity.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: ha.quantity < 5
                      ? () => _updateAppliance(
                          index,
                          ha.copyWith(quantity: ha.quantity + 1),
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: const Icon(Icons.add, size: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Usage slider
            _buildUsageSlider(index, ha, appliance),

            // Age toggle if needed
            if (appliance.requiresAgeToggle) ...[
              const SizedBox(height: 12),
              AgeToggleButtons(
                selected: ha.ageSelection,
                onSelected: (age) {
                  _updateAppliance(index, ha.copyWith(ageSelection: age));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build custom appliance card
  Widget _buildCustomApplianceCard(int index, HouseholdAppliance ha) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(12),
        backgroundColor: const Color(0xFFFFF8F0),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ha.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeCustomAppliance(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Qty:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: ha.quantity > 1
                      ? () => _updateCustomAppliance(
                          index,
                          ha.copyWith(quantity: ha.quantity - 1),
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: const Icon(Icons.remove, size: 12),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 25,
                  child: Text(
                    '${ha.quantity.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: ha.quantity < 5
                      ? () => _updateCustomAppliance(
                          index,
                          ha.copyWith(quantity: ha.quantity + 1),
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: const Icon(Icons.add, size: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build usage slider based on input type
  Widget _buildUsageSlider(
    int index,
    HouseholdAppliance ha,
    Appliance appliance,
  ) {
    switch (appliance.inputType) {
      case 'always_on':
        return Text(
          'Always on (24 hrs)',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        );

      case 'daily_hours':
        return LabeledSlider(
          label: 'Daily use',
          value: ha.dailyHours ?? appliance.defaultDailyHours ?? 0,
          min: 0,
          max: 24,
          suffix: 'hrs',
          onChanged: (value) {
            _updateAppliance(index, ha.copyWith(dailyHours: value));
          },
        );

      case 'weekly_hours':
        return LabeledSlider(
          label: 'Weekly use',
          value: ha.weeklyHours ?? appliance.defaultWeeklyHours ?? 0,
          min: 0,
          max: 48,
          suffix: 'hrs',
          onChanged: (value) {
            _updateAppliance(index, ha.copyWith(weeklyHours: value));
          },
        );

      case 'weekly_cycles':
        return LabeledSlider(
          label: 'Weekly cycles',
          value: ha.weeklyCycles ?? appliance.defaultWeeklyCycles ?? 0,
          min: 0,
          max: 20,
          suffix: 'cycles',
          onChanged: (value) {
            _updateAppliance(index, ha.copyWith(weeklyCycles: value));
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Show custom appliance dialog
  void _showCustomApplianceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Appliance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customNameController,
                  decoration: InputDecoration(
                    labelText: 'Appliance Name',
                    hintText: 'e.g., Water Pump, Solar Panel',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customWattageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Wattage (W)',
                    hintText: 'e.g., 500, 1000, 1500',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Hours: ${_customDailyHours.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: _customDailyHours,
                      min: 0,
                      max: 24,
                      divisions: 24,
                      onChanged: (value) {
                        setState(() {
                          _customDailyHours = value;
                        });
                      },
                      activeColor: const Color(0xFF005F54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005F54),
              ),
              onPressed: _addCustomAppliance,
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _customWattageController.dispose();
    super.dispose();
  }
}

extension HouseholdApplianceCopy on HouseholdAppliance {
  HouseholdAppliance copyWith({
    String? ageSelection,
    double? quantity,
    bool? isEnabled,
    double? dailyHours,
    double? weeklyHours,
    double? weeklyCycles,
  }) {
    return HouseholdAppliance(
      applianceId: applianceId,
      name: name,
      ageSelection: ageSelection ?? this.ageSelection,
      quantity: quantity ?? this.quantity,
      isEnabled: isEnabled ?? this.isEnabled,
      dailyHours: dailyHours ?? this.dailyHours,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      weeklyCycles: weeklyCycles ?? this.weeklyCycles,
    );
  }
}
