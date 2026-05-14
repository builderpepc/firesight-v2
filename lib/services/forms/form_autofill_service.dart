import 'package:firesight/models/form_autofill_result.dart';
import 'package:firesight/models/form_field_suggestion.dart';
import 'package:firesight/models/inspection_form.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/forms/form_autofill_engine.dart';

/// Coordinates form autofill and merge policy for the active engine.
class FormAutofillService {
  const FormAutofillService(this._engine);

  final FormAutofillEngine _engine;

  Future<FormAutofillResult> autofill({
    required InspectionForm currentForm,
    required List<Observation> observations,
    bool overwriteExisting = false,
  }) async {
    final result = await _engine.autofill(
      currentForm: currentForm,
      observations: observations,
    );

    var mergedForm = currentForm;
    final appliedSuggestions = <FormFieldSuggestion>[];

    for (final suggestion in result.suggestions) {
      final existingValue = mergedForm.valueFor(suggestion.fieldId);
      final hasExistingValue =
          existingValue != null && existingValue.trim().isNotEmpty;

      if (hasExistingValue && !overwriteExisting) continue;

      mergedForm = mergedForm.applyFieldValue(
        suggestion.fieldId,
        suggestion.value,
      );
      appliedSuggestions.add(suggestion);
    }

    return FormAutofillResult(
      form: mergedForm,
      suggestions: appliedSuggestions,
    );
  }
}
