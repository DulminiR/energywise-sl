import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/ai_advisor_payload.dart';
import '../routes/app_routes.dart';
import '../services/ai_advisor_service_gemini.dart';
import '../services/energy_calculation_engine.dart';
import '../services/tariff_engine.dart';
import '../services/appliance_service.dart';
import '../widgets/reusable_components.dart';
import 'ai_advisor_chat_screen.dart';

/// AI Advisor screen - displays ranked recommendations and chat.
/// Shows personalized action plan based on household data.
class AIAdvisorScreen extends StatefulWidget {
  const AIAdvisorScreen({Key? key}) : super(key: key);

  @override
  State<AIAdvisorScreen> createState() => _AIAdvisorScreenState();
}

class _AIAdvisorScreenState extends State<AIAdvisorScreen> {
  final AIAdvisorServiceGemini _advisorService = AIAdvisorServiceGemini();
  final EnergyCalculationEngine _energyEngine = EnergyCalculationEngine();
  final TariffEngine _tariffEngine = TariffEngine();
  final ApplianceService _applianceService = ApplianceService();

  AIAdvisorResponse? _recommendations;
  bool _isLoading = true;
  bool _showChat = false;
  TextEditingController _chatController = TextEditingController();
  List<ChatMessage> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _generateRecommendations();
  }

  /// Generate recommendations from household data
  Future<void> _generateRecommendations() async {
    try {
      final appState = context.read<AppState>();

      // Build AI payload from current state
      final payload = await _buildAIPayload(appState);

      // Get recommendations from mock service
      final recommendations = await _advisorService.generateRecommendations(
        payload,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
        // Add initial context to chat
        _chatMessages = [
          ChatMessage(
            text: recommendations.chatContext,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];
      });
    } catch (e) {
      print('Error generating recommendations: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Build AI advisor payload from current state
  Future<AIAdvisorPayload> _buildAIPayload(AppState appState) async {
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

    // Calculate appliance-level costs
    final applianceSelections = <ApplianceSelectionData>[];
    final topConsumers = <ApplianceConsumerData>[];

    final applianceCosts = <MapEntry<String, double>>[];

    for (final ha in appState.householdAppliances) {
      if (!ha.isEnabled) continue;

      final appliance = catalogMap[ha.applianceId];
      if (appliance == null) continue;

      final kwh = _calculateApplianceKwh(appliance, ha);
      final cost = kwh * 5.0; // Rough estimate

      applianceCosts.add(MapEntry(ha.name, kwh));
      applianceSelections.add(
        ApplianceSelectionData(
          id: ha.applianceId,
          name: ha.name,
          quantity: ha.quantity.toInt(),
          dailyHours: ha.dailyHours,
          weeklyCycles: ha.weeklyCycles,
          ageSelection: ha.ageSelection,
          monthlyKwh: kwh,
          monthlyCostLkr: cost,
        ),
      );
    }

    // Sort by cost and get top 5
    applianceCosts.sort((a, b) => b.value.compareTo(a.value));
    for (final entry in applianceCosts.take(5)) {
      final percentage = (entry.value / totalKwh) * 100;
      topConsumers.add(
        ApplianceConsumerData(
          name: entry.key,
          monthlyKwh: entry.value,
          monthlyCostLkr: entry.value * 5.0,
          percentageOfBill: percentage,
        ),
      );
    }

    return AIAdvisorPayload(
      household: HouseholdData(
        archetype: appState.selectedArchetype ?? 'standard_house',
        selectedAppliances: applianceSelections,
      ),
      billing: BillingData(
        monthlyKwh: totalKwh,
        estimatedBillLkr: tariffResult.totalBill,
        actualBillLkr: appState.actualMonthlyBill,
        differenceLkr: appState.actualMonthlyBill != null
            ? (appState.actualMonthlyBill! - tariffResult.totalBill).abs()
            : null,
      ),
      tariffStatus: TariffStatusData(
        currentBand: tariffResult.currentBand,
        bandName: tariffResult.currentBandName,
        bandRateLkrPerKwh: tariffResult.currentBandRatePerKwh,
        remainingKwhInBand: tariffResult.remainingKwhInBand,
        kwhToNextLowerBand: 30 - (totalKwh % 30), // Simplified
        savingsAtLowerBandLkr: tariffResult.savingsToNextBand,
      ),
      topConsumers: topConsumers,
      whatIfScenarios: [],
    );
  }

  /// Calculate kWh for single appliance
  double _calculateApplianceKwh(dynamic appliance, dynamic ha) {
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
        appBar: CustomAppBar(title: 'AI Energy Advisor', showBackButton: false),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F54)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(title: 'AI Energy Advisor', showBackButton: false),
      body: _buildRecommendationsView(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              label: 'Ask Question',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIAdvisorChatScreen(
                      payload: _buildPayload(), // Pass the data to chat
                    ),
                  ),
                );
              },
            ),
          ),
          BottomNav(
            currentRoute: AppRoutes.aiAdvisor,
            onNavigate: (route) {
              Navigator.pushNamed(context, route);
            },
          ),
        ],
      ),
    );
  }

  /// Build payload for chat screen
  AIAdvisorPayload _buildPayload() {
    final appState = context.read<AppState>();
    return AIAdvisorPayload(
      household: HouseholdData(
        archetype: appState.selectedArchetype ?? 'standard_house',
        selectedAppliances: [],
      ),
      billing: BillingData(
        monthlyKwh: appState.totalMonthlyKwh ?? 0,
        estimatedBillLkr: appState.estimatedBillLkr ?? 0,
      ),
      tariffStatus: TariffStatusData(
        currentBand: 3,
        bandName: 'Band 3',
        bandRateLkrPerKwh: 5.23,
        remainingKwhInBand: 30,
        kwhToNextLowerBand: 0,
      ),
      topConsumers:
          _recommendations?.actionPlan
              .map(
                (item) => ApplianceConsumerData(
                  name: item.appliance,
                  monthlyKwh: 0,
                  monthlyCostLkr: item.savingsLkr,
                  percentageOfBill: 0,
                ),
              )
              .toList() ??
          [],
      whatIfScenarios: [],
    );
  }

  /// Build recommendations view
  Widget _buildRecommendationsView() {
    if (_recommendations == null) {
      return const Center(child: Text('No recommendations available'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Recommendation
            const Text(
              'Your Top Priority',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF999999),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildTopRecommendationCard(_recommendations!.topRecommendation),

            const SizedBox(height: 24),

            // Action Plan
            const Text(
              'Action Plan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF999999),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ..._recommendations!.actionPlan.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActionCard(item),
              ),
            ),

            const SizedBox(height: 24),

            // Chat Button
            //     SizedBox(
            //       width: double.infinity,
            //       child: SecondaryButton(
            //         label: 'Ask Questions',
            //         onPressed: () {
            //           setState(() {
            //             _showChat = true;
            //           });
            //         },
            //       ),
            //     ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Build top recommendation card
  Widget _buildTopRecommendationCard(TopRecommendation rec) {
    final effortColor = rec.effortLevel == 'easy'
        ? const Color(0xFF4CAF50)
        : rec.effortLevel == 'medium'
        ? const Color(0xFFFDD835)
        : const Color(0xFFE65100);

    return CustomCard(
      padding: const EdgeInsets.all(20),
      border: Border.all(color: const Color(0xFF005F54), width: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              '💡 Top Priority',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005F54),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            rec.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rec.action,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Savings',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LKR ${rec.estimatedMonthlySavingsLkr.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005F54),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: effortColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: effortColor, width: 1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  rec.effortLevel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: effortColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build action card
  Widget _buildActionCard(ActionPlanItem item) {
    final effortColor = item.effort == 'easy'
        ? const Color(0xFF4CAF50)
        : item.effort == 'medium'
        ? const Color(0xFFFDD835)
        : const Color(0xFFE65100);

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${item.rank}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005F54),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    if (item.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saves LKR ${item.savingsLkr.toStringAsFixed(0)}/month',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005F54),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: effortColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: effortColor, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  item.effort.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: effortColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }
}

/// Model for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
