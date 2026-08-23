import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/appliance.dart';

/// Service to load and manage appliance catalog.
class ApplianceService {
  static final ApplianceService _instance = ApplianceService._internal();

  factory ApplianceService() {
    return _instance;
  }

  ApplianceService._internal();

  List<Appliance>? _cachedAppliances;

  /// Load appliances from assets/data/appliances.json
  /// Load appliances from assets/data/appliances.json
  Future<List<Appliance>> loadAppliances() async {
    if (_cachedAppliances != null) {
      return _cachedAppliances!;
    }

    try {
      print('loadAppliances: Starting...');
      final jsonString = await rootBundle.loadString(
        'assets/data/appliances.json',
      );
      print('loadAppliances: JSON loaded, length: ${jsonString.length}');

      final jsonData = jsonDecode(jsonString);
      print('loadAppliances: Decoded JSON type: ${jsonData.runtimeType}');
      print('loadAppliances: First 200 chars: ${jsonString.substring(0, 200)}');

      // Check if it's a list directly or wrapped in an object
      List<dynamic> appliancesArray;
      if (jsonData is List) {
        print('loadAppliances: JSON is a List directly');
        appliancesArray = jsonData as List<dynamic>;
      } else if (jsonData is Map) {
        print('loadAppliances: JSON is a Map, extracting appliances key');
        appliancesArray =
            (jsonData as Map<String, dynamic>)['appliances'] as List<dynamic>;
      } else {
        throw Exception('Unexpected JSON type: ${jsonData.runtimeType}');
      }

      print('loadAppliances: Found ${appliancesArray.length} appliances');

      final appliancesList = appliancesArray
          .map((item) => Appliance.fromJson(item as Map<String, dynamic>))
          .toList();

      print(
        'loadAppliances: Successfully created ${appliancesList.length} Appliance objects',
      );
      _cachedAppliances = appliancesList;
      return appliancesList;
    } catch (e) {
      print('ERROR in loadAppliances: $e');
      rethrow;
    }
  }

  /// Get appliances grouped by catalog_group
  /// Get appliances grouped by catalog_group
  Future<Map<String, List<Appliance>>> getAppliancesGroupedByCategory() async {
    try {
      print('getAppliancesGroupedByCategory: Starting...');
      final appliances = await loadAppliances();
      print(
        'getAppliancesGroupedByCategory: Loaded ${appliances.length} appliances',
      );

      final grouped = <String, List<Appliance>>{};

      for (final appliance in appliances) {
        final group = appliance.catalogGroup;
        print('Processing: ${appliance.name} -> Group: $group');
        if (!grouped.containsKey(group)) {
          grouped[group] = [];
        }
        grouped[group]!.add(appliance);
      }

      print(
        'getAppliancesGroupedByCategory: Done! Groups: ${grouped.keys.toList()}',
      );
      return grouped;
    } catch (e) {
      print('ERROR in getAppliancesGroupedByCategory: $e');
      rethrow;
    }
  }

  /// Get a single appliance by ID
  Future<Appliance?> getApplianceById(String id) async {
    final appliances = await loadAppliances();
    try {
      return appliances.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}
