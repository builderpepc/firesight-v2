import 'package:firesight/models/inspection_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InspectionForm', () {
    test('serializes to json with stable field names', () {
      const form = InspectionForm(
        buildingName: 'Lincoln High School',
        alarmPanelLocation: 'Front lobby',
      );

      final json = form.toJson();

      expect(json['building_name'], 'Lincoln High School');
      expect(json['alarm_panel_location'], 'Front lobby');
    });

    test('applies field values by stable field id', () {
      final form = const InspectionForm().applyFieldValue(
        InspectionFormFieldIds.sprinklerRiserLocation,
        'Mechanical room',
      );

      expect(form.sprinklerRiserLocation, 'Mechanical room');
      expect(
        form.valueFor(InspectionFormFieldIds.sprinklerRiserLocation),
        'Mechanical room',
      );
    });
  });
}
