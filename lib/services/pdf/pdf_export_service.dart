import 'dart:typed_data';

import 'package:firesight/models/inspection_session.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates PDF from InspectionSession using pdf package.
class PdfExportService {
  Future<Uint8List> generateInspectionFormPdf(
    InspectionSession session,
  ) async {
    final doc = pw.Document();
    final form = session.form;

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'FireSight Pre-Incident Inspection Form',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text('Session: ${session.name}'),
          pw.Text('Created: ${session.createdAt.toLocal()}'),
          pw.Text('Updated: ${session.updatedAt.toLocal()}'),
          pw.SizedBox(height: 18),
          _section('Building Information'),
          _field('Building Name', form.buildingName),
          _field('Address', form.address),
          _field('Occupancy Type', form.occupancyType),
          _field('Construction Type', form.constructionType),
          pw.SizedBox(height: 14),
          _section('Fire Protection Systems'),
          _field('Alarm Panel Location', form.alarmPanelLocation),
          _field('Sprinkler Riser Location', form.sprinklerRiserLocation),
          _field('Fire Protection Systems', form.fireProtectionSystems),
          pw.SizedBox(height: 14),
          _section('Utilities / Shutoffs'),
          _field('Utility Shutoffs', form.utilityShutoffs),
          pw.SizedBox(height: 14),
          _section('Access And Hazards'),
          _field('Access Notes', form.accessNotes),
          _field('Known Hazards', form.hazards),
          _field('Additional Notes', form.notes),
          pw.SizedBox(height: 18),
          _section('Observation Appendix'),
          if (session.observations.isEmpty)
            pw.Text('No observations recorded.')
          else
            ...session.observations.map(
              (observation) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  '- ${observation.text ?? '[No text]'}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );

    return doc.save();
  }

  /// Generates PDF and shares via system share sheet.
  Future<void> generateAndShare(InspectionSession session) async {
    final bytes = await generateInspectionFormPdf(session);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${session.name}_report.pdf',
    );
  }

  pw.Widget _section(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _field(String label, String? value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.3),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(_displayValue(value)),
          ),
        ],
      ),
    );
  }

  String _displayValue(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not documented';
    return value.trim();
  }
}
