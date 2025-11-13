import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:re_view/features/player/services/audio_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'audio_service_test.mocks.dart';

@GenerateMocks([ja.AudioPlayer])
void main() {
  group('AudioService with Mock', () {
    late AudioService audioService;
    late MockAudioPlayer mockPlayer;
    late StreamController<Duration> positionController;
    late StreamController<ja.PlayerState> stateController;

    setUp(() {
      mockPlayer = MockAudioPlayer();
      positionController = StreamController<Duration>.broadcast();
      stateController = StreamController<ja.PlayerState>.broadcast();

      // Mock stream setup
      when(
        mockPlayer.positionStream,
      ).thenAnswer((_) => positionController.stream);
      when(
        mockPlayer.playerStateStream,
      ).thenAnswer((_) => stateController.stream);

      audioService = AudioService(player: mockPlayer);
    });

    tearDown(() async {
      await positionController.close();
      await stateController.close();
    });

    group('Initialization and Resource Management', () {
      test('should create AudioService instance successfully', () {
        expect(audioService, isNotNull);
        expect(audioService.positionStream, isA<Stream<Duration>>());
        expect(audioService.stateStream, isA<Stream<ja.PlayerState>>());
      });

      test('should dispose player when dispose is called', () async {
        when(mockPlayer.dispose()).thenAnswer((_) async => {});

        await audioService.dispose();

        verify(mockPlayer.dispose()).called(1);
      });

      test('should handle multiple dispose calls', () async {
        when(mockPlayer.dispose()).thenAnswer((_) async => {});

        await audioService.dispose();
        await audioService.dispose();

        verify(mockPlayer.dispose()).called(2);
      });
    });

    group('Audio Loading', () {
      test('should call setAsset when path starts with assets/', () async {
        final assetPath = 'assets/lectures/lec_demo_001/audio.mp3';
        when(
          mockPlayer.setAsset(assetPath),
        ).thenAnswer((_) async => Duration(seconds: 100));

        await audioService.loadAudio(assetPath);

        verify(mockPlayer.setAsset(assetPath)).called(1);
        verifyNever(mockPlayer.setFilePath(any));
      });

      test('should call setFilePath when path starts with /', () async {
        final filePath = '/path/to/audio/file.mp3';
        when(
          mockPlayer.setFilePath(filePath),
        ).thenAnswer((_) async => Duration(seconds: 100));

        await audioService.loadAudio(filePath);

        verify(mockPlayer.setFilePath(filePath)).called(1);
        verifyNever(mockPlayer.setAsset(any));
      });

      test('should call setFilePath for non-asset paths', () async {
        final relativePath = 'relative/path/to/audio.mp3';
        when(
          mockPlayer.setFilePath(relativePath),
        ).thenAnswer((_) async => Duration(seconds: 100));

        await audioService.loadAudio(relativePath);

        verify(mockPlayer.setFilePath(relativePath)).called(1);
        verifyNever(mockPlayer.setAsset(any));
      });

      test('should handle empty path', () async {
        final emptyPath = '';
        when(
          mockPlayer.setFilePath(emptyPath),
        ).thenThrow(Exception('Invalid path'));

        expect(() => audioService.loadAudio(emptyPath), throwsA(anything));
      });

      test('should rethrow exception from setAsset', () async {
        final assetPath = 'assets/invalid/path.mp3';
        when(
          mockPlayer.setAsset(assetPath),
        ).thenThrow(Exception('Asset not found'));

        expect(
          () => audioService.loadAudio(assetPath),
          throwsA(isA<Exception>()),
        );

        verify(mockPlayer.setAsset(assetPath)).called(1);
      });

      test('should rethrow exception from setFilePath', () async {
        final filePath = '/invalid/path.mp3';
        when(
          mockPlayer.setFilePath(filePath),
        ).thenThrow(Exception('File not found'));

        expect(
          () => audioService.loadAudio(filePath),
          throwsA(isA<Exception>()),
        );

        verify(mockPlayer.setFilePath(filePath)).called(1);
      });

      test('should load different files consecutively', () async {
        final assetPath1 = 'assets/audio1.mp3';
        final assetPath2 = 'assets/audio2.mp3';

        when(
          mockPlayer.setAsset(any),
        ).thenAnswer((_) async => Duration(seconds: 100));

        await audioService.loadAudio(assetPath1);
        await audioService.loadAudio(assetPath2);

        verify(mockPlayer.setAsset(assetPath1)).called(1);
        verify(mockPlayer.setAsset(assetPath2)).called(1);
      });
    });

    group('Playback Controls', () {
      test('should call player.play() when play is called', () async {
        when(mockPlayer.play()).thenAnswer((_) async => {});

        await audioService.play();

        verify(mockPlayer.play()).called(1);
      });

      test('should call player.pause() when pause is called', () async {
        when(mockPlayer.pause()).thenAnswer((_) async => {});

        await audioService.pause();

        verify(mockPlayer.pause()).called(1);
      });

      test('should call player.seek() with correct position', () async {
        final position = Duration(seconds: 10);
        when(mockPlayer.seek(position)).thenAnswer((_) async => {});

        await audioService.seek(position);

        verify(mockPlayer.seek(position)).called(1);
      });

      test(
        'should handle multiple seek calls with different positions',
        () async {
          when(mockPlayer.seek(any)).thenAnswer((_) async => {});

          await audioService.seek(Duration(seconds: 5));
          await audioService.seek(Duration(seconds: 10));
          await audioService.seek(Duration(seconds: 3));

          verify(mockPlayer.seek(Duration(seconds: 5))).called(1);
          verify(mockPlayer.seek(Duration(seconds: 10))).called(1);
          verify(mockPlayer.seek(Duration(seconds: 3))).called(1);
        },
      );

      test('should rethrow exception from play()', () async {
        when(mockPlayer.play()).thenThrow(Exception('Play failed'));

        expect(() => audioService.play(), throwsA(isA<Exception>()));
      });

      test('should rethrow exception from pause()', () async {
        when(mockPlayer.pause()).thenThrow(Exception('Pause failed'));

        expect(() => audioService.pause(), throwsA(isA<Exception>()));
      });

      test('should rethrow exception from seek()', () async {
        when(mockPlayer.seek(any)).thenThrow(Exception('Seek failed'));

        expect(
          () => audioService.seek(Duration(seconds: 10)),
          throwsA(isA<Exception>()),
        );
      });

      test('should call player.setSpeed() with correct speed', () async {
        final speed = 1.5;
        when(mockPlayer.setSpeed(speed)).thenAnswer((_) async => {});

        await audioService.setSpeed(speed);

        verify(mockPlayer.setSpeed(speed)).called(1);
      });

      test(
        'should handle multiple setSpeed calls with different speeds',
        () async {
          when(mockPlayer.setSpeed(any)).thenAnswer((_) async => {});

          await audioService.setSpeed(0.5);
          await audioService.setSpeed(1.0);
          await audioService.setSpeed(2.0);

          verify(mockPlayer.setSpeed(0.5)).called(1);
          verify(mockPlayer.setSpeed(1.0)).called(1);
          verify(mockPlayer.setSpeed(2.0)).called(1);
        },
      );

      test('should rethrow exception from setSpeed()', () async {
        when(mockPlayer.setSpeed(any)).thenThrow(Exception('SetSpeed failed'));

        expect(() => audioService.setSpeed(1.5), throwsA(isA<Exception>()));
      });
    });

    group('Streams', () {
      test('should provide positionStream from player', () {
        final stream = audioService.positionStream;
        expect(stream, isA<Stream<Duration>>());
        verify(mockPlayer.positionStream).called(1);
      });

      test('should provide stateStream from player', () {
        final stream = audioService.stateStream;
        expect(stream, isA<Stream<ja.PlayerState>>());
        verify(mockPlayer.playerStateStream).called(1);
      });

      test('positionStream should emit Duration values', () async {
        // Subscribe first, then add data
        final futurePositions = audioService.positionStream.take(2).toList();

        // Add data after subscription
        positionController.add(Duration(seconds: 5));
        positionController.add(Duration(seconds: 10));

        final positions = await futurePositions;

        expect(positions.length, 2);
        expect(positions[0], Duration(seconds: 5));
        expect(positions[1], Duration(seconds: 10));
      });

      test('stateStream should emit PlayerState values', () async {
        final state1 = ja.PlayerState(false, ja.ProcessingState.idle);
        final state2 = ja.PlayerState(true, ja.ProcessingState.ready);

        // Subscribe first, then add data
        final futureStates = audioService.stateStream.take(2).toList();

        stateController.add(state1);
        stateController.add(state2);

        final states = await futureStates;

        expect(states.length, 2);
        expect(states[0].playing, false);
        expect(states[0].processingState, ja.ProcessingState.idle);
        expect(states[1].playing, true);
        expect(states[1].processingState, ja.ProcessingState.ready);
      });

      test('positionStream should handle multiple listeners', () async {
        final stream = audioService.positionStream;

        // First value
        final future1 = stream.first;
        positionController.add(Duration(seconds: 1));
        final position1 = await future1;

        // Second value
        final future2 = stream.first;
        positionController.add(Duration(seconds: 2));
        final position2 = await future2;

        expect(position1, Duration(seconds: 1));
        expect(position2, Duration(seconds: 2));
      });

      test('stateStream should handle multiple listeners', () async {
        final state = ja.PlayerState(false, ja.ProcessingState.idle);

        final stream = audioService.stateStream;
        final futureState = stream.first;

        stateController.add(state);

        final receivedState = await futureState;
        expect(receivedState.playing, false);
        expect(receivedState.processingState, ja.ProcessingState.idle);
      });
    });

    group('Audio Switching', () {
      test('should only seek when switching to same audio path', () async {
        final samePath = 'assets/audio.mp3';
        when(
          mockPlayer.setAsset(samePath),
        ).thenAnswer((_) async => Duration(seconds: 100));
        when(mockPlayer.seek(any)).thenAnswer((_) async => {});

        // Load initial audio
        await audioService.loadAudio(samePath);

        // Switch to same audio with different position
        await audioService.switchAudio(samePath, 5000);

        // Should only call seek, not setAsset/setFilePath again
        verify(mockPlayer.setAsset(samePath)).called(1);
        verify(mockPlayer.seek(Duration(milliseconds: 5000))).called(1);
        verifyNever(mockPlayer.setFilePath(any));
      });

      test(
        'should load new asset and seek when switching to different audio',
        () async {
          final path1 = 'assets/audio1.mp3';
          final path2 = 'assets/audio2.mp3';
          when(mockPlayer.setAsset(any))
              .thenAnswer((_) async => Duration(seconds: 100));
          when(mockPlayer.seek(any)).thenAnswer((_) async => {});
          when(mockPlayer.playing).thenReturn(false);

          // Load initial audio
          await audioService.loadAudio(path1);

          // Switch to different audio
          await audioService.switchAudio(path2, 3000);

          verify(mockPlayer.setAsset(path1)).called(1);
          verify(mockPlayer.setAsset(path2)).called(1);
          verify(mockPlayer.seek(Duration(milliseconds: 3000))).called(1);
        },
      );

      test(
        'should load new file and seek when switching to different file path',
        () async {
          final path1 = '/path/to/audio1.mp3';
          final path2 = '/path/to/audio2.mp3';
          when(mockPlayer.setFilePath(any))
              .thenAnswer((_) async => Duration(seconds: 100));
          when(mockPlayer.seek(any)).thenAnswer((_) async => {});
          when(mockPlayer.playing).thenReturn(false);

          // Load initial audio
          await audioService.loadAudio(path1);

          // Switch to different audio
          await audioService.switchAudio(path2, 2000);

          verify(mockPlayer.setFilePath(path1)).called(1);
          verify(mockPlayer.setFilePath(path2)).called(1);
          verify(mockPlayer.seek(Duration(milliseconds: 2000))).called(1);
        },
      );

      test('should restore playing state when switching audio', () async {
        final path1 = 'assets/audio1.mp3';
        final path2 = 'assets/audio2.mp3';
        when(mockPlayer.setAsset(any))
            .thenAnswer((_) async => Duration(seconds: 100));
        when(mockPlayer.seek(any)).thenAnswer((_) async => {});
        when(mockPlayer.playing).thenReturn(true);
        when(mockPlayer.play()).thenAnswer((_) async => {});

        // Load initial audio
        await audioService.loadAudio(path1);

        // Switch to different audio while playing
        await audioService.switchAudio(path2, 1000);

        verify(mockPlayer.playing).called(1);
        verify(mockPlayer.play()).called(1);
      });

      test('should not play when switching audio if not playing', () async {
        final path1 = 'assets/audio1.mp3';
        final path2 = 'assets/audio2.mp3';
        when(mockPlayer.setAsset(any))
            .thenAnswer((_) async => Duration(seconds: 100));
        when(mockPlayer.seek(any)).thenAnswer((_) async => {});
        when(mockPlayer.playing).thenReturn(false);

        // Load initial audio
        await audioService.loadAudio(path1);

        // Switch to different audio while paused
        await audioService.switchAudio(path2, 1000);

        verify(mockPlayer.playing).called(1);
        verifyNever(mockPlayer.play());
      });

      test(
        'should handle mixed asset and file path switching',
        () async {
          final assetPath = 'assets/audio1.mp3';
          final filePath = '/path/to/audio2.mp3';
          when(mockPlayer.setAsset(any))
              .thenAnswer((_) async => Duration(seconds: 100));
          when(mockPlayer.setFilePath(any))
              .thenAnswer((_) async => Duration(seconds: 100));
          when(mockPlayer.seek(any)).thenAnswer((_) async => {});
          when(mockPlayer.playing).thenReturn(false);

          // Load asset audio
          await audioService.loadAudio(assetPath);

          // Switch to file path audio
          await audioService.switchAudio(filePath, 500);

          verify(mockPlayer.setAsset(assetPath)).called(1);
          verify(mockPlayer.setFilePath(filePath)).called(1);
          verify(mockPlayer.seek(Duration(milliseconds: 500))).called(1);
        },
      );

      test('should rethrow exception from setAsset during switch', () async {
        final path1 = 'assets/audio1.mp3';
        final path2 = 'assets/invalid.mp3';
        when(mockPlayer.setAsset(path1))
            .thenAnswer((_) async => Duration(seconds: 100));
        when(mockPlayer.setAsset(path2)).thenThrow(Exception('Asset not found'));
        when(mockPlayer.playing).thenReturn(false);

        // Load initial audio
        await audioService.loadAudio(path1);

        // Switch to invalid audio
        expect(
          () => audioService.switchAudio(path2, 1000),
          throwsA(isA<Exception>()),
        );

        verify(mockPlayer.setAsset(path2)).called(1);
      });

      test('should rethrow exception from setFilePath during switch', () async {
        final path1 = '/path/to/audio1.mp3';
        final path2 = '/invalid/path.mp3';
        when(mockPlayer.setFilePath(path1))
            .thenAnswer((_) async => Duration(seconds: 100));
        when(mockPlayer.setFilePath(path2))
            .thenThrow(Exception('File not found'));
        when(mockPlayer.playing).thenReturn(false);

        // Load initial audio
        await audioService.loadAudio(path1);

        // Switch to invalid audio
        expect(
          () => audioService.switchAudio(path2, 1000),
          throwsA(isA<Exception>()),
        );

        verify(mockPlayer.setFilePath(path2)).called(1);
      });

      test('should seek to zero position when targetPositionMs is 0', () async {
        final path1 = 'assets/audio1.mp3';
        final path2 = 'assets/audio2.mp3';
        when(mockPlayer.setAsset(any))
            .thenAnswer((_) async => Duration(seconds: 100));
        when(mockPlayer.seek(any)).thenAnswer((_) async => {});
        when(mockPlayer.playing).thenReturn(false);

        // Load initial audio
        await audioService.loadAudio(path1);

        // Switch to different audio at position 0
        await audioService.switchAudio(path2, 0);

        verify(mockPlayer.seek(Duration.zero)).called(1);
      });

      test(
        'should handle large position values when switching',
        () async {
          final path1 = 'assets/audio1.mp3';
          final path2 = 'assets/audio2.mp3';
          when(mockPlayer.setAsset(any))
              .thenAnswer((_) async => Duration(seconds: 100));
          when(mockPlayer.seek(any)).thenAnswer((_) async => {});
          when(mockPlayer.playing).thenReturn(false);

          // Load initial audio
          await audioService.loadAudio(path1);

          // Switch with large position value (1 hour)
          final largePosition = 3600000; // 1 hour in milliseconds
          await audioService.switchAudio(path2, largePosition);

          verify(
            mockPlayer.seek(Duration(milliseconds: largePosition)),
          ).called(1);
        },
      );

      test(
        'should maintain correct audio path after successful switch',
        () async {
          final path1 = 'assets/audio1.mp3';
          final path2 = 'assets/audio2.mp3';
          final path3 = 'assets/audio3.mp3';
          when(mockPlayer.setAsset(any))
              .thenAnswer((_) async => Duration(seconds: 100));
          when(mockPlayer.seek(any)).thenAnswer((_) async => {});
          when(mockPlayer.playing).thenReturn(false);

          // Load initial audio
          await audioService.loadAudio(path1);

          // Switch to second audio
          await audioService.switchAudio(path2, 1000);

          // Try to switch to same audio (should only seek)
          await audioService.switchAudio(path2, 2000);

          // Switch to third audio
          await audioService.switchAudio(path3, 3000);

          verify(mockPlayer.setAsset(path1)).called(1);
          verify(mockPlayer.setAsset(path2)).called(1);
          verify(mockPlayer.setAsset(path3)).called(1);
          verify(mockPlayer.seek(Duration(milliseconds: 1000))).called(1);
          verify(mockPlayer.seek(Duration(milliseconds: 2000))).called(1);
          verify(mockPlayer.seek(Duration(milliseconds: 3000))).called(1);
        },
      );
    });

    group('Edge Cases', () {
      test('should handle concurrent play and seek', () async {
        when(mockPlayer.play()).thenAnswer((_) async => {});
        when(mockPlayer.seek(any)).thenAnswer((_) async => {});

        await Future.wait([
          audioService.play(),
          audioService.seek(Duration(seconds: 5)),
        ]);

        verify(mockPlayer.play()).called(1);
        verify(mockPlayer.seek(Duration(seconds: 5))).called(1);
      });

      test('should handle exception during load and recover', () async {
        final failPath = 'assets/fail.mp3';
        final successPath = 'assets/success.mp3';

        when(mockPlayer.setAsset(failPath)).thenThrow(Exception('Load failed'));
        when(
          mockPlayer.setAsset(successPath),
        ).thenAnswer((_) async => Duration(seconds: 100));

        // First load fails
        expect(
          () => audioService.loadAudio(failPath),
          throwsA(isA<Exception>()),
        );

        // Second load succeeds
        await audioService.loadAudio(successPath);

        verify(mockPlayer.setAsset(failPath)).called(1);
        verify(mockPlayer.setAsset(successPath)).called(1);
      });
    });
  });
}
