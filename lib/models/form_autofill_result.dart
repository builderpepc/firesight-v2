import 'package:equatable/equatable.dart';
import 'package:firesight/models/form_field_suggestion.dart';
import 'package:firesight/models/inspection_form.dart';

/// Result returned by any form autofill engine.
class FormAutofillResult extends Equatable {
  const FormAutofillResult({
    required this.form,
    required this.suggestions,
  });

  final InspectionForm form;
  final List<FormFieldSuggestion> suggestions;

  @override
  List<Object?> get props => [form, suggestions];
}
