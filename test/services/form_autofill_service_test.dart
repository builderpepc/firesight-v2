import 'package:firesight/models/form_autofill_result.dart';
import 'package:firesight/models/form_field_suggestion.dart';
import 'package:firesight/models/inspection_form.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/forms/form_autofill_engine.dart';
import 'package:firesight/services/forms/form_autofill_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormAutofillService', () {
    test('does not overwrite existing field values by default', () async {
      final service = FormAutofillService(
        _FakeAutofillEngine(
          [
            FormFieldSuggestion(
              fieldId: InspectionFormFieldIds.alarmPanelLocation,
              value: 'Front lobby',
              confidence: 0.9,
              source: AutofillSource.ruleBased,
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
        ),
      );

      final result = await service.autofill(
        currentForm: const InspectionForm(
          alarmPanelLocation: 'User-entered lobby note',
        ),
        observations: const [],
      );

      expect(result.form.alarmPanelLocation, 'User-entered lobby note');
      expect(result.suggestions, isEmpty);
    });

    test('can overwrite existing values when requested', () async {
      final service = FormAutofillService(
        _FakeAutofillEngine(
          [
            FormFieldSuggestion(
              fieldId: InspectionFormFieldIds.alarmPanelLocation,
              value: 'Front lobby',
              confidence: 0.9,
              source: AutofillSource.ruleBased,
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
        ),
      );

      final result = await service.autofill(
        currentForm: const InspectionForm(
          alarmPanelLocation: 'User-entered lobby note',
        ),
        observations: const [],
        overwriteExisting: true,
      );

      expect(result.form.alarmPanelLocation, 'Front lobby');
      expect(result.suggestions, hasLength(1));
    });
  });
}

class _FakeAutofillEngine implements FormAutofillEngine {
  const _FakeAutofillEngine(this._suggestions);

  final List<FormFieldSuggestion> _suggestions;

  @override
  Future<FormAutofillResult> autofill({
    required InspectionForm currentForm,
    required List<Observation> observations,
  }) async {
    var form = currentForm;
    for (final suggestion in _suggestions) {
      form = form.applyFieldValue(suggestion.fieldId, suggestion.value);
    }
    return FormAutofillResult(form: form, suggestions: _suggestions);
  }
}
