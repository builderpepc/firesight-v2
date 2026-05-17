import 'package:firesight/models/inspection_form.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/pdf/pdf_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfExportService', () {
    test('generateAndShare creates PDF with session data', () async {
      final service = PdfExportService();
      final session = InspectionSession(
        id: 'session-1',
        name: 'Test Inspection',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        form: const InspectionForm(
          buildingName: 'Lincoln High School',
          alarmPanelLocation: 'Front lobby',
        ),
        observations: [
          Observation(
            id: 'obs-1',
            timestamp: DateTime(2026, 1, 1),
            text: 'The alarm panel is in the front lobby.',
          ),
        ],
      );

      final bytes = await service.generateInspectionFormPdf(session);

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });
}
