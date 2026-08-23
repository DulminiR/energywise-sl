import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tariff_result.dart';

/// Calculates billing from total monthly kWh.
/// Loads tariff configuration from assets and applies Sri Lankan increasing-block tariff.
class TariffEngine {
  // Cached tariff config
  Map<String, dynamic>? _tariffConfig;

  /// Load tariff configuration from assets.
  /// Must be called once before any calculations.
  Future<void> loadTariffConfig() async {
    if (_tariffConfig != null) return; // Already loaded

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/tariff_config.json',
      );
      _tariffConfig = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load tariff config: $e');
    }
  }

  /// Main calculation method.
  /// Takes total kWh and returns complete tariff result.
  Future<TariffResult> calculateBill(double totalKwh) async {
    // Ensure config is loaded
    await loadTariffConfig();

    // Extract config values
    final fixedCharge = (_tariffConfig!['fixed_charge'] as num).toDouble();
    final ssclRatePerKwh = (_tariffConfig!['sscl']['rate_per_kwh'] as num)
        .toDouble();
    final consumptionBands = _tariffConfig!['consumption_bands'] as List;

    // Convert to list of band maps for easier processing
    final bands = consumptionBands
        .map(
          (b) => {
            'band_name': b['band_name'] as String,
            'lower_limit': (b['lower_limit'] as num).toDouble(),
            'upper_limit': (b['upper_limit'] as num).toDouble(),
            'rate_per_kwh': (b['rate_per_kwh'] as num).toDouble(),
          },
        )
        .toList();

    // Calculate energy charge across bands
    final energyCharge = _calculateEnergyCharge(totalKwh, bands);

    // Calculate SSCL (tax on energy charge)
    final sscl = energyCharge * ssclRatePerKwh;

    // Calculate subtotal and total
    final subtotal = energyCharge + fixedCharge;
    final totalBill = subtotal + sscl;

    // Determine current band and tariff status
    final bandInfo = _getCurrentBandInfo(totalKwh, bands);
    final currentBand = bandInfo['band_number'] as int;
    final currentBandName = bandInfo['band_name'] as String;
    final currentBandRate = bandInfo['rate_per_kwh'] as double;
    final remainingKwh = bandInfo['remaining_kwh'] as double;

    // Calculate savings to next lower band (tariff proximity insight)
    final savingsToNextBand = _calculateSavingsToNextBand(totalKwh, bands);

    return TariffResult(
      totalKwh: totalKwh,
      energyCharge: energyCharge,
      fixedCharge: fixedCharge,
      subtotal: subtotal,
      sscl: sscl,
      totalBill: totalBill,
      currentBand: currentBand,
      currentBandName: currentBandName,
      currentBandRatePerKwh: currentBandRate,
      remainingKwhInBand: remainingKwh,
      savingsToNextBand: savingsToNextBand,
    );
  }

  /// Calculate energy charge across tariff bands.
  /// Uses increasing-block tariff: different rates for different consumption ranges.
  ///
  /// Example: 75 kWh
  /// Band 1 (0-30): 30 × 3.86 = 115.80
  /// Band 2 (31-60): 30 × 4.48 = 134.40
  /// Band 3 (61-90): 15 × 5.23 = 78.45
  /// Total: 328.65
  double _calculateEnergyCharge(
    double totalKwh,
    List<Map<String, dynamic>> bands,
  ) {
    double energyCharge = 0.0;
    double remainingKwh = totalKwh;

    for (final band in bands) {
      if (remainingKwh <= 0) break;

      final lowerLimit = band['lower_limit'] as double;
      final upperLimit = band['upper_limit'] as double;
      final ratePerKwh = band['rate_per_kwh'] as double;

      // How many kWh fall into this band?
      final bandWidth = upperLimit - lowerLimit;
      final kwhInThisBand = remainingKwh > bandWidth ? bandWidth : remainingKwh;

      // Add to energy charge
      energyCharge += kwhInThisBand * ratePerKwh;

      // Reduce remaining
      remainingKwh -= kwhInThisBand;
    }

    return energyCharge;
  }

  /// Determine which band the user is currently in.
  /// Returns band number (1-5), name, rate, and remaining kWh in that band.
  Map<String, dynamic> _getCurrentBandInfo(
    double totalKwh,
    List<Map<String, dynamic>> bands,
  ) {
    double runningTotal = 0.0;

    for (int i = 0; i < bands.length; i++) {
      final band = bands[i];
      final lowerLimit = band['lower_limit'] as double;
      final upperLimit = band['upper_limit'] as double;
      final ratePerKwh = band['rate_per_kwh'] as double;
      final bandName = band['band_name'] as String;

      // Is the user in this band?
      if (totalKwh >= lowerLimit && totalKwh <= upperLimit) {
        final remainingInBand = upperLimit - totalKwh;
        return {
          'band_number': i + 1,
          'band_name': bandName,
          'rate_per_kwh': ratePerKwh,
          'remaining_kwh': remainingInBand,
        };
      }

      // If consumption exceeds this band, continue to next
      if (totalKwh > upperLimit) {
        runningTotal = upperLimit;
      }
    }

    // If we get here, consumption is in the last (highest) band
    final lastBand = bands.last;
    return {
      'band_number': bands.length,
      'band_name': lastBand['band_name'] as String,
      'rate_per_kwh': lastBand['rate_per_kwh'] as double,
      'remaining_kwh': 0.0, // No upper limit on the last band
    };
  }

  /// Calculate potential savings by reducing consumption to the next lower band.
  /// This is the "tariff proximity" insight.
  ///
  /// Example: If you're at 75 kWh (Band 3), calculate savings if you drop to 60 kWh (Band 2).
  /// This motivates users with actionable targets.
  double? _calculateSavingsToNextBand(
    double totalKwh,
    List<Map<String, dynamic>> bands,
  ) {
    // Find the current band
    int currentBandIndex = -1;
    for (int i = 0; i < bands.length; i++) {
      final band = bands[i];
      if (totalKwh >= band['lower_limit'] && totalKwh <= band['upper_limit']) {
        currentBandIndex = i;
        break;
      }
    }

    // If in the last band or not found, no next band to drop to
    if (currentBandIndex <= 0) return null;

    // Get the upper limit of the previous (lower-cost) band
    final previousBandUpperLimit =
        (bands[currentBandIndex - 1]['upper_limit'] as num).toDouble();

    // How much kWh would we need to save?
    final kwhToSave = totalKwh - previousBandUpperLimit;

    // Rough calculation: difference in rates × kWh to save
    // This is simplified; a more accurate calculation would recalculate the full bill.
    final currentRate = (bands[currentBandIndex]['rate_per_kwh'] as num)
        .toDouble();
    final previousRate = (bands[currentBandIndex - 1]['rate_per_kwh'] as num)
        .toDouble();
    final rateDifference = currentRate - previousRate;

    // Savings = kWh saved × rate difference
    final estimatedSavings = kwhToSave * rateDifference;

    return estimatedSavings > 0 ? estimatedSavings : null;
  }

  /// Helper: Get tariff config (for testing/debugging).
  Map<String, dynamic>? getTariffConfig() => _tariffConfig;
}
