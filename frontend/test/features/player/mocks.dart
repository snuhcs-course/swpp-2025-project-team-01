import 'package:mockito/annotations.dart';
import 'package:re_view/data/hive_manager.dart';
import 'package:re_view/features/player/services/audio_service.dart';
import 'package:re_view/features/player/services/pdf_cache_service.dart';
import 'package:pdfx/pdfx.dart';
import 'package:re_view/features/player/services/pdf_service.dart';

/// Common mocks for player tests
///
/// This file contains all mock definitions used across player-related tests.
/// Run `flutter pub run build_runner build --delete-conflicting-outputs`
/// to generate mocks after any changes.
@GenerateMocks([AudioService, PdfCacheService, HiveManager, PdfService])
@GenerateNiceMocks([MockSpec<PdfDocument>()])
void main() {}
