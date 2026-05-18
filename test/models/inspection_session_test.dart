import 'package:firesight/models/form_field_suggestion.dart';
import 'package:firesight/models/inspection_form.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InspectionSession', () {
    test('fromJson creates session', () {
      final session = InspectionSession.fromJson(const {
        'id': 'session-1',
        'name': 'Inspection',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        'form': {
          'building_name': 'Lincoln High School',
          'alarm_panel_location': 'Front lobby',
        },
        'form_suggestions': [
          {
            'field_id': 'alarm_panel_location',
            'value': 'Front lobby',
            'confidence': 0.9,
            'evidence': 'Alarm panel is in the front lobby.',
            'source': 'rule_based',
            'created_at': '2026-01-01T00:00:00.000',
          }
        ],
      });

      expect(session.form.buildingName, 'Lincoln High School');
      expect(session.formSuggestions.single.source, AutofillSource.ruleBased);
    });

    test('copyWith updates fields', () {
      final session = InspectionSession(
        id: 'session-1',
        name: 'Inspection',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = session.copyWith(
        form: const InspectionForm(buildingName: 'Lincoln High School'),
      );

      expect(session.form.buildingName, isNull);
      expect(updated.form.buildingName, 'Lincoln High School');
    });

    test('equality works', () {
      final first = InspectionSession(
        id: 'session-1',
        name: 'Inspection',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        form: const InspectionForm(buildingName: 'Lincoln High School'),
      );
      final second = InspectionSession(
        id: 'session-1',
        name: 'Inspection',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        form: const InspectionForm(buildingName: 'Lincoln High School'),
      );

      expect(first, second);
    });
  });
}
