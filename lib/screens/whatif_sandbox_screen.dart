import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/household_appliance.dart';
import '../routes/app_routes.dart';
import '../services/energy_calculation_engine.dart';
import '../services/tariff_engine.dart';
import '../services/appliance_service.dart';
import '../widgets/reusable_components.dart';

/// What-If Sandbox screen - simplified for current model
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

  // What-If state (copy of current)
  late List<HouseholdAppliance> _whatIfAppliances;
  double _whatIfBill = 0;
  double _whatIfKwh = 0;
  bool _isLoading = true;

  // Track which appliances are pinned
  late Set<String> _pinnedAppliances;
  late Map<String, double> _applianceKwhMap;

  @override
  void initState() {
    super.initState();
    _initializeWhatIf();
  }

  Future<void> _initializeWhatIf() async {
    try {
      await _tariffEngine.loadTariffConfig();

      final appState = context.read<AppState>();

      _currentBill = appState.estimatedBillLkr ?? 0;
      _currentKwh = appState.totalMonthlyKwh ?? 0;

      print('DEBUG: Current kWh = $_currentKwh, Bill = $_currentBill');

      // Deep copy appliances
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

      // Calculate kWh map
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

      // Pin top 5 (deduplicated)
      final sortedByKwh = _applianceKwhMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _pinnedAppliances = sortedByKwh.take(5).map((e) => e.key).toSet();

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

  void _updateWhatIfAppliance(int index, HouseholdAppliance updated) {
    setState(() {
      _whatIfAppliances[index] = updated;
    });
    _recalculateWhatIf();
  }

  void _updateUsage(
    int index,
    HouseholdAppliance ha,
    double newValue,
    String type,
  ) {
    final updated = HouseholdAppliance(
      applianceId: ha.applianceId,
      name: ha.name,
      ageSelection: ha.ageSelection,
      quantity: ha.quantity,
      isEnabled: ha.isEnabled,
      dailyHours: type == 'daily' ? newValue : ha.dailyHours,
      weeklyHours: type == 'weekly' ? newValue : ha.weeklyHours,
      weeklyCycles: type == 'cycles' ? newValue : ha.weeklyCycles,
    );
    _updateWhatIfAppliance(index, updated);
  }

  void _updateQuantity(int index, HouseholdAppliance ha, double newQty) {
    final updated = HouseholdAppliance(
      applianceId: ha.applianceId,
      name: ha.name,
      ageSelection: ha.ageSelection,
      quantity: newQty,
      isEnabled: ha.isEnabled,
      dailyHours: ha.dailyHours,
      weeklyHours: ha.weeklyHours,
      weeklyCycles: ha.weeklyCycles,
    );
    _updateWhatIfAppliance(index, updated);
  }

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

  void _applyChanges() {
    context.read<AppState>().setHouseholdAppliances(_whatIfAppliances);
    Navigator.pushNamed(context, AppRoutes.aiAdvisor);
  }

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

    // Get pinned appliances (no duplicates)
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
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: _resetToActual,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF005F54),
                size: 20,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Fixed Savings Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF005F54), Color(0xFF004D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005F54).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Potential Savings',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'LKR ${savings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${savingsPercent.toStringAsFixed(1)}% savings',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Before',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LKR ${_currentBill.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LKR ${_whatIfBill.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
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

          // Scrollable appliances
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    final index = _whatIfAppliances.indexWhere(
                      (a) => a.applianceId == entry.value.applianceId,
                    );
                    if (index < 0) return const SizedBox.shrink();
                    return _buildAdjustableCard(index, entry.value);
                  }).toList(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildAdjustableCard(int index, HouseholdAppliance ha) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  onTap: () {
                    setState(() {
                      _pinnedAppliances.remove(ha.applianceId);
                    });
                  },
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

            // Quantity
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
                            ? () => _updateQuantity(index, ha, ha.quantity - 1)
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
                            ? () => _updateQuantity(index, ha, ha.quantity + 1)
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

  Widget _buildUsageSlider(int index, HouseholdAppliance ha) {
    if (ha.dailyHours != null) {
      return LabeledSlider(
        label: 'Daily use',
        value: ha.dailyHours ?? 0,
        min: 0,
        max: 24,
        suffix: 'hours',
        onChanged: (value) => _updateUsage(index, ha, value, 'daily'),
      );
    } else if (ha.weeklyHours != null) {
      return LabeledSlider(
        label: 'Weekly use',
        value: ha.weeklyHours ?? 0,
        min: 0,
        max: 48,
        suffix: 'hours',
        onChanged: (value) => _updateUsage(index, ha, value, 'weekly'),
      );
    } else if (ha.weeklyCycles != null) {
      return LabeledSlider(
        label: 'Weekly cycles',
        value: ha.weeklyCycles ?? 0,
        min: 0,
        max: 20,
        suffix: 'cycles',
        onChanged: (value) => _updateUsage(index, ha, value, 'cycles'),
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
