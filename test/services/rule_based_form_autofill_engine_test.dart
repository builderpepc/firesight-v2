import 'package:firesight/models/form_field_suggestion.dart';
import 'package:firesight/models/inspection_form.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/forms/rule_based_form_autofill_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RuleBasedFormAutofillEngine', () {
    test('extracts locations for common fire inspection fields', () async {
      final engine = RuleBasedFormAutofillEngine(
        clock: () => DateTime(2026, 1, 1),
      );

      final result = await engine.autofill(
        currentForm: const InspectionForm(),
        observations: [
          Observation(
            id: '1',
            timestamp: DateTime(2026, 1, 1),
            text: 'The alarm panel is in the front lobby.',
          ),
          Observation(
            id: '2',
            timestamp: DateTime(2026, 1, 1),
            text: 'The sprinkler riser is in the mechanical room.',
          ),
        ],
      );

      expect(result.form.alarmPanelLocation, 'the front lobby');
      expect(result.form.sprinklerRiserLocation, 'the mechanical room');
      expect(
        result.suggestions.map((suggestion) => suggestion.source).toSet(),
        {AutofillSource.ruleBased},
      );
    });

    test('captures evidence and confidence for suggestions', () async {
      final engine = RuleBasedFormAutofillEngine(
        clock: () => DateTime(2026, 1, 1),
      );

      final result = await engine.autofill(
        currentForm: const InspectionForm(),
        observations: [
          Observation(
            id: '1',
            timestamp: DateTime(2026, 1, 1),
            text: 'Gas shutoff is on the north side of the building.',
          ),
        ],
      );

      final suggestion = result.suggestions.single;
      expect(suggestion.fieldId, InspectionFormFieldIds.utilityShutoffs);
      expect(suggestion.confidence, greaterThan(0));
      expect(suggestion.evidence, contains('Gas shutoff'));
    });
  });
}
