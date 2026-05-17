import 'package:firesight/models/form_autofill_result.dart';
import 'package:firesight/models/inspection_form.dart';
import 'package:firesight/models/observation.dart';

/// Pluggable engine for converting observations into structured form fields.
///
/// This is the swap point for autofill implementations. The MVP uses local
/// rules, but future Cactus/Gemini engines should implement this same contract.
abstract class FormAutofillEngine {
  Future<FormAutofillResult> autofill({
    required InspectionForm currentForm,
    required List<Observation> observations,
  });
}
