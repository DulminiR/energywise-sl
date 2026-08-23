/// Represents the complete tariff calculation result.
/// Includes all bill components and tariff status.
class TariffResult {
  final double totalKwh; // Total monthly consumption
  final double energyCharge; // Cost based on consumption bands
  final double fixedCharge; // Fixed monthly charge (300 LKR)
  final double subtotal; // energyCharge + fixedCharge
  final double sscl; // Sustainable System and Cost of Living Levy
  final double totalBill; // subtotal + sscl
  final int currentBand; // Which tariff band (1-5) the user is in
  final String currentBandName; // e.g., "Band 2 (Medium)"
  final double currentBandRatePerKwh; // Rate for current band
  final double remainingKwhInBand; // How much kWh until next band
  final double?
  savingsToNextBand; // Estimated LKR saved if you reach next lower band

  TariffResult({
    required this.totalKwh,
    required this.energyCharge,
    required this.fixedCharge,
    required this.subtotal,
    required this.sscl,
    required this.totalBill,
    required this.currentBand,
    required this.currentBandName,
    required this.currentBandRatePerKwh,
    required this.remainingKwhInBand,
    this.savingsToNextBand,
  });

  /// Factory constructor to create from JSON (for debugging/testing).
  factory TariffResult.fromJson(Map<String, dynamic> json) {
    return TariffResult(
      totalKwh: (json['total_kwh'] as num).toDouble(),
      energyCharge: (json['energy_charge'] as num).toDouble(),
      fixedCharge: (json['fixed_charge'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      sscl: (json['sscl'] as num).toDouble(),
      totalBill: (json['total_bill'] as num).toDouble(),
      currentBand: json['current_band'] as int,
      currentBandName: json['current_band_name'] as String,
      currentBandRatePerKwh: (json['current_band_rate_per_kwh'] as num)
          .toDouble(),
      remainingKwhInBand: (json['remaining_kwh_in_band'] as num).toDouble(),
      savingsToNextBand: json['savings_to_next_band'] != null
          ? (json['savings_to_next_band'] as num).toDouble()
          : null,
    );
  }

  /// Convert to JSON for persistence/debugging.
  Map<String, dynamic> toJson() {
    return {
      'total_kwh': totalKwh,
      'energy_charge': energyCharge,
      'fixed_charge': fixedCharge,
      'subtotal': subtotal,
      'sscl': sscl,
      'total_bill': totalBill,
      'current_band': currentBand,
      'current_band_name': currentBandName,
      'current_band_rate_per_kwh': currentBandRatePerKwh,
      'remaining_kwh_in_band': remainingKwhInBand,
      'savings_to_next_band': savingsToNextBand,
    };
  }

  /// Helper method to format bill for display.
  String get formattedBill => 'LKR ${totalBill.toStringAsFixed(2)}';

  /// Helper method to get band-level info.
  String get bandInfo =>
      '$currentBandName (${currentBandRatePerKwh.toStringAsFixed(2)} LKR/kWh)';

  @override
  String toString() =>
      'TariffResult(kWh: $totalKwh, bill: LKR ${totalBill.toStringAsFixed(2)}, band: $currentBand)';
}
