// basic_test.dart
// AI-Powered Immunization & Vaccination System — MRA Project
// Run with: flutter test test/basic_test.dart

import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────
//  MODELS (inline — no Firebase needed in tests)
// ─────────────────────────────────────────────

class Child {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String guardianPhone;
  final String area;

  Child({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.guardianPhone,
    required this.area,
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - dateOfBirth.year) * 12 +
        (now.month - dateOfBirth.month);
  }
}

class VaccinationRecord {
  final String childId;
  final String vaccineType;
  final String dose;
  final String status; // completed | refused | absent
  final DateTime date;

  VaccinationRecord({
    required this.childId,
    required this.vaccineType,
    required this.dose,
    required this.status,
    required this.date,
  });
}

// ─────────────────────────────────────────────
//  VACCINE SCHEDULE LOGIC
// ─────────────────────────────────────────────

class VaccineSchedule {
  static const Map<String, int> dueAgeMonths = {
    'BCG': 0,
    'OPV': 0,
    'Pentavalent Dose 1': 6,
    'Pentavalent Dose 2': 10,
    'Pentavalent Dose 3': 14,
    'PCV Dose 1': 6,
    'PCV Dose 2': 10,
    'PCV Dose 3': 14,
    'IPV': 14,
    'Measles/MR': 9,
  };

  /// Returns list of vaccine+dose combos due for a child at given age
  static List<String> getDueVaccines(int ageInMonths) {
    return dueAgeMonths.entries
        .where((e) => e.value == ageInMonths)
        .map((e) => e.key)
        .toList();
  }

  /// Returns true if child is overdue for any vaccine
  static bool isOverdue(int ageInMonths, List<String> completedVaccines) {
    final allDue = dueAgeMonths.entries
        .where((e) => e.value <= ageInMonths)
        .map((e) => e.key)
        .toList();
    return allDue.any((v) => !completedVaccines.contains(v));
  }
}

// ─────────────────────────────────────────────
//  AI RISK SCORER (pure logic, no API call)
// ─────────────────────────────────────────────

class AIRiskScorer {
  /// Returns a dropout risk score 0–100
  /// Higher = more likely to miss next dose
  static int calculateRisk({
    required int missedDoses,
    required int ageInMonths,
    required bool remoteArea,
    required bool previousRefusal,
  }) {
    int score = 0;
    score += missedDoses * 20;
    if (ageInMonths > 6) score += 10; // older children often missed
    if (remoteArea) score += 25;
    if (previousRefusal) score += 30;
    return score.clamp(0, 100);
  }

  static String riskLabel(int score) {
    if (score >= 70) return 'High';
    if (score >= 40) return 'Medium';
    return 'Low';
  }
}

// ─────────────────────────────────────────────
//  COVERAGE CALCULATOR
// ─────────────────────────────────────────────

class CoverageCalculator {
  static double calculateCoverage({
    required int totalChildren,
    required int vaccinatedChildren,
  }) {
    if (totalChildren == 0) return 0.0;
    return (vaccinatedChildren / totalChildren) * 100;
  }

  static Map<String, int> summariseByStatus(
      List<VaccinationRecord> records) {
    final summary = {'completed': 0, 'refused': 0, 'absent': 0};
    for (final r in records) {
      final key = r.status.toLowerCase();
      if (summary.containsKey(key)) summary[key] = summary[key]! + 1;
    }
    return summary;
  }
}

// ─────────────────────────────────────────────
//  VALIDATOR
// ─────────────────────────────────────────────

class Validator {
  static bool isValidPhone(String phone) =>
      RegExp(r'^03\d{9}$').hasMatch(phone);

  static bool isValidVaccinatorId(String id) =>
      id.trim().isNotEmpty && id.length >= 4;

  static bool isValidChildName(String name) =>
      name.trim().isNotEmpty && name.length >= 2;
}

// ─────────────────────────────────────────────
//  SESSION DETAILS MODEL
// ─────────────────────────────────────────────

class VaccinatorSession {
  final String vaccinatorId;
  final String vaccineType;
  final String dose;
  final DateTime scheduledDate;

  VaccinatorSession({
    required this.vaccinatorId,
    required this.vaccineType,
    required this.dose,
    required this.scheduledDate,
  });

  bool get isValid =>
      vaccinatorId.isNotEmpty && vaccineType.isNotEmpty && dose.isNotEmpty;
}

// ═════════════════════════════════════════════
//  T E S T S
// ═════════════════════════════════════════════

