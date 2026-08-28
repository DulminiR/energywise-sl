import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/household_appliance.dart';
import '../routes/app_routes.dart';
import '../services/energy_calculation_engine.dart';
import '../services/tariff_engine.dart';
import '../services/appliance_service.dart';
import '../widgets/reusable_components.dart';

/// What-If Sandbox screen with proper data persistence.
class WhatIfSandboxScreen extends StatefulWidget {
  const WhatIfSandboxScreen({Key? key}) : super(key: key);

  @override
  State<WhatIfSandboxScreen> createState() => _WhatIfSandboxScreenState();
}

class _WhatIfSandboxScreenState extends State<WhatIfSandboxScreen> {
  final EnergyCalculationEngine _energyEngine = EnergyCalculationEngine();
  final TariffEngine _tariffEngine = TariffEngine();
  final ApplianceService _applianceService = ApplianceService();

  double _currentBill = 0;
  double _currentKwh = 0;

  // What-If state (starts as copy of current)
  late List<HouseholdAppliance> _whatIfAppliances;
  double _whatIfBill = 0;
  double _whatIfKwh = 0;
  bool _isLoading = true;

  // Track which appliances are pinned for quick adjustment
  late Set<String> _pinnedAppliances;
  late Map<String, double> _applianceKwhMap;

  @override
  void initState() {
    super.initState();
    _initializeWhatIf();
  }

