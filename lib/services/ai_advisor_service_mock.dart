import '../models/ai_advisor_payload.dart';
import 'ai_advisor_service_interface.dart';

/// Mock AI Advisor Service - returns hardcoded recommendations.
/// Use this for development/testing without API calls or credits.
/// Implements the same interface as the real service.
class AIAdvisorServiceMock implements IAIAdvisorService {
  @override
  Future<AIAdvisorResponse> generateRecommendations(
    AIAdvisorPayload payload,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return hardcoded recommendations based on the payload
    return AIAdvisorResponse(
      topRecommendation: TopRecommendation(
        title: 'Reduce air-conditioner usage by 2 hours/day',
        appliance: 'Air Conditioner',
        action: 'Reduce daily use from 5 to 3 hours',
        estimatedMonthlySavingsLkr: 720,
        effortLevel: 'easy',
      ),
      actionPlan: [
        ActionPlanItem(
          rank: 1,
          title: 'Reduce air-conditioner usage by 2 hours/day',
          appliance: 'Air Conditioner',
          savingsLkr: 720,
          effort: 'easy',
          description: 'Your AC is the highest cost appliance. Reducing by 2 hours/day saves ~LKR 720/month and moves you closer to a lower tariff block.',
        ),
        ActionPlanItem(
          rank: 2,
          title: 'Shorten hot-water usage',
          appliance: 'Water Heater',
          savingsLkr: 340,
          effort: 'medium',
          description: 'Reducing shower time or temperature settings can save ~LKR 340/month without major lifestyle changes.',
        ),
        ActionPlanItem(
          rank: 3,
          title: 'Reduce fan usage',
          appliance: 'Ceiling Fan',
          savingsLkr: 90,
          effort: 'easy',
          description: 'Using fans for only 6 hours/day instead of 8 saves ~LKR 90/month.',
        ),
        ActionPlanItem(
          rank: 4,
          title: 'Switch off unused lights',
          appliance: 'Lighting',
          savingsLkr: 60,
          effort: 'easy',
          description: 'Low-impact but adds up. Ensure lights are off in unused rooms during the day.',
        ),
      ],
      chatContext: 'Your air conditioner is the biggest cost driver at 34% of your bill. You\'re currently in the highest tariff band. Small reductions could save you significantly.',
    );
  }

  @override
  Future<String> askAdvisor(
    AIAdvisorPayload payload,
    String userQuestion,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Return mock responses based on common questions
    if (userQuestion.toLowerCase().contains('save')) {
      return 'Based on your usage, the biggest opportunity is reducing your air conditioner use by 2 hours per day, which could save you LKR 720/month. Your AC is currently consuming 34% of your total bill.';
    } else if (userQuestion.toLowerCase().contains('bill')) {
      return 'Your estimated monthly bill is LKR 8,450 based on 182 kWh usage. You\'re in the highest tariff band (Band 4). Reducing your consumption by just 6 kWh would move you to a lower tariff and save you approximately LKR 120/month.';
    } else if (userQuestion.toLowerCase().contains('tariff') ||
        userQuestion.toLowerCase().contains('band')) {
      return 'You\'re currently in Band 4 (Very High), paying 6.10 LKR per kWh. If you reduce your usage to 176 kWh or below, you\'d move to Band 3 and save money on every kWh consumed. That\'s why small reductions have outsized impact.';
    } else if (userQuestion.toLowerCase().contains('appliance')) {
      return 'Your top 3 cost drivers are: (1) Air Conditioner - LKR 2,900/month, (2) Water Heater - LKR 1,650/month, (3) Refrigerator - LKR 1,050/month. These three account for 65% of your total bill.';
    } else {
      return 'I can help answer questions about your bill, appliances, recommendations, tariff position, and potential savings. What would you like to know?';
    }
  }
}
