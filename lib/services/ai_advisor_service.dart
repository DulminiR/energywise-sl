import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/ai_advisor_payload.dart';
import 'ai_advisor_service_interface.dart';

/// Real AI Advisor Service - calls Claude API.
/// Implements IAIAdvisorService interface (same as mock).
class AIAdvisorService implements IAIAdvisorService {
  static const String _apiEndpoint = 'https://api.anthropic.com/v1/messages';
  static const String _modelId = 'claude-3-5-sonnet-20241022';
  static const int _maxTokens = 1024;

  late String _apiKey;
  bool _initialized = false;

  /// Initialize the service with API key from .env
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
      if (_apiKey.isEmpty) {
        throw Exception('ANTHROPIC_API_KEY not found in .env file');
      }
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize AI Advisor Service: $e');
    }
  }

  /// Generate ranked recommendations from household data.
  /// Returns structured action plan + chat context.
  Future<AIAdvisorResponse> generateRecommendations(
    AIAdvisorPayload payload,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final response = await _callClaude(payload);
      return response;
    } catch (e) {
      throw Exception('Failed to generate recommendations: $e');
    }
  }

  /// Internal: Call Claude API with payload and prompt.
  Future<AIAdvisorResponse> _callClaude(AIAdvisorPayload payload) async {
    // Build the prompt
    final prompt = _buildPrompt(payload);

    // Prepare the request
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': _apiKey,
      'anthropic-version': '2023-06-01',
    };

    final body = jsonEncode({
      'model': _modelId,
      'max_tokens': _maxTokens,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    });

    // Make the API call
    final httpResponse = await http.post(
      Uri.parse(_apiEndpoint),
      headers: headers,
      body: body,
    );

    // Handle response
    if (httpResponse.statusCode != 200) {
      throw Exception(
        'Claude API error: ${httpResponse.statusCode}\n${httpResponse.body}',
      );
    }

    // Parse response
    final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
    final content = responseData['content'] as List;
    final textContent = content.first['text'] as String;

    // Extract JSON from Claude's response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(textContent);
    if (jsonMatch == null) {
      throw Exception('Could not extract JSON from Claude response');
    }

    final jsonStr = jsonMatch.group(0)!;
    final recommendationJson = jsonDecode(jsonStr) as Map<String, dynamic>;

    return AIAdvisorResponse.fromJson(recommendationJson);
  }

  /// Build the prompt that Claude receives.
  /// This defines the behavior and output format.
  String _buildPrompt(AIAdvisorPayload payload) {
    final payloadJson = jsonEncode(payload.toJson());

    return '''You are EnergyWise, a friendly but direct energy-saving advisor for Sri Lankan households.

Given this household's energy data, provide personalized recommendations to save money on electricity bills.

IMPORTANT RULES:
1. Only use the data provided. Never invent calculations or savings estimates.
2. Be specific: reference appliances by name, estimated LKR savings, and current usage.
3. Prioritize recommendations by potential monthly LKR saved (highest first).
4. Consider practicality: easy actions first, then medium, then challenging.
5. Be encouraging but realistic. Tone: helpful, not preachy.
6. If asked questions outside the data, say "I can only help with information about your bill and appliances."

HOUSEHOLD DATA:
$payloadJson

Generate a JSON response with this exact structure (no markdown, just raw JSON):
{
  "top_recommendation": {
    "title": "Specific action title",
    "appliance": "Appliance name",
    "action": "Specific change (e.g., 'Reduce AC by 2 hours/day')",
    "estimated_monthly_savings_lkr": 720,
    "effort_level": "easy"
  },
  "action_plan": [
    {
      "rank": 1,
      "title": "Action title",
      "appliance": "Appliance name",
      "savings": 720,
      "effort": "easy",
      "description": "Brief explanation of why this saves money"
    },
    {
      "rank": 2,
      "title": "Action title",
      "appliance": "Appliance name",
      "savings": 340,
      "effort": "medium",
      "description": "Brief explanation"
    }
  ],
  "chat_context": "Brief summary of their biggest cost driver and tariff position (max 100 words)"
}

Provide ONLY the JSON, no additional text.''';
  }

  /// Generate a chat response from user question.
  /// Uses the same payload as context.
  @override
  Future<String> askAdvisor(
    AIAdvisorPayload payload,
    String userQuestion,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final response = await _callClaudeForChat(payload, userQuestion);
      return response;
    } catch (e) {
      throw Exception('Failed to get chat response: $e');
    }
  }

  /// Internal: Call Claude API for conversational chat.
  Future<String> _callClaudeForChat(
    AIAdvisorPayload payload,
    String userQuestion,
  ) async {
    final prompt = _buildChatPrompt(payload, userQuestion);

    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': _apiKey,
      'anthropic-version': '2023-06-01',
    };

    final body = jsonEncode({
      'model': _modelId,
      'max_tokens': _maxTokens,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    });

    final httpResponse = await http.post(
      Uri.parse(_apiEndpoint),
      headers: headers,
      body: body,
    );

    if (httpResponse.statusCode != 200) {
      throw Exception(
        'Claude API error: ${httpResponse.statusCode}\n${httpResponse.body}',
      );
    }

    final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
    final content = responseData['content'] as List;
    final textContent = content.first['text'] as String;

    return textContent;
  }

  /// Build chat prompt for Claude.
  String _buildChatPrompt(AIAdvisorPayload payload, String userQuestion) {
    final payloadJson = jsonEncode(payload.toJson());

    return '''You are EnergyWise, a friendly energy-saving advisor for Sri Lankan households.

A user has asked you a question about their electricity bill and energy usage.

IMPORTANT:
1. Only answer based on the provided household data. Don't invent information.
2. Be specific: use actual numbers from their bill and appliances.
3. Be helpful and encouraging.
4. If the question is outside your knowledge (not about their energy), politely redirect.

HOUSEHOLD DATA:
$payloadJson

USER QUESTION:
$userQuestion

Provide a helpful, conversational response (not JSON, just plain text). Keep it under 150 words.''';
  }
}
