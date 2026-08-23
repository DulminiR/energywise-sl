import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'models/app_state.dart';
import 'routes/app_routes.dart';
import 'screens/welcome_screen.dart';
import 'screens/archetype_screen.dart';
import 'screens/appliance_tuning_screen.dart';
import 'screens/bill_calibration_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/whatif_sandbox_screen.dart';
import 'screens/ai_advisor_screen.dart';

void main() async {
  // Load .env before anything else
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'EnergyWise SL',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF005F54),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        initialRoute: AppRoutes.welcome,
        routes: {
          // Placeholder routes - we'll build these next
          AppRoutes.welcome: (context) => const WelcomeScreen(),
          AppRoutes.householdArchetype: (context) => const ArchetypeScreen(),
          AppRoutes.applianceTuning: (context) => const ApplianceTuningScreen(),
          AppRoutes.billCalibration: (context) => const BillCalibrationScreen(),
          AppRoutes.dashboard: (context) => const DashboardScreen(),
          AppRoutes.whatIfSandbox: (context) => const WhatIfSandboxScreen(),
          AppRoutes.aiAdvisor: (context) => const AIAdvisorScreen(),
        },
      ),
    );
  }
}
