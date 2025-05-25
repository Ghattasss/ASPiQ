import 'dart:io';
//import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';


class PdfShareService {
  Future<void> sharePdf(File pdfFile, {String? subject, String? text}) async {
    if (!await pdfFile.exists()) {
      if (kDebugMode) {
        print("PDF file does not exist at ${pdfFile.path}");
      }
      // Optionally, throw an exception or handle the error as appropriate
      throw Exception("File to share does not exist.");
    }

    try {
      // For share_plus, XFile is preferred for better cross-platform compatibility
      final xfile = XFile(pdfFile.path);
      await Share.shareXFiles(
        [xfile],
        subject: subject ?? 'Child Report PDF',
        text: text ?? 'Please find the attached child report PDF.',
      );
      if (kDebugMode) {
        print("PDF shared successfully: ${pdfFile.path}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sharing PDF: $e");
      }
      // Re-throw or handle as appropriate for the app's error handling strategy
      throw Exception("Failed to share PDF: $e");
    }
  }
}

// Example of how to use (for testing, not part of the class file):
/*
Future<void> main() async {
  // This main function is for testing and won't run in a Flutter app directly this way.
  // You'd call this from your Flutter UI after generating the PDF.

  // Assume pdfGeneratorService.generateReportPdf() has been called and returned a File object
  // For this example, let's simulate a file path.
  // In a real app, you'd get this from the PdfGeneratorService.
  // final String fakePdfPath = '/path/to/your/generated/child_report.pdf';
  // IMPORTANT: This path needs to be valid and the file must exist for sharing to work.
  // For a real test, you'd need to ensure a file is actually at this path.
  // Since we can't create files easily in a pure Dart test environment without Flutter context for path_provider,
  // this example is more conceptual.

  // Let's assume a file was created by PdfGeneratorService in the temp directory
  // final Directory tempDir = await getTemporaryDirectory(); // Needs path_provider, Flutter context
  // final File testPdfFile = File('${tempDir.path}/child_report.pdf');
    // await testPdfFile.writeAsStringSync(
  */