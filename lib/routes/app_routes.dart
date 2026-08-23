/// Central location for all app routes and screen names.
/// Instead of hardcoding 'screen_name' everywhere, we use these constants.
class AppRoutes {
  static const String welcome = '/welcome';
  static const String householdArchetype = '/archetype';
  static const String applianceTuning = '/appliance-tuning';
  static const String billCalibration = '/bill-calibration';
  static const String dashboard = '/dashboard';
  static const String whatIfSandbox = '/what-if';
  static const String aiAdvisor = '/advisor';

  /// Screen order for navigation
  static const List<String> screenOrder = [
    welcome,
    householdArchetype,
    applianceTuning,
    billCalibration,
    dashboard,
    whatIfSandbox,
    aiAdvisor,
  ];

  /// Get the next screen in the flow
  static String? getNextScreen(String currentScreen) {
    final index = screenOrder.indexOf(currentScreen);
    if (index >= 0 && index < screenOrder.length - 1) {
      return screenOrder[index + 1];
    }
    return null;
  }

  /// Get the previous screen in the flow
  static String? getPreviousScreen(String currentScreen) {
    final index = screenOrder.indexOf(currentScreen);
    if (index > 0) {
      return screenOrder[index - 1];
    }
    return null;
  }
}