void main() {
  // ── 1. Child Model ──────────────────────────
  group('Child model', () {
    test('age in months is calculated correctly', () {
      final dob = DateTime.now().subtract(const Duration(days: 182)); // ~6 months
      final child = Child(
        id: 'c001',
        name: 'Ali Hassan',
        dateOfBirth: dob,
        guardianPhone: '03001234567',
        area: 'Rawalpindi',
      );
      expect(child.ageInMonths, greaterThanOrEqualTo(5));
      expect(child.ageInMonths, lessThanOrEqualTo(7));
    });

    test('child has correct fields', () {
      final child = Child(
        id: 'c002',
        name: 'Fatima Bibi',
        dateOfBirth: DateTime(2024, 1, 1),
        guardianPhone: '03331234567',
        area: 'Lahore',
      );
      expect(child.name, 'Fatima Bibi');
      expect(child.area, 'Lahore');
    });
  });

  // ── 2. Vaccine Schedule ─────────────────────
  group('VaccineSchedule', () {
    test('BCG and OPV are due at birth (0 months)', () {
      final due = VaccineSchedule.getDueVaccines(0);
      expect(due, containsAll(['BCG', 'OPV']));
    });

    test('Pentavalent Dose 1 is due at 6 weeks (~6)', () {
      final due = VaccineSchedule.getDueVaccines(6);
      expect(due, contains('Pentavalent Dose 1'));
    });

    test('Measles/MR is due at 9 months', () {
      final due = VaccineSchedule.getDueVaccines(9);
      expect(due, contains('Measles/MR'));
    });

    test('child is overdue if BCG not given at 3 months', () {
      final overdue = VaccineSchedule.isOverdue(3, []);
      expect(overdue, isTrue);
    });

    test('child is NOT overdue if all due vaccines completed', () {
      final overdue = VaccineSchedule.isOverdue(0, ['BCG', 'OPV']);
      expect(overdue, isFalse);
    });
  });

  // ── 3. AI Risk Scorer ───────────────────────
  group('AIRiskScorer', () {
    test('no risk factors gives low score', () {
      final score = AIRiskScorer.calculateRisk(
        missedDoses: 0,
        ageInMonths: 2,
        remoteArea: false,
        previousRefusal: false,
      );
      expect(score, lessThan(40));
      expect(AIRiskScorer.riskLabel(score), 'Low');
    });

    test('multiple risk factors gives high score', () {
      final score = AIRiskScorer.calculateRisk(
        missedDoses: 2,
        ageInMonths: 8,
        remoteArea: true,
        previousRefusal: true,
      );
      expect(score, greaterThanOrEqualTo(70));
      expect(AIRiskScorer.riskLabel(score), 'High');
    });

    test('remote area alone raises score to medium+', () {
      final score = AIRiskScorer.calculateRisk(
        missedDoses: 0,
        ageInMonths: 2,
        remoteArea: true,
        previousRefusal: false,
      );
      expect(score, greaterThanOrEqualTo(25));
    });

    test('score is clamped between 0 and 100', () {
      final score = AIRiskScorer.calculateRisk(
        missedDoses: 10,
        ageInMonths: 24,
        remoteArea: true,
        previousRefusal: true,
      );
      expect(score, lessThanOrEqualTo(100));
      expect(score, greaterThanOrEqualTo(0));
    });
  });

  // ── 4. Coverage Calculator ──────────────────
  group('CoverageCalculator', () {
    test('50% coverage with half vaccinated', () {
      final pct = CoverageCalculator.calculateCoverage(
        totalChildren: 100,
        vaccinatedChildren: 50,
      );
      expect(pct, 50.0);
    });

    test('100% coverage when all vaccinated', () {
      final pct = CoverageCalculator.calculateCoverage(
        totalChildren: 80,
        vaccinatedChildren: 80,
      );
      expect(pct, 100.0);
    });

    test('returns 0 when total children is 0', () {
      final pct = CoverageCalculator.calculateCoverage(
        totalChildren: 0,
        vaccinatedChildren: 0,
      );
      expect(pct, 0.0);
    });

    test('summariseByStatus counts correctly', () {
      final records = [
        VaccinationRecord(childId: 'c1', vaccineType: 'BCG', dose: 'Dose 1', status: 'completed', date: DateTime.now()),
        VaccinationRecord(childId: 'c2', vaccineType: 'OPV', dose: 'Dose 1', status: 'refused',  date: DateTime.now()),
        VaccinationRecord(childId: 'c3', vaccineType: 'PCV', dose: 'Dose 1', status: 'absent',   date: DateTime.now()),
        VaccinationRecord(childId: 'c4', vaccineType: 'BCG', dose: 'Dose 1', status: 'completed', date: DateTime.now()),
      ];
      final summary = CoverageCalculator.summariseByStatus(records);
      expect(summary['completed'], 2);
      expect(summary['refused'],   1);
      expect(summary['absent'],    1);
    });
  });

  // ── 5. Validator ────────────────────────────
  group('Validator', () {
    test('valid Pakistani phone number passes', () {
      expect(Validator.isValidPhone('03001234567'), isTrue);
      expect(Validator.isValidPhone('03331234567'), isTrue);
    });

    test('invalid phone numbers fail', () {
      expect(Validator.isValidPhone('1234567890'), isFalse);
      expect(Validator.isValidPhone('0300123'),    isFalse);
      expect(Validator.isValidPhone(''),           isFalse);
    });

    test('vaccinator ID must be 4+ chars', () {
      expect(Validator.isValidVaccinatorId('V001'),   isTrue);
      expect(Validator.isValidVaccinatorId('AB'),     isFalse);
      expect(Validator.isValidVaccinatorId(''),       isFalse);
    });

    test('child name must be 2+ characters', () {
      expect(Validator.isValidChildName('Ali'),  isTrue);
      expect(Validator.isValidChildName('A'),    isFalse);
      expect(Validator.isValidChildName('   '),  isFalse);
    });
  });

  // ── 6. VaccinatorSession ────────────────────
  group('VaccinatorSession', () {
    test('valid session passes isValid check', () {
      final session = VaccinatorSession(
        vaccinatorId: 'V001',
        vaccineType:  'BCG',
        dose:         'Dose 1',
        scheduledDate: DateTime.now(),
      );
      expect(session.isValid, isTrue);
    });

    test('session with empty vaccinator ID is invalid', () {
      final session = VaccinatorSession(
        vaccinatorId:  '',
        vaccineType:   'BCG',
        dose:          'Dose 1',
        scheduledDate: DateTime.now(),
      );
      expect(session.isValid, isFalse);
    });

    test('session with empty vaccine type is invalid', () {
      final session = VaccinatorSession(
        vaccinatorId:  'V001',
        vaccineType:   '',
        dose:          'Dose 1',
        scheduledDate: DateTime.now(),
      );
      expect(session.isValid, isFalse);
    });
  });
}