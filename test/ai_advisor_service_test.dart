import 'package:flutter_test/flutter_test.dart';
import 'package:energywise_sl/models/ai_advisor_payload.dart';
import 'package:energywise_sl/services/ai_advisor_service_mock.dart';

void main() {
  late AIAdvisorServiceMock advisorService;

  setUp(() {
    advisorService = AIAdvisorServiceMock();
  });

  test('Generate recommendations from mock service', () async {
    final payload = AIAdvisorPayload(
      household: HouseholdData(
        archetype: 'standard_house',
        selectedAppliances: [
          ApplianceSelectionData(
            id: 'air_conditioner_12k',
            name: 'Air Conditioner',
            quantity: 1,
            dailyHours: 5,
            ageSelection: 'standard',
            monthlyKwh: 45,
            monthlyCostLkr: 2900,
          ),
        ],
      ),
      billing: BillingData(monthlyKwh: 182, estimatedBillLkr: 8450),
      tariffStatus: TariffStatusData(
        currentBand: 4,
        bandName: 'Band 4 (Very High)',
        bandRateLkrPerKwh: 6.10,
        remainingKwhInBand: 0,
        kwhToNextLowerBand: 6,
        savingsAtLowerBandLkr: 120,
      ),
      topConsumers: [],
      whatIfScenarios: [],
    );

    final response = await advisorService.generateRecommendations(payload);

    expect(response.topRecommendation, isNotNull);
    expect(response.actionPlan, isNotEmpty);
    expect(response.chatContext, isNotEmpty);
  });

  test('Ask advisor a question', () async {
    final payload = AIAdvisorPayload(
      household: HouseholdData(
        archetype: 'standard_house',
        selectedAppliances: [],
      ),
      billing: BillingData(monthlyKwh: 182, estimatedBillLkr: 8450),
      tariffStatus: TariffStatusData(
        currentBand: 4,
        bandName: 'Band 4 (Very High)',
        bandRateLkrPerKwh: 6.10,
        remainingKwhInBand: 0,
        kwhToNextLowerBand: 6,
      ),
      topConsumers: [],
      whatIfScenarios: [],
    );

    final response = await advisorService.askAdvisor(
      payload,
      'How can I save money on my electricity bill?',
    );

    expect(response, isNotEmpty);
    expect(response.length, greaterThan(10));
  });
}
