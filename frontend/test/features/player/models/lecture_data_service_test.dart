import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/features/player/models/lecture_data.dart';

void main() {
  group('TranscriptMetadata', () {
    group('fromJson - Valid Data', () {
      test('should create instance from valid JSON', () {
        final json = {
          'total_sentences': 10,
          'total_duration': 120500,
          'voice': 'af_heart',
          'speed': 1.0,
          'language_code': 'a',
          'sample_rate': 24000,
        };

        final metadata = TranscriptMetadata.fromJson(json);

        expect(metadata.totalSentences, equals(10));
        expect(metadata.totalDuration, equals(120500));
        expect(metadata.voice, equals('af_heart'));
        expect(metadata.speed, equals(1.0));
        expect(metadata.languageCode, equals('a'));
        expect(metadata.sampleRate, equals(24000));
      });

      test('should throw error when duration is double', () {
        final json = {
          'total_sentences': 5,
          'total_duration': 100.5, // double value instead of int
          'voice': 'voice-1',
          'speed': 1.5,
          'language_code': 'ko-KR',
          'sample_rate': 22050,
        };

        expect(
          () => TranscriptMetadata.fromJson(json),
          throwsA(isA<TypeError>()),
        );
      });

      test('should handle integer speed as double', () {
        final json = {
          'total_sentences': 3,
          'total_duration': 50000,
          'voice': 'voice-2',
          'speed': 2,
          'language_code': 'ja-JP',
          'sample_rate': 16000,
        };

        final metadata = TranscriptMetadata.fromJson(json);

        expect(metadata.speed, isA<double>());
        expect(metadata.speed, equals(2.0));
      });

      test('should handle zero values', () {
        final json = {
          'total_sentences': 0,
          'total_duration': 0,
          'voice': '',
          'speed': 0.0,
          'language_code': '',
          'sample_rate': 0,
        };

        final metadata = TranscriptMetadata.fromJson(json);

        expect(metadata.totalSentences, equals(0));
        expect(metadata.totalDuration, equals(0));
        expect(metadata.voice, equals(''));
        expect(metadata.speed, equals(0.0));
        expect(metadata.languageCode, equals(''));
        expect(metadata.sampleRate, equals(0));
      });
    });

    group('fromJson - Invalid Data', () {
      test('should throw when total_sentences is missing', () {
        final json = {
          'total_duration': 120500,
          'voice': 'voice',
          'speed': 1.0,
          'language_code': 'en-US',
          'sample_rate': 24000,
        };

        expect(() => TranscriptMetadata.fromJson(json), throwsA(anything));
      });

      test('should throw when total_sentences is wrong type', () {
        final json = {
          'total_sentences': '10',
          'total_duration': 120500,
          'voice': 'voice',
          'speed': 1.0,
          'language_code': 'en-US',
          'sample_rate': 24000,
        };

        expect(() => TranscriptMetadata.fromJson(json), throwsA(anything));
      });

      test('should throw when total_duration is wrong type', () {
        final json = {
          'total_sentences': 10,
          'total_duration': 'invalid',
          'voice': 'voice',
          'speed': 1.0,
          'language_code': 'en-US',
          'sample_rate': 24000,
        };

        expect(() => TranscriptMetadata.fromJson(json), throwsA(anything));
      });

      test('should throw when voice is wrong type', () {
        final json = {
          'total_sentences': 10,
          'total_duration': 120500,
          'voice': 123,
          'speed': 1.0,
          'language_code': 'en-US',
          'sample_rate': 24000,
        };

        expect(() => TranscriptMetadata.fromJson(json), throwsA(anything));
      });

      test('should throw when sample_rate is wrong type', () {
        final json = {
          'total_sentences': 10,
          'total_duration': 120500,
          'voice': 'voice',
          'speed': 1.0,
          'language_code': 'en-US',
          'sample_rate': 'invalid',
        };

        expect(() => TranscriptMetadata.fromJson(json), throwsA(anything));
      });
    });
  });

  group('TranscriptSentence', () {
    group('fromJson - Valid Data', () {
      test('should create instance from valid JSON', () {
        final json = {
          'sentence_id': 1,
          'text': 'Hello world',
          'slide_number': 2,
          'start_time': 10500,
          'end_time': 15300,
          'duration': 4800,
        };

        final sentence = TranscriptSentence.fromJson(json);

        expect(sentence.sentenceId, equals(1));
        expect(sentence.text, equals('Hello world'));
        expect(sentence.slideNumber, equals(2));
        expect(sentence.startTime, equals(10500));
        expect(sentence.endTime, equals(15300));
        expect(sentence.duration, equals(4800));
      });

      test('should handle empty text', () {
        final json = {
          'sentence_id': 3,
          'text': '',
          'slide_number': 0,
          'start_time': 0,
          'end_time': 0,
          'duration': 0,
        };

        final sentence = TranscriptSentence.fromJson(json);

        expect(sentence.text, equals(''));
        expect(sentence.slideNumber, equals(0));
      });

      test('should throw error when values are negative', () {
        final json = {
          'sentence_id': -1,
          'text': 'Negative test',
          'slide_number': -1,
          'start_time': -1,
          'end_time': -5,
          'duration': -1,
        };

        expect(
          () => TranscriptSentence.fromJson(json),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('fromJson - Invalid Data', () {
      test('should throw when sentence_id is missing', () {
        final json = {
          'text': 'Hello',
          'slide_number': 1,
          'start_time': 0,
          'end_time': 1000,
          'duration': 1000,
        };

        expect(() => TranscriptSentence.fromJson(json), throwsA(anything));
      });

      test('should throw when text is missing', () {
        final json = {
          'sentence_id': 1,
          'slide_number': 1,
          'start_time': 0,
          'end_time': 1000,
          'duration': 1000,
        };

        expect(() => TranscriptSentence.fromJson(json), throwsA(anything));
      });

      test('should throw when slide_number is wrong type', () {
        final json = {
          'sentence_id': 1,
          'text': 'Hello',
          'slide_number': '1',
          'start_time': 0,
          'end_time': 1000,
          'duration': 1000,
        };

        expect(() => TranscriptSentence.fromJson(json), throwsA(anything));
      });

      test('should throw when time values are wrong type', () {
        final json = {
          'sentence_id': 1,
          'text': 'Hello',
          'slide_number': 1,
          'start_time': 'invalid',
          'end_time': 1000,
          'duration': 1000,
        };

        expect(() => TranscriptSentence.fromJson(json), throwsA(anything));
      });
    });
  });

  group('TranscriptData', () {
    group('fromJson - Valid Data', () {
      test('should create instance from valid JSON', () {
        final json = {
          'metadata': {
            'total_sentences': 2,
            'total_duration': 10000,
            'voice': 'test-voice',
            'speed': 1.0,
            'language_code': 'en-US',
            'sample_rate': 24000,
          },
          'timestamps': [
            {
              'sentence_id': 1,
              'text': 'First sentence',
              'slide_number': 1,
              'start_time': 0,
              'end_time': 5000,
              'duration': 5000,
            },
            {
              'sentence_id': 2,
              'text': 'Second sentence',
              'slide_number': 1,
              'start_time': 5000,
              'end_time': 10000,
              'duration': 5000,
            },
          ],
        };

        final data = TranscriptData.fromJson(json);

        expect(data.metadata, isA<TranscriptMetadata>());
        expect(data.metadata.totalSentences, equals(2));
        expect(data.timestamps.length, equals(2));
        expect(data.timestamps[0].text, equals('First sentence'));
        expect(data.timestamps[1].text, equals('Second sentence'));
      });

      test('should handle empty timestamps array', () {
        final json = {
          'metadata': {
            'total_sentences': 0,
            'total_duration': 0,
            'voice': 'voice',
            'speed': 1.0,
            'language_code': 'en-US',
            'sample_rate': 24000,
          },
          'timestamps': [],
        };

        final data = TranscriptData.fromJson(json);

        expect(data.timestamps.length, equals(0));
        expect(data.timestamps, isEmpty);
      });

      test('should handle single timestamp', () {
        final json = {
          'metadata': {
            'total_sentences': 1,
            'total_duration': 3500,
            'voice': 'voice',
            'speed': 1.0,
            'language_code': 'en-US',
            'sample_rate': 24000,
          },
          'timestamps': [
            {
              'sentence_id': 1,
              'text': 'Only one',
              'slide_number': 1,
              'start_time': 0,
              'end_time': 3500,
              'duration': 3500,
            },
          ],
        };

        final data = TranscriptData.fromJson(json);

        expect(data.timestamps.length, equals(1));
        expect(data.timestamps.first.text, equals('Only one'));
      });

      test('should handle many timestamps', () {
        final timestampsList = List.generate(
          1000,
          (i) => {
            'sentence_id': i,
            'text': 'Sentence $i',
            'slide_number': i ~/ 10,
            'start_time': i * 1000,
            'end_time': (i + 1) * 1000,
            'duration': 1000,
          },
        );

        final json = {
          'metadata': {
            'total_sentences': 100,
            'total_duration': 100000,
            'voice': 'voice',
            'speed': 1.0,
            'language_code': 'en-US',
            'sample_rate': 24000,
          },
          'timestamps': timestampsList,
        };

        final data = TranscriptData.fromJson(json);

        expect(data.timestamps.length, equals(1000));
        expect(data.timestamps[0].text, equals('Sentence 0'));
        expect(data.timestamps[999].text, equals('Sentence 999'));
      });
    });

    group('fromJson - Invalid Data', () {
      test('should throw when metadata is missing', () {
        final json = {'timestamps': []};

        expect(() => TranscriptData.fromJson(json), throwsA(anything));
      });

      test('should throw when timestamps is missing', () {
        final json = {
          'metadata': {
            'total_sentences': 0,
            'total_duration': 0,
            'voice': 'voice',
            'speed': 1.0,
            'language_code': 'en-US',
            'sample_rate': 24000,
          },
        };

        expect(() => TranscriptData.fromJson(json), throwsA(anything));
      });

      test('should throw when metadata is wrong type', () {
        final json = {'metadata': 'invalid', 'timestamps': []};

        expect(() => TranscriptData.fromJson(json), throwsA(anything));
      });

      test('should throw when timestamps is not a list', () {
        final json = {
          'metadata': {
            'total_sentences': 0,
            'total_duration': 0,
            'voice': 'voice',
            'speed': 1.0,
            'language_code': 'en-US',
            'sample_rate': 24000,
          },
          'timestamps': 'invalid',
        };

        expect(() => TranscriptData.fromJson(json), throwsA(anything));
      });

      test('should throw when timestamp item is invalid', () {
        final json = {
          'metadata': {
            'total_sentences': 1,
            'total_duration': 1000,
            'voice': 'voice',
            'speed': 1.0,
            'language_code': 'en-US',
            'sample_rate': 24000,
          },
          'timestamps': [
            {
              'sentence_id': 1,
              // Missing required fields
            },
          ],
        };

        expect(() => TranscriptData.fromJson(json), throwsA(anything));
      });

      test('should throw when metadata fields are invalid', () {
        final json = {
          'metadata': {
            'total_sentences': 'invalid',
            'total_duration': 0,
            'voice': 'voice',
            'speed': 1.0,
            'language_code': 'en-US',
            'sample_rate': 24000,
          },
          'timestamps': [],
        };

        expect(() => TranscriptData.fromJson(json), throwsA(anything));
      });
    });
  });

  group('Integration Tests', () {
    test('should parse complete valid lecture data', () {
      final json = {
        'metadata': {
          'total_sentences': 3,
          'total_duration': 45200,
          'voice': 'en-US-Neural2-D',
          'speed': 1.2,
          'language_code': 'en-US',
          'sample_rate': 24000,
        },
        'timestamps': [
          {
            'sentence_id': 0,
            'text': 'Welcome to this lecture.',
            'slide_number': 1,
            'start_time': 0,
            'end_time': 2500,
            'duration': 2500,
          },
          {
            'sentence_id': 1,
            'text': 'Today we will discuss AI.',
            'slide_number': 1,
            'start_time': 2500,
            'end_time': 5300,
            'duration': 2800,
          },
          {
            'sentence_id': 2,
            'text': 'Let us begin with the basics.',
            'slide_number': 2,
            'start_time': 5300,
            'end_time': 8100,
            'duration': 2800,
          },
        ],
      };

      final data = TranscriptData.fromJson(json);

      expect(data.metadata.totalSentences, equals(3));
      expect(data.metadata.totalDuration, equals(45200));
      expect(data.metadata.speed, equals(1.2));
      expect(data.timestamps.length, equals(3));
      expect(data.timestamps[0].slideNumber, equals(1));
      expect(data.timestamps[2].slideNumber, equals(2));
      expect(data.timestamps[1].startTime, equals(2500));
      expect(data.timestamps[2].endTime, equals(8100));
    });

    test('should maintain data consistency', () {
      final json = {
        'metadata': {
          'total_sentences': 2,
          'total_duration': 10000,
          'voice': 'voice',
          'speed': 1.0,
          'language_code': 'en-US',
          'sample_rate': 24000,
        },
        'timestamps': [
          {
            'sentence_id': 0,
            'text': 'First',
            'slide_number': 1,
            'start_time': 0,
            'end_time': 5000,
            'duration': 5000,
          },
          {
            'sentence_id': 1,
            'text': 'Second',
            'slide_number': 1,
            'start_time': 5000,
            'end_time': 10000,
            'duration': 5000,
          },
        ],
      };

      final data = TranscriptData.fromJson(json);

      expect(data.metadata.totalSentences, equals(data.timestamps.length));
      expect(data.timestamps.last.endTime, equals(data.metadata.totalDuration));
    });
  });
}
