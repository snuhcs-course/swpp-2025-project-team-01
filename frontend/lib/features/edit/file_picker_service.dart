import 'package:file_picker/file_picker.dart';

/// FilePicker를 감싸는 서비스 클래스
///
/// 테스트 시 이 클래스를 상속하거나 Fake 객체로 대체하여 사용
class FilePickerService {
  Future<String?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return result?.files.single.path;
  }

  Future<String?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'mp3', 'wav', 'aac', 'ogg', 'flac'],
    );
    return result?.files.single.path;
  }
}
