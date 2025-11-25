import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';

class PdfService {
  Future<PdfDocument> openFile(String path) {
    return PdfDocument.openFile(path);
  }

  Future<PdfDocument> openAsset(String name) {
    return PdfDocument.openAsset(name);
  }

  Future<PdfDocument> openData(Uint8List data) {
    return PdfDocument.openData(data);
  }
}
