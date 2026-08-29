import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/ai_advisor_payload.dart';

/// Gemini AI Advisor Service - Uses Google's Gemini API
class AIAdvisorServiceGemini {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // Updated model endpoint to gemini-2.5-flash
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-3.6-flash:generateContent';

  /// Generate recommendations using Gemini API
  Future<AIAdvisorResponse> generateRecommendations(
    AIAdvisorPayload payload,
  ) async {
    try {
      final prompt = _buildPrompt(payload);

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 4000},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Parse Gemini response into structured recommendations
        return _parseGeminiResponse(responseText, payload);
      } else {
        print('Gemini API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      throw Exception('Failed to get recommendations: $e');
    }
  }

  /// Ask Gemini a follow-up question using the same data from recommendations
  Future<String> askAdvisor(AIAdvisorPayload payload, String question) async {
    try {
      // Build the same detailed prompt, but focus on the specific question
      final topAppliancesList = payload.topConsumers.isNotEmpty
          ? payload.topConsumers
                .map(
                  (c) =>
                      '${c.name} (${c.percentageOfBill.toStringAsFixed(1)}%, LKR ${c.monthlyCostLkr.toStringAsFixed(0)}/month)',
                )
                .join('\n')
          : 'No data available';

      final prompt =
          '''
You are an energy efficiency advisor for Sri Lankan households.

HOUSEHOLD CONTEXT:
- Monthly consumption: ${payload.billing.monthlyKwh} kWh
- Estimated bill: LKR ${payload.billing.estimatedBillLkr}
- Tariff band: Band ${payload.tariffStatus.currentBand} (LKR ${payload.tariffStatus.bandRateLkrPerKwh}/kWh)
- Home type: ${payload.household.archetype}

TOP ENERGY CONSUMERS:
$topAppliancesList

User Question: $question

IMPORTANT: Answer in 2-3 sentences MAX. Be direct and practical. Reference specific appliances and savings amounts. No lengthy explanations.
''';

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 3000, // Increased from 500 for better answers
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in askAdvisor: $e');
      throw Exception('Failed to get response: $e');
    }
  }

  /// Build prompt for Gemini
  String _buildPrompt(AIAdvisorPayload payload) {
    final topAppliances = payload.topConsumers
        .map((c) => '${c.name} (${c.percentageOfBill.toStringAsFixed(1)}%)')
        .join('\n');

    return '''
You are an energy efficiency advisor for Sri Lankan households. Analyze this household's electricity consumption and provide 3-5 ranked recommendations to reduce their bill.

HOUSEHOLD DATA:
- Monthly consumption: ${payload.billing.monthlyKwh} kWh
- Estimated bill: LKR ${payload.billing.estimatedBillLkr}
- Tariff band: Band ${payload.tariffStatus.currentBand} (LKR ${payload.tariffStatus.bandRateLkrPerKwh}/kWh)
- Home type: ${payload.household.archetype}

TOP ENERGY CONSUMERS:
$topAppliances

Please provide:
1. A brief analysis (1-2 sentences)
2. Ranked recommendations in this exact format:
   Recommendation 1: [Action] - Saves approximately LKR [amount]/month - Effort: [Easy/Medium/Hard]
   Recommendation 2: [Action] - Saves approximately LKR [amount]/month - Effort: [Easy/Medium/Hard]
   (continue for 3-5 recommendations)
3. A personalized message about their consumption compared to other ${payload.household.archetype} households in Sri Lanka

Be specific, practical, and focused on Sri Lankan context (appliances, habits, climate).
''';
  }

  /// Parse Gemini response into structured format
  AIAdvisorResponse _parseGeminiResponse(
    String responseText,
    AIAdvisorPayload payload,
  ) {
    try {
      // Extract top recommendation
      final topAppliance = payload.topConsumers.isNotEmpty
          ? payload.topConsumers.first
          : ApplianceConsumerData(
              name: 'Top appliance',
              monthlyKwh: 0,
              monthlyCostLkr: 0,
              percentageOfBill: 0,
            );

      final topRecommendation = TopRecommendation(
        title: 'Reduce ${topAppliance.name} usage',
        appliance: topAppliance.name,
        action:
            'Adjust your ${topAppliance.name} usage patterns to save energy.',
        estimatedMonthlySavingsLkr: (topAppliance.monthlyCostLkr * 0.15),
        effortLevel: 'easy',
      );

      // Parse action plan from Gemini response
      final actionPlan = <ActionPlanItem>[];
      final lines = responseText.split('\n');

      int rank = 1;
      for (var line in lines) {
        if (line.contains('Recommendation') && line.contains(':')) {
          final parts = line.split('-');
          if (parts.length >= 2) {
            final action = parts[0]
                .replaceAll('Recommendation $rank:', '')
                .trim();
            final savings = _extractSavingsAmount(parts[1]);
            final effort = _extractEffortLevel(line);

            // Try to extract appliance name from action
            final applianceName = _extractApplianceName(action, payload);

            actionPlan.add(
              ActionPlanItem(
                rank: rank,
                title: action,
                appliance: applianceName,
                savingsLkr: savings,
                effort: effort,
                description: action,
              ),
            );
            rank++;
          }
        }
      }

      // Fallback if no recommendations parsed
      if (actionPlan.isEmpty) {
        actionPlan.add(
          ActionPlanItem(
            rank: 1,
            title: 'Review your top appliances',
            appliance: payload.topConsumers.isNotEmpty
                ? payload.topConsumers.first.name
                : 'Top appliance',
            description:
                'Focus on reducing usage of your highest-consuming appliances.',
            savingsLkr: 500,
            effort: 'medium',
          ),
        );
      }

      return AIAdvisorResponse(
        topRecommendation: topRecommendation,
        actionPlan: actionPlan,
        chatContext: responseText,
      );
    } catch (e) {
      print('Error parsing Gemini response: $e');
      // Return default response
      final defaultAppliance = payload.topConsumers.isNotEmpty
          ? payload.topConsumers.first.name
          : 'Top appliance';

      return AIAdvisorResponse(
        topRecommendation: TopRecommendation(
          title: 'Optimize your consumption',
          appliance: defaultAppliance,
          action: 'Review and adjust your appliance usage.',
          estimatedMonthlySavingsLkr: 500,
          effortLevel: 'easy',
        ),
        actionPlan: [
          ActionPlanItem(
            rank: 1,
            title: 'Check your top consumers',
            appliance: defaultAppliance,
            description: 'Focus on appliances using the most energy.',
            savingsLkr: 300,
            effort: 'easy',
          ),
        ],
        chatContext: responseText,
      );
    }
  }

  /// Extract appliance name from action text
  String _extractApplianceName(String text, AIAdvisorPayload payload) {
    for (var consumer in payload.topConsumers) {
      if (text.toLowerCase().contains(consumer.name.toLowerCase())) {
        return consumer.name;
      }
    }
    // Default to top consumer
    return payload.topConsumers.isNotEmpty
        ? payload.topConsumers.first.name
        : 'Top appliance';
  }

  /// Extract savings amount from text
  double _extractSavingsAmount(String text) {
    final regex = RegExp(r'LKR\s*(\d+)');
    final match = regex.firstMatch(text);
    if (match != null) {
      return double.parse(match.group(1) ?? '0');
    }
    return 500; // Default
  }

  /// Extract effort level from text
  String _extractEffortLevel(String text) {
    if (text.toLowerCase().contains('easy')) return 'easy';
    if (text.toLowerCase().contains('hard') ||
        text.toLowerCase().contains('challenging'))
      return 'challenging';
    return 'medium';
  }
}
