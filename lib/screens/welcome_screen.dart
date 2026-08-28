import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../widgets/reusable_components.dart';

/// Welcome/onboarding screen.
/// First screen users see - explains value proposition and starts the flow.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Logo Section
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 48),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF005F54),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'EnergyWise SL',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005F54),
                      ),
                    ),
                  ],
                ),
              ),

              // Illustration placeholder (using icon)
              Expanded(
                child: Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 100,
                      color: Color(0xFF005F54),
                    ),
                  ),
                ),
              ),

              // Text Content
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  children: [
                    const Text(
                      'Understand your electricity.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Spend smarter.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005F54),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'See what is driving your electricity bill, explore simple ways to reduce it, and get personalized recommendations.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Button + Footer
              Column(
                children: [
                  PrimaryButton(
                    label: 'Get Started',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.householdArchetype,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.electrical_services,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No smart meter needed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