  /// Initialize what-if with ACTUAL current data from AppState
  Future<void> _initializeWhatIf() async {
    try {
      await _tariffEngine.loadTariffConfig();

      final appState = context.read<AppState>();

      // Load CURRENT values (from Appliance Tuning screen)
      _currentBill = appState.estimatedBillLkr ?? 0;
      _currentKwh = appState.totalMonthlyKwh ?? 0;

      print('DEBUG: Current kWh = $_currentKwh, Bill = $_currentBill');

      // Create COPY of current appliances for what-if modification
      _whatIfAppliances = appState.householdAppliances
          .map(
            (ha) => HouseholdAppliance(
              applianceId: ha.applianceId,
              name: ha.name,
              ageSelection: ha.ageSelection,
              quantity: ha.quantity,
              isEnabled: ha.isEnabled,
              dailyHours: ha.dailyHours,
              weeklyHours: ha.weeklyHours,
              weeklyCycles: ha.weeklyCycles,
            ),
          )
          .toList();

      print(
        'DEBUG: Loaded ${_whatIfAppliances.length} appliances from AppState',
      );

      // Calculate kWh for each appliance
      final appliances = await _applianceService.loadAppliances();
      final catalogMap = {for (var a in appliances) a.id: a};

      _applianceKwhMap = {};
      for (final ha in _whatIfAppliances) {
        if (!ha.isEnabled) continue;
        final appliance = catalogMap[ha.applianceId];
        if (appliance == null) continue;

        final kwh = _calculateApplianceKwh(appliance, ha);
        _applianceKwhMap[ha.applianceId] = kwh;
      }

      // Pin top 5 appliances by kWh
      final sortedByKwh = _applianceKwhMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _pinnedAppliances = sortedByKwh.take(5).map((e) => e.key).toSet();

      // Initial what-if calculation
      await _recalculateWhatIf();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing What-If: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Recalculate what-if bill based on current adjustments
  Future<void> _recalculateWhatIf() async {
    try {
      final appliances = await _applianceService.loadAppliances();
      final catalogMap = {for (var a in appliances) a.id: a};

      final whatIfKwh = _energyEngine.calculateTotalMonthlyKwh(
        _whatIfAppliances,
        catalogMap,
      );

      final tariffResult = await _tariffEngine.calculateBill(whatIfKwh);

      setState(() {
        _whatIfKwh = whatIfKwh;
        _whatIfBill = tariffResult.totalBill;
      });

      print('DEBUG: What-If kWh = $whatIfKwh, Bill = $_whatIfBill');
    } catch (e) {
      print('Error recalculating: $e');
    }
  }

  /// Update an appliance in what-if
  void _updateWhatIfAppliance(int index, HouseholdAppliance updated) {
    setState(() {
      _whatIfAppliances[index] = updated;
    });
    _recalculateWhatIf();
  }

  /// Update quantity of pinned appliance
  void _updateQuantity(String applianceId, double newQuantity) {
    final index = _whatIfAppliances.indexWhere(
      (a) => a.applianceId == applianceId,
    );
    if (index >= 0) {
      _updateWhatIfAppliance(
        index,
        _whatIfAppliances[index].copyWith(quantity: newQuantity),
      );
    }
  }

  /// Toggle pinning an appliance
  void _togglePinnedAppliance(String applianceId) {
    setState(() {
      if (_pinnedAppliances.contains(applianceId)) {
        _pinnedAppliances.remove(applianceId);
      } else {
        _pinnedAppliances.add(applianceId);
      }
    });
  }

  /// Reset to original values
  void _resetToActual() {
    final appState = context.read<AppState>();
    _whatIfAppliances = appState.householdAppliances
        .map(
          (ha) => HouseholdAppliance(
            applianceId: ha.applianceId,
            name: ha.name,
            ageSelection: ha.ageSelection,
            quantity: ha.quantity,
            isEnabled: ha.isEnabled,
            dailyHours: ha.dailyHours,
            weeklyHours: ha.weeklyHours,
            weeklyCycles: ha.weeklyCycles,
          ),
        )
        .toList();
    _recalculateWhatIf();
  }

  /// Apply changes and go to AI Advisor
  void _applyChanges() {
    context.read<AppState>().setHouseholdAppliances(_whatIfAppliances);
    Navigator.pushNamed(context, AppRoutes.aiAdvisor);
  }

  /// Calculate kWh for appliance
  double _calculateApplianceKwh(dynamic appliance, HouseholdAppliance ha) {
    final wattage = appliance.defaultWattage;
    final dutyCycle = appliance.defaultDutyCycle;
    final quantity = ha.quantity;
    final ageMultiplier = appliance.ageMultipliers[ha.ageSelection] ?? 1.0;

    double monthlyKwh = 0.0;

    switch (appliance.inputType) {
      case 'always_on':
        monthlyKwh =
            (wattage * 24 * 30 * dutyCycle * quantity * ageMultiplier) / 1000;
        break;
      case 'daily_hours':
        final hours = ha.dailyHours ?? appliance.defaultDailyHours ?? 0;
        monthlyKwh =
            (wattage * hours * 30 * dutyCycle * quantity * ageMultiplier) /
            1000;
        break;
      case 'weekly_hours':
        final hours = ha.weeklyHours ?? appliance.defaultWeeklyHours ?? 0;
        const weeksPerMonth = 52 / 12;
        monthlyKwh =
            (wattage *
                hours *
                weeksPerMonth *
                dutyCycle *
                quantity *
                ageMultiplier) /
            1000;
        break;
      case 'weekly_cycles':
        final cycles = ha.weeklyCycles ?? appliance.defaultWeeklyCycles ?? 0;
        final hoursPerCycle = appliance.avgHoursPerCycle ?? 1.0;
        const weeksPerMonth = 52 / 12;
        monthlyKwh =
            (wattage *
                cycles *
                hoursPerCycle *
                weeksPerMonth *
                quantity *
                ageMultiplier) /
            1000;
        break;
    }

    return monthlyKwh;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: CustomAppBar(title: 'What-If Sandbox', showBackButton: false),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F54)),
          ),
        ),
      );
    }

    final savings = _currentBill - _whatIfBill;
    final savingsPercent = _currentBill > 0
        ? (savings / _currentBill) * 100
        : 0;

    // Get pinned appliances
    final pinnedAppliances = _whatIfAppliances
        .where(
          (ha) => ha.isEnabled && _pinnedAppliances.contains(ha.applianceId),
        )
        .toList();
    pinnedAppliances.sort(
      (a, b) => ((_applianceKwhMap[b.applianceId] ?? 0)).compareTo(
        (_applianceKwhMap[a.applianceId] ?? 0),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'What-If Sandbox',
        showBackButton: false,
        actionWidget: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF005F54)),
            onPressed: _resetToActual,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Savings Hero
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF005F54), Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF005F54).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Potential Savings',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LKR ${savings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${savingsPercent.toStringAsFixed(1)}% savings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Before',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LKR ${_currentBill.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'After',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'LKR ${_whatIfBill.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Top Cost Contributors
              const Text(
                'Top Cost Contributors',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF999999),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ...pinnedAppliances.asMap().entries.map((entry) {
                return _buildAdjustableCard(entry.key, entry.value);
              }).toList(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              label: 'Apply & Get AI Advice',
              onPressed: _applyChanges,
            ),
          ),
          BottomNav(
            currentRoute: AppRoutes.whatIfSandbox,
            onNavigate: (route) {
              Navigator.pushNamed(context, route);
            },
          ),
        ],
      ),
    );
  }

  /// Build adjustable card with quantity and usage controls
  Widget _buildAdjustableCard(int index, HouseholdAppliance ha) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ha.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'kWh: ${(_applianceKwhMap[ha.applianceId] ?? 0).toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _togglePinnedAppliance(ha.applianceId),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF005F54),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // QUANTITY CONTROLS - VISIBLE AND COMPACT
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: ha.quantity > 1
                            ? () => _updateQuantity(
                                ha.applianceId,
                                ha.quantity - 1,
                              )
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ha.quantity > 1
                                ? Colors.white
                                : Colors.grey[100],
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${ha.quantity.toInt()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: ha.quantity < 10
                            ? () => _updateQuantity(
                                ha.applianceId,
                                ha.quantity + 1,
                              )
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ha.quantity < 10
                                ? Colors.white
                                : Colors.grey[100],
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: const Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Usage slider
            _buildUsageSlider(index, ha),
          ],
        ),
      ),
    );
  }

  /// Build usage slider
  Widget _buildUsageSlider(int index, HouseholdAppliance ha) {
    if (ha.dailyHours != null) {
      return LabeledSlider(
        label: 'Daily use',
        value: ha.dailyHours ?? 0,
        min: 0,
        max: 24,
        suffix: 'hours',
        onChanged: (value) {
          _updateWhatIfAppliance(index, ha.copyWith(dailyHours: value));
        },
      );
    } else if (ha.weeklyHours != null) {
      return LabeledSlider(
        label: 'Weekly use',
        value: ha.weeklyHours ?? 0,
        min: 0,
        max: 48,
        suffix: 'hours',
        onChanged: (value) {
          _updateWhatIfAppliance(index, ha.copyWith(weeklyHours: value));
        },
      );
    } else if (ha.weeklyCycles != null) {
      return LabeledSlider(
        label: 'Weekly cycles',
        value: ha.weeklyCycles ?? 0,
        min: 0,
        max: 20,
        suffix: 'cycles',
        onChanged: (value) {
          _updateWhatIfAppliance(index, ha.copyWith(weeklyCycles: value));
        },
      );
    }
    return Text(
      'Always on',
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

extension HouseholdApplianceCopyWhat on HouseholdAppliance {
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
