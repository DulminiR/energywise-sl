import '../models/ai_advisor_payload.dart';

/// Abstract interface that any AI advisor service must implement.
/// Both mock and real services implement this.
/// This allows swapping implementations without changing calling code.
abstract class IAIAdvisorService {
  /// Generate ranked recommendations from household data.
  /// Returns structured action plan + chat context.
  Future<AIAdvisorResponse> generateRecommendations(AIAdvisorPayload payload);

  /// Generate a chat response from user question.
  /// Uses the same payload as context.
  Future<String> askAdvisor(AIAdvisorPayload payload, String userQuestion);
}
