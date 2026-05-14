import 'package:firesight/models/form_autofill_result.dart';
import 'package:firesight/models/form_field_suggestion.dart';
import 'package:firesight/models/inspection_form.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/forms/form_autofill_engine.dart';

/// Lightweight MVP engine. It extracts obvious fire-inspection facts locally.
///
/// Confidence values returned by this engine are fixed heuristics. AI-backed
/// engines should return model-derived or evidence-derived confidence scores.
class RuleBasedFormAutofillEngine implements FormAutofillEngine {
  const RuleBasedFormAutofillEngine({DateTime Function()? clock})
      : _clock = clock;

  final DateTime Function()? _clock;

  @override
  Future<FormAutofillResult> autofill({
    required InspectionForm currentForm,
    required List<Observation> observations,
  }) async {
    final suggestions = <FormFieldSuggestion>[];
    final now = _clock?.call() ?? DateTime.now();

    for (final observation in observations) {
      final text = observation.text?.trim();
      if (text == null || text.isEmpty) continue;

      suggestions.addAll(_extractSuggestions(text, now));
    }

    final bestSuggestions = _dedupeByField(suggestions);
    var form = currentForm;
    for (final suggestion in bestSuggestions) {
      form = form.applyFieldValue(suggestion.fieldId, suggestion.value);
    }

    return FormAutofillResult(
      form: form,
      suggestions: bestSuggestions,
    );
  }

  List<FormFieldSuggestion> _extractSuggestions(String text, DateTime now) {
    return [
      if (_extractLocation(text, _alarmPanelPatterns) case final value?)
        _suggestion(
          InspectionFormFieldIds.alarmPanelLocation,
          value,
          0.88,
          text,
          now,
        ),
      if (_extractLocation(text, _sprinklerRiserPatterns) case final value?)
        _suggestion(
          InspectionFormFieldIds.sprinklerRiserLocation,
          value,
          0.88,
          text,
          now,
        ),
      if (_containsAny(text, _fireProtectionTerms))
        _suggestion(
          InspectionFormFieldIds.fireProtectionSystems,
          _sentenceValue(text),
          0.72,
          text,
          now,
        ),
      if (_containsAny(text, _utilityTerms))
        _suggestion(
          InspectionFormFieldIds.utilityShutoffs,
          _sentenceValue(text),
          0.74,
          text,
          now,
        ),
      if (_containsAny(text, _hazardTerms))
        _suggestion(
          InspectionFormFieldIds.hazards,
          _sentenceValue(text),
          0.72,
          text,
          now,
        ),
      if (_containsAny(text, _accessTerms))
        _suggestion(
          InspectionFormFieldIds.accessNotes,
          _sentenceValue(text),
          0.72,
          text,
          now,
        ),
      if (_extractOccupancy(text) case final value?)
        _suggestion(
          InspectionFormFieldIds.occupancyType,
          value,
          0.7,
          text,
          now,
        ),
    ];
  }

  List<FormFieldSuggestion> _dedupeByField(
    List<FormFieldSuggestion> suggestions,
  ) {
    final byField = <String, FormFieldSuggestion>{};
    for (final suggestion in suggestions) {
      final existing = byField[suggestion.fieldId];
      if (existing == null || suggestion.confidence > existing.confidence) {
        byField[suggestion.fieldId] = suggestion;
      }
    }
    return byField.values.toList();
  }

  FormFieldSuggestion _suggestion(
    String fieldId,
    String value,
    double confidence,
    String evidence,
    DateTime now,
  ) {
    return FormFieldSuggestion(
      fieldId: fieldId,
      value: value,
      confidence: confidence,
      evidence: evidence,
      source: AutofillSource.ruleBased,
      createdAt: now,
    );
  }

  String? _extractLocation(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final value = match.group(1)?.trim();
      if (value == null || value.isEmpty) continue;
      return _cleanValue(value);
    }
    return null;
  }

  String? _extractOccupancy(String text) {
    final lower = text.toLowerCase();
    const occupancies = [
      'apartment',
      'commercial',
      'hospital',
      'hotel',
      'office',
      'restaurant',
      'school',
      'warehouse',
    ];

    for (final occupancy in occupancies) {
      if (lower.contains(occupancy)) return occupancy;
    }
    return null;
  }

  bool _containsAny(String text, List<String> terms) {
    final lower = text.toLowerCase();
    return terms.any(lower.contains);
  }

  String _sentenceValue(String text) => _cleanValue(text);

  String _cleanValue(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirst(RegExp(r'[.!,;:]+$'), '')
        .trim();
  }

  static final _alarmPanelPatterns = [
    RegExp(
      r'alarm panel (?:is |is located |located |located in |located at )?(?:in |at |near |by )?(.+)',
      caseSensitive: false,
    ),
    RegExp(
      r'fire alarm panel (?:is |is located |located |located in |located at )?(?:in |at |near |by )?(.+)',
      caseSensitive: false,
    ),
  ];

  static final _sprinklerRiserPatterns = [
    RegExp(
      r'sprinkler riser (?:is |is located |located |located in |located at )?(?:in |at |near |by )?(.+)',
      caseSensitive: false,
    ),
    RegExp(
      r'riser (?:is |is located |located |located in |located at )?(?:in |at |near |by )?(.+)',
      caseSensitive: false,
    ),
  ];

  static const _fireProtectionTerms = [
    'sprinkler',
    'standpipe',
    'fire pump',
    'alarm system',
    'suppression',
  ];

  static const _utilityTerms = [
    'gas shutoff',
    'electric shutoff',
    'electrical shutoff',
    'water shutoff',
    'utility shutoff',
    'utilities',
  ];

  static const _hazardTerms = [
    'hazard',
    'flammable',
    'chemical',
    'oxygen',
    'fuel',
    'paint storage',
    'hazmat',
  ];

  static const _accessTerms = [
    'knox box',
    'access',
    'gate code',
    'main entrance',
    'fire lane',
  ];
}
