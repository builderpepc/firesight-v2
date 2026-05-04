import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firesight/models/inspection_session.dart';

/// Generates PDF from InspectionSession using pdf package.
class PdfExportService {
  /// Generates PDF and shares via system share sheet.
  Future<void> generateAndShare(InspectionSession session) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              session.name,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Created: ${session.createdAt.toLocal()}'),
            pw.SizedBox(height: 20),
            // TODO: Add observations and photos to PDF.
            ...session.observations.map(
              (obs) => pw.Text(
                obs.text ?? '[No text]',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${session.name}_report.pdf',
    );
  }
}
