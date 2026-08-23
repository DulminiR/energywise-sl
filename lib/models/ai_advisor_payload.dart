/// Payload sent to Claude for AI advisor recommendations.
/// Contains all calculated data needed for personalized advice.
class AIAdvisorPayload {
  final HouseholdData household;
  final BillingData billing;
  final TariffStatusData tariffStatus;
  final List<ApplianceConsumerData> topConsumers;
  final List<WhatIfScenarioData> whatIfScenarios;

  AIAdvisorPayload({
    required this.household,
    required this.billing,
    required this.tariffStatus,
    required this.topConsumers,
    required this.whatIfScenarios,
  });

  /// Convert to JSON for sending to Claude.
  Map<String, dynamic> toJson() {
    return {
      'household': household.toJson(),
      'billing': billing.toJson(),
      'tariff_status': tariffStatus.toJson(),
      'top_5_consumers': topConsumers.map((c) => c.toJson()).toList(),
      'what_if_scenarios': whatIfScenarios.map((s) => s.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'AIAdvisorPayload(kWh: ${billing.monthlyKwh}, bill: LKR ${billing.estimatedBillLkr})';
}

/// Household context data.
class HouseholdData {
  final String archetype; // 'studio', 'standard_house', 'large_house'
  final List<ApplianceSelectionData> selectedAppliances;

  HouseholdData({required this.archetype, required this.selectedAppliances});

  Map<String, dynamic> toJson() {
    return {
      'archetype': archetype,
      'selected_appliances': selectedAppliances.map((a) => a.toJson()).toList(),
    };
  }
}

/// Individual appliance selection with cost breakdown.
class ApplianceSelectionData {
  final String id;
  final String name;
  final int quantity;
  final double? dailyHours;
  final double? weeklyCycles;
  final String ageSelection;
  final double monthlyKwh;
  final double monthlyCostLkr;

  ApplianceSelectionData({
    required this.id,
    required this.name,
    required this.quantity,
    this.dailyHours,
    this.weeklyCycles,
    required this.ageSelection,
    required this.monthlyKwh,
    required this.monthlyCostLkr,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'daily_hours': dailyHours,
      'weekly_cycles': weeklyCycles,
      'age_selection': ageSelection,
      'monthly_kwh': monthlyKwh,
      'monthly_cost_lkr': monthlyCostLkr,
    };
  }
}

/// Billing summary.
class BillingData {
  final double monthlyKwh;
  final double estimatedBillLkr;
  final double? actualBillLkr;
  final double? differenceLkr;

  BillingData({
    required this.monthlyKwh,
    required this.estimatedBillLkr,
    this.actualBillLkr,
    this.differenceLkr,
  });

  Map<String, dynamic> toJson() {
    return {
      'monthly_kwh': monthlyKwh,
      'estimated_bill_lkr': estimatedBillLkr,
      'actual_bill_lkr': actualBillLkr,
      'difference_lkr': differenceLkr,
    };
  }
}

/// Current tariff position and savings potential.
class TariffStatusData {
  final int currentBand;
  final String bandName;
  final double bandRateLkrPerKwh;
  final double remainingKwhInBand;
  final double kwhToNextLowerBand; // How much to reduce to reach lower band
  final double? savingsAtLowerBandLkr; // Estimated savings if you reach it

  TariffStatusData({
    required this.currentBand,
    required this.bandName,
    required this.bandRateLkrPerKwh,
    required this.remainingKwhInBand,
    required this.kwhToNextLowerBand,
    this.savingsAtLowerBandLkr,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_band': currentBand,
      'band_name': bandName,
      'band_rate_lkr_per_kwh': bandRateLkrPerKwh,
      'remaining_kwh_in_band': remainingKwhInBand,
      'kwh_to_next_lower_band': kwhToNextLowerBand,
      'savings_at_lower_band_lkr': savingsAtLowerBandLkr,
    };
  }
}

/// Top 5 appliances by cost contribution.
class ApplianceConsumerData {
  final String name;
  final double monthlyKwh;
  final double monthlyCostLkr;
  final double percentageOfBill;

  ApplianceConsumerData({
    required this.name,
    required this.monthlyKwh,
    required this.monthlyCostLkr,
    required this.percentageOfBill,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'monthly_kwh': monthlyKwh,
      'monthly_cost_lkr': monthlyCostLkr,
      'percentage_of_bill': percentageOfBill,
    };
  }
}

/// What-If scenario with simulated savings.
class WhatIfScenarioData {
  final String scenarioName;
  final double kwhSaved;
  final double lkrSaved;
  final double newTotalKwh;

  WhatIfScenarioData({
    required this.scenarioName,
    required this.kwhSaved,
    required this.lkrSaved,
    required this.newTotalKwh,
  });

  Map<String, dynamic> toJson() {
    return {
      'scenario_name': scenarioName,
      'kwh_saved': kwhSaved,
      'lkr_saved': lkrSaved,
      'new_total_kwh': newTotalKwh,
    };
  }
}

/// AI Advisor response - ranked recommendations.
class AIAdvisorResponse {
  final TopRecommendation topRecommendation;
  final List<ActionPlanItem> actionPlan;
  final String chatContext;

  AIAdvisorResponse({
    required this.topRecommendation,
    required this.actionPlan,
    required this.chatContext,
  });

  /// Parse from Claude's JSON response.
  factory AIAdvisorResponse.fromJson(Map<String, dynamic> json) {
    return AIAdvisorResponse(
      topRecommendation: TopRecommendation.fromJson(
        json['top_recommendation'] as Map<String, dynamic>,
      ),
      actionPlan: (json['action_plan'] as List)
          .map((item) => ActionPlanItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      chatContext: json['chat_context'] as String,
    );
  }
}

/// Single ranked recommendation.
class TopRecommendation {
  final String title;
  final String appliance;
  final String action;
  final double estimatedMonthlySavingsLkr;
  final String effortLevel; // 'easy', 'medium', 'challenging'

  TopRecommendation({
    required this.title,
    required this.appliance,
    required this.action,
    required this.estimatedMonthlySavingsLkr,
    required this.effortLevel,
  });

  factory TopRecommendation.fromJson(Map<String, dynamic> json) {
    return TopRecommendation(
      title: json['title'] as String,
      appliance: json['appliance'] as String,
      action: json['action'] as String,
      estimatedMonthlySavingsLkr: (json['estimated_monthly_savings_lkr'] as num)
          .toDouble(),
      effortLevel: json['effort_level'] as String,
    );
  }
}

/// Individual action plan item (card in UI).
class ActionPlanItem {
  final int rank;
  final String title;
  final String appliance;
  final double savingsLkr;
  final String effort;
  final String? description;

  ActionPlanItem({
    required this.rank,
    required this.title,
    required this.appliance,
    required this.savingsLkr,
    required this.effort,
    this.description,
  });

  factory ActionPlanItem.fromJson(Map<String, dynamic> json) {
    return ActionPlanItem(
      rank: json['rank'] as int,
      title: json['title'] as String,
      appliance: json['appliance'] as String,
      savingsLkr: (json['savings'] as num).toDouble(),
      effort: json['effort'] as String,
      description: json['description'] as String?,
    );
  }
}
