import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../routes/app_routes.dart';
import '../widgets/reusable_components.dart';

/// Household archetype selection screen.
/// User chooses between Studio, Standard, or Large house.
class ArchetypeScreen extends StatefulWidget {
  const ArchetypeScreen({Key? key}) : super(key: key);

  @override
  State<ArchetypeScreen> createState() => _ArchetypeScreenState();
}

class _ArchetypeScreenState extends State<ArchetypeScreen> {
  String? selectedArchetype;

  final List<Map<String, dynamic>> archetypes = [
    {
      'id': 'studio',
      'name': 'Studio / Small Home',
      'description': '1–2 people • Few appliances',
      'icon': Icons.home_work,
    },
    {
      'id': 'standard_house',
      'name': 'Standard House',
      'description': '2–4 people • Typical appliance usage',
      'icon': Icons.home,
    },
    {
      'id': 'large_house',
      'name': 'Large House',
      'description': '4+ people • More rooms and appliances',
      'icon': Icons.villa,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Step 1 of 6',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Let's start with your home",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the option that feels closest to your household. You can customize everything later.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Archetype Cards
                ...archetypes.map((archetype) {
                  final isSelected = selectedArchetype == archetype['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedArchetype = archetype['id'];
                        });
                      },
                      child: CustomCard(
                        backgroundColor: isSelected
                            ? const Color(0xFFE0F2F1)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF005F54)
                              : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                archetype['icon'],
                                color: isSelected
                                    ? const Color(0xFF005F54)
                                    : Colors.grey[600],
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        archetype['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? const Color(0xFF005F54)
                                              : const Color(0xFF212121),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF005F54),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    archetype['description'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? const Color(0xFF005F54)
                                                .withOpacity(0.7)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 24),

                // Info Box
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    border: Border.all(
                      color: const Color(0xFFB2DFDB),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF005F54),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This preset helps us estimate your baseline. You\'ll be able to adjust every specific appliance in the next step.',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF005F54).withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: PrimaryButton(
          label: 'Continue',
          onPressed: selectedArchetype == null
              ? null
              : () {
                  // Save selection to AppState
                  context.read<AppState>().setArchetype(selectedArchetype!);

                  // Navigate to next screen
                  Navigator.pushNamed(context, AppRoutes.applianceTuning);
                },
        ),
      ),
    );
  }
}
