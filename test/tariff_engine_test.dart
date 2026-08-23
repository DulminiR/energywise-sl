import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:energywise_sl/services/tariff_engine.dart';

void main() {
  // Initialize Flutter's binding before running tests
  // This allows rootBundle.loadString() to work in tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TariffEngine Tests', () {
    late TariffEngine tariffEngine;

    setUp(() {
      tariffEngine = TariffEngine();
    });

    test('Load tariff config successfully', () async {
      await tariffEngine.loadTariffConfig();
      final config = tariffEngine.getTariffConfig();
      expect(config, isNotNull);
      expect(config!['effective_date'], '2026-05-01');
    });

    test('Calculate bill for 30 kWh (Band 1)', () async {
      final result = await tariffEngine.calculateBill(30.0);

      // Band 1: 30 × 3.86 = 115.80
      expect(result.totalKwh, 30.0);
      expect(result.energyCharge, closeTo(115.80, 0.01));
      expect(result.fixedCharge, 300.0);
      expect(result.currentBand, 1);
      expect(result.currentBandName, contains('Band 1'));
    });

    test('Calculate bill for 75 kWh (spans Bands 1-3)', () async {
      final result = await tariffEngine.calculateBill(75.0);

      // Band 1: 30 × 3.86 = 115.80
      // Band 2: 30 × 4.48 = 134.40
      // Band 3: 15 × 5.23 = 78.45
      // Energy charge = 328.65
      expect(result.totalKwh, 75.0);
      expect(
        result.energyCharge,
        closeTo(328.65, 1.0),
      ); // Allow up to 1.0 LKR difference
      expect(result.currentBand, 3);
    });

    test('Calculate bill for 150 kWh (high consumption)', () async {
      final result = await tariffEngine.calculateBill(150.0);

      // Spans all bands including the highest
      expect(result.totalKwh, 150.0);
      expect(result.currentBand, 5);
      expect(result.totalBill, greaterThan(0));
    });

    test('Tariff proximity savings exists for Band 2+', () async {
      final result = await tariffEngine.calculateBill(75.0);

      // At 75 kWh (Band 3), dropping to 60 kWh should have savings
      expect(result.savingsToNextBand, isNotNull);
      expect(result.savingsToNextBand, greaterThan(0));
    });

    test('No tariff proximity savings for Band 1', () async {
      final result = await tariffEngine.calculateBill(20.0);

      // At 20 kWh (Band 1), no lower band to drop to
      expect(result.savingsToNextBand, isNull);
    });

    test('SSCL is applied correctly', () async {
      final result = await tariffEngine.calculateBill(50.0);

      // SSCL should be ~4.75% of energy charge
      final expectedSscl = result.energyCharge * 0.0475;
      expect(result.sscl, closeTo(expectedSscl, 0.01));
    });

    test('Total bill = subtotal + SSCL', () async {
      final result = await tariffEngine.calculateBill(100.0);

      final calculatedTotal = result.subtotal + result.sscl;
      expect(result.totalBill, closeTo(calculatedTotal, 0.01));
    });
  });
}
