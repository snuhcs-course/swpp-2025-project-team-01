import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';

class PdfService {
  Future<PdfDocument> openFile(String path) {
    if (path.startsWith('assets/')) {
      return PdfDocument.openAsset(path);
    }
    return PdfDocument.openFile(path);
  }

  Future<PdfDocument> openData(Uint8List data) {
    return PdfDocument.openData(data);
  }
}
