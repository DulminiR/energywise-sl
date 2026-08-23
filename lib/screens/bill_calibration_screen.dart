import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../routes/app_routes.dart';
import '../services/energy_calculation_engine.dart';
import '../services/tariff_engine.dart';
import '../services/appliance_service.dart';
import '../widgets/reusable_components.dart';

/// Bill calibration screen.
/// Calculates actual bill from appliances and compares with user's input.
class BillCalibrationScreen extends StatefulWidget {
  const BillCalibrationScreen({Key? key}) : super(key: key);

  @override
  State<BillCalibrationScreen> createState() => _BillCalibrationScreenState();
}

class _BillCalibrationScreenState extends State<BillCalibrationScreen> {
  final TextEditingController _billController = TextEditingController();
  final EnergyCalculationEngine _energyEngine = EnergyCalculationEngine();
  final TariffEngine _tariffEngine = TariffEngine();
  final ApplianceService _applianceService = ApplianceService();

  double? _actualBill;
  double _estimatedBill = 0;
  double _totalKwh = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateEstimatedBill();
  }

  /// Calculate estimated bill from household appliances
  Future<void> _calculateEstimatedBill() async {
    try {
      final appState = context.read<AppState>();

      // Load appliances catalog
      final appliances = await _applianceService.loadAppliances();
      final catalogMap = {for (var a in appliances) a.id: a};

      // Calculate total kWh
      final totalKwh = _energyEngine.calculateTotalMonthlyKwh(
        appState.householdAppliances,
        catalogMap,
      );

      // Calculate bill
      await _tariffEngine.loadTariffConfig();
      final tariffResult = await _tariffEngine.calculateBill(totalKwh);

      setState(() {
        _totalKwh = totalKwh;
        _estimatedBill = tariffResult.totalBill;
        _isLoading = false;
      });

      print('DEBUG: Total kWh = $totalKwh');
      print('DEBUG: Estimated Bill = $_estimatedBill');
    } catch (e) {
      print('Error calculating bill: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateActualBill(String value) {
    setState(() {
      if (value.isEmpty) {
        _actualBill = null;
      } else {
        _actualBill = double.tryParse(value.replaceAll(',', ''));
      }
    });
  }

  void _proceedToDashboard() {
    // Save actual bill if entered
    if (_actualBill != null) {
      context.read<AppState>().setActualBill(_actualBill!);
    }

    // Navigate to dashboard
    Navigator.pushNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: CustomAppBar(
          title: 'Step 3 of 6',
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

    final difference = _actualBill != null
        ? (_actualBill! - _estimatedBill).abs()
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Step 3 of 6',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'How close is our estimate?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your appliances, we calculated an estimated bill. If you have your latest electricity bill, enter it to compare.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Calculated values display
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Estimated Usage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_totalKwh.toStringAsFixed(0)} kWh',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005F54),
                              ),
                            ),
                            Text(
                              'per month',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'LKR ${_estimatedBill.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005F54),
                              ),
                            ),
                            Text(
                              'estimated bill',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Input Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your actual monthly bill',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'LKR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(158, 158, 158, 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _billController,
                            keyboardType: TextInputType.number,
                            onChanged: _updateActualBill,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                            decoration: InputDecoration(
                              hintText: '${_estimatedBill.toStringAsFixed(0)}',
                              hintStyle: TextStyle(
                                fontSize: 24,
                                color: Colors.grey[300],
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Comparison Card
              if (_actualBill != null)
                CustomCard(
                  backgroundColor: Colors.white,
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.balance,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'COMPARISON',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Comparison rows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Our estimate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'LKR ${_estimatedBill.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Your bill',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'LKR ${_actualBill!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005F54),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Difference
                      if (difference != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Difference',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'LKR ${difference.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Info box
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
                        'We calculated your bill based on your appliances and usage. If it differs from your actual bill, you might have appliances we missed.',
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
        padding: const EdgeInsets.all(24),
        child: PrimaryButton(
          label: 'View My Energy',
          onPressed: _proceedToDashboard,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _billController.dispose();
    super.dispose();
  }
}
