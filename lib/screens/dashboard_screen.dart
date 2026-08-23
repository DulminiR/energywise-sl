import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/app_state.dart';
import '../models/household_appliance.dart';
import '../routes/app_routes.dart';
import '../services/energy_calculation_engine.dart';
import '../services/tariff_engine.dart';
import '../services/appliance_service.dart';
import '../widgets/reusable_components.dart';

/// Dashboard screen - main overview of energy consumption and costs.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EnergyCalculationEngine _energyEngine = EnergyCalculationEngine();
  final TariffEngine _tariffEngine = TariffEngine();
  final ApplianceService _applianceService = ApplianceService();

  double? _totalKwh;
  double? _estimatedBill;
  int? _currentBand;
  String? _bandName;
  bool _isLoading = true;
  List<MapEntry<String, double>>? _topConsumers;
  int? _touchedIndex; // Track which pie slice is tapped
  String? _selectedArchetype; // Track which archetype was selected
  double? _averageKwhForArchetype; // Average for comparison

  @override
  void initState() {
    super.initState();
    _calculateEnergyAndBill();
  }

  /// Calculate total energy and bill
  /// Calculate total energy and bill
  Future<void> _calculateEnergyAndBill() async {
    try {
      final appState = context.read<AppState>();

      // Get archetype for comparison
      _selectedArchetype = appState.selectedArchetype ?? 'standard_house';
      _averageKwhForArchetype = _getAverageKwhForArchetype(_selectedArchetype!);

      final householdAppliances = appState.householdAppliances;

      final appliances = await _applianceService.loadAppliances();
      final catalogMap = {for (var a in appliances) a.id: a};

      final totalKwh = _energyEngine.calculateTotalMonthlyKwh(
        householdAppliances,
        catalogMap,
      );

      await _tariffEngine.loadTariffConfig();
      final tariffResult = await _tariffEngine.calculateBill(totalKwh);

      // Calculate top consumers
      final consumers = <MapEntry<String, double>>[];
      for (final ha in householdAppliances) {
        if (!ha.isEnabled) continue;

        final appliance = catalogMap[ha.applianceId];
        if (appliance == null) continue;

        final kwhForAppliance = _calculateApplianceKwh(appliance, ha);
        consumers.add(MapEntry(ha.name, kwhForAppliance));
      }

      consumers.sort((a, b) => b.value.compareTo(a.value));
      final topFive = consumers.take(5).toList();

      setState(() {
        _totalKwh = totalKwh;
        _estimatedBill = tariffResult.totalBill;
        _currentBand = tariffResult.currentBand;
        _bandName = tariffResult.currentBandName;
        _topConsumers = topFive;
        _isLoading = false;
      });

      appState.setCalculationResults(totalKwh, tariffResult.totalBill);
    } catch (e) {
      print('Error calculating bill: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get average kWh for archetype
  double _getAverageKwhForArchetype(String archetype) {
    switch (archetype) {
      case 'studio':
        return 75;
      case 'standard_house':
        return 130;
      case 'large_house':
        return 220;
      default:
        return 130;
    }
  }

  /// Get consumption status message
  String _getConsumptionStatus() {
    if (_totalKwh == null || _averageKwhForArchetype == null) return '';

    final difference = _totalKwh! - _averageKwhForArchetype!;
    final percentDiff = (difference / _averageKwhForArchetype!) * 100;

    if (percentDiff > 20) {
      // Above average
      String archetype = _selectedArchetype == 'studio'
          ? 'studio apartment'
          : _selectedArchetype == 'large_house'
          ? 'large household'
          : 'standard household';
      return 'Your consumption is a little bit above average compared to a regular $archetype in Sri Lanka.';
    } else if (percentDiff < -20) {
      // Below average
      return 'Your consumption is below average, which is really good.';
    } else {
      // In acceptance range
      return 'Your consumption is in the acceptance range.';
    }
  }

  /// Calculate kWh for a single appliance
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
        appBar: CustomAppBar(title: 'Your Energy', showBackButton: false),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F54)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(title: 'Your Energy', showBackButton: false),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card
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
                      'Estimated monthly bill',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LKR ${_estimatedBill?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: Color(0xFFFDD835),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_totalKwh?.toStringAsFixed(0) ?? '0'} kWh / month',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tariff status bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Tariff Band',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              'Band $_currentBand',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_currentBand ?? 1) / 5,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFDD835),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // DYNAMIC CONSUMPTION STATUS BOX
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color:
                          _totalKwh != null &&
                              _totalKwh! >
                                  (_averageKwhForArchetype ?? 130) * 1.2
                          ? const Color(0xFFFFF3E0) // Orange if above average
                          : const Color(0xFFE8F5E9), // Green if average/below
                      border: Border.all(
                        color:
                            _totalKwh != null &&
                                _totalKwh! >
                                    (_averageKwhForArchetype ?? 130) * 1.2
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFF81C784),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _totalKwh != null &&
                                    _totalKwh! >
                                        (_averageKwhForArchetype ?? 130) * 1.2
                                ? Icons.info_outline
                                : Icons.check_circle_outline,
                            color:
                                _totalKwh != null &&
                                    _totalKwh! >
                                        (_averageKwhForArchetype ?? 130) * 1.2
                                ? const Color(0xFFE65100)
                                : const Color(0xFF2E7D32),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getConsumptionStatus(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color:
                                  _totalKwh != null &&
                                      _totalKwh! >
                                          (_averageKwhForArchetype ?? 130) * 1.2
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

              // Chart Section
              if (_topConsumers != null && _topConsumers!.isNotEmpty) ...[
                const Text(
                  'What\'s using the most?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF999999),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                CustomCard(child: _buildPieChart()),
                const SizedBox(height: 16),
                // Touched appliance info
                if (_touchedIndex != null &&
                    _touchedIndex! < _topConsumers!.length)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF005F54),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _topConsumers![_touchedIndex!].key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005F54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Top Opportunities
              const Text(
                'Top opportunities',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF999999),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildOpportunityCards(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentRoute: AppRoutes.dashboard,
        onNavigate: (route) {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }

  /// Build pie chart with different colors and interactivity
  Widget _buildPieChart() {
    if (_topConsumers == null || _topConsumers!.isEmpty) {
      return const SizedBox.shrink();
    }

    // DIFFERENT COLORS for each slice
    final colors = [
      const Color(0xFF005F54), // Teal (primary)
      const Color(0xFF1976D2), // Blue
      const Color(0xFFD32F2F), // Red
      const Color(0xFFF57C00), // Orange
      const Color(0xFF7B1FA2), // Purple
    ];

    final total = _topConsumers!.fold<double>(
      0,
      (sum, item) => sum + item.value,
    );

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: List.generate(_topConsumers!.length, (index) {
            final item = _topConsumers![index];
            final percentage = (item.value / total) * 100;
            final isSelected = _touchedIndex == index;

            return PieChartSectionData(
              value: item.value,
              color: colors[index % colors.length],
              title: '${percentage.toStringAsFixed(0)}%',
              radius: isSelected ? 90 : 80, // Enlarge when selected
              titleStyle: TextStyle(
                fontSize: isSelected ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
          centerSpaceRadius: 50,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                final index =
                    pieTouchResponse?.touchedSection?.touchedSectionIndex;
                _touchedIndex = (index != null && index >= 0) ? index : null;
              });
            },
          ),
        ),
      ),
    );
  }

  /// Build opportunity cards
  List<Widget> _buildOpportunityCards() {
    if (_topConsumers == null || _topConsumers!.isEmpty) {
      return [];
    }

    final icons = {
      'Air Conditioner (12,000 BTU)': Icons.wind_power,
      'Hot Water Shower Heater': Icons.water_drop,
      'Refrigerator (Double Door / Single)': Icons.kitchen,
      'Ceiling Fan': Icons.air,
    };

    return _topConsumers!.take(2).map((consumer) {
      final applianceName = consumer.key;
      final kwh = consumer.value;
      final estimatedCost = kwh * 5.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CustomCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icons[applianceName] ?? Icons.lightbulb,
                  color: const Color(0xFF005F54),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applianceName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    Text(
                      'Highest estimated cost',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '~LKR ${estimatedCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005F54),
                    ),
                  ),
                  Text(
                    '/month',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
