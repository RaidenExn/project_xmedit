import 'package:flutter_test/flutter_test.dart';
import 'package:project_xmedit/models/claim_models.dart';

import 'package:project_xmedit/services/xml_validator.dart';

void main() {
  group('XmlValidator', () {
    late ClaimData validClaim;

    setUp(() {
      validClaim = ClaimData()
        ..claimId = '12345'
        ..patientId = 'PAT123'
        ..memberID = 'MEM123'
        ..payerID = 'PAY123'
        ..senderID = 'SENDER123'
        ..receiverID = 'RECEIVER123'
        ..start = '01/01/2023'
        ..end = '01/01/2023'
        ..gross = '100.00'
        ..patientShare = '20.00'
        ..net = '80.00';

      // Add a valid activity
      validClaim.activities.add(ActivityData()
        ..code = '99213'
        ..net = '80.00' // matches claim net
        ..quantity = '1');

      // Add a valid diagnosis
      validClaim.diagnoses.add(DiagnosisData()
        ..code = 'R51.9'
        ..type = 'Principal');
    });

    test('validates a correct claim without errors', () {
      final result = XmlValidator.validateClaim(validClaim);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('reports error for missing Claim ID', () {
      validClaim.claimId = '';
      final result = XmlValidator.validateClaim(validClaim);
      expect(result.isValid, isFalse);
      expect(result.hasErrorForField('claimId'), isTrue);
    });

    test('reports error for invalid dates', () {
      validClaim.start = 'invalid';
      final result = XmlValidator.validateClaim(validClaim);
      expect(result.isValid, isFalse);
      expect(result.hasErrorForField('encounterStart'), isTrue);
    });

    test('reports error for mismatched totals', () {
      validClaim.gross = '200.00'; // Mismatch with activity sum (100)
      final result = XmlValidator.validateClaim(validClaim);
      expect(result.isValid, isFalse);
      expect(result.hasErrorForField('totals'),
          isTrue); // Error is on 'totals' field
    });

    test('reports warning for missing principal diagnosis', () {
      validClaim.diagnoses.clear();
      final result = XmlValidator.validateClaim(validClaim);
      // It's a warning, not an error, so isValid might be true if there are no other errors
      // But we check specifically for the warning
      expect(result.warnings.any((e) => e.field == 'diagnoses'), isTrue);
    });

    test('canSave returns false for critical errors', () {
      validClaim.claimId = '';
      expect(XmlValidator.canSave(validClaim), isFalse);
    });
  });
}
