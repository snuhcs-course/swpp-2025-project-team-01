import 'dart:io';
import 'package:re_view/features/edit/fetch_lecture.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:test/test.dart';

void main() {
  group('Lecture Fetch Helpers', () {
    test('PDF Splitting', () async {
      final inputFilePath = 'assets/lectures/lec_demo_002/lec_demo_002_slides.pdf';
      final bytes = await File(inputFilePath).readAsBytes();
      final originalPdf = PdfDocument(inputBytes: bytes);
      final originalSize = originalPdf.pages[2].size;
      await splitPdfRange(inputFilePath, start: 3, end: 5, order: 1);
      final outputPath = inputFilePath.replaceFirst(
        RegExp(r'\.pdf$', caseSensitive: false),
        '_tmp1.pdf',
      );
      final inputBytes = await File(outputPath).readAsBytes();
      final splittedPdf = PdfDocument(inputBytes: inputBytes);
      expect(splittedPdf.pages.count, 3);
      expect(splittedPdf.pages[0].size, originalSize);
    });
  });
}