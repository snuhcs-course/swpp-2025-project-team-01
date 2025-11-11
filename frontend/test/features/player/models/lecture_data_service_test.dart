import 'package:flutter_test/flutter_test.dart';
import 'package:re_view/features/player/models/lecture_data.dart';

void main() {
  group('TranscriptSentence', () {
    group('fromJson - Valid Data', () {
      test('should create instance from valid JSON', () {
        final json = {
          'text_eng': 'Hello world',
          'text_kor': '안녕',
          'slide_number': 2,
          'original_start_time': 10500,
          'original_end_time': 15300,
          'tts_start_time': 10500,
          'tts_end_time': 15300,
        };

        final sentence = TranscriptSentence.fromJson(json);

        expect(sentence.textEng, equals('Hello world'));
        expect(sentence.textKor, equals('안녕'));
        expect(sentence.slideNumber, equals(2));
        expect(sentence.originalStartTime, equals(10500));
        expect(sentence.originalEndTime, equals(15300));
        expect(sentence.ttsStartTime, equals(10500));
        expect(sentence.ttsEndTime, equals(15300));
      });

      test('should handle empty text', () {
        final json = {
          'text_eng': '',
          'text_kor': '',
          'slide_number': 0,
          'original_start_time': 0,
          'original_end_time': 0,
          'tts_start_time': 0,
          'tts_end_time': 0,
        };

        final sentence = TranscriptSentence.fromJson(json);

        expect(sentence.textEng, equals(''));
        expect(sentence.textKor, equals(''));
        expect(sentence.slideNumber, equals(0));
      });

      test('should throw error when values are negative', () {
        final json = {
          'text_eng': 'Negative test',
          'text_kor': 'Negative test',
          'original_start_time': -1,
          'original_end_time': -1,
          'slide_number': -1,
          'tts_start_time': -1,
          'tts_end_time': -5,
        };

        expect(
          () => TranscriptSentence.fromJson(json),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('fromJson - Invalid Data', () {
      test('should throw when eng text is missing', () {
        final json = {
          'text_kor': '더미',
          'slide_number': 0,
          'original_start_time': 0,
          'original_end_time': 0,
          'tts_start_time': 0,
          'tts_end_time': 0,
        };

        expect(() => TranscriptSentence.fromJson(json), throwsA(anything));
      });

      test('should throw when kor text is missing', () {
        final json = {
          'text_eng': 'dummy',
          'slide_number': 0,
          'original_start_time': 0,
          'original_end_time': 0,
          'tts_start_time': 0,
          'tts_end_time': 0,
        };

        expect(() => TranscriptSentence.fromJson(json), throwsA(anything));
      });

      test('should throw when slide_number is wrong type', () {
        final json = {
          'text_eng': 'Hello',
          'slide_number': '1',
          'tts_start_time': 0,
          'tts_end_time': 1000,
        };

        expect(() => TranscriptSentence.fromJson(json), throwsA(anything));
      });

      test('should throw when time values are wrong type', () {
        final json = {
          'sentence_id': 1,
          'text_eng': 'Hello',
          'slide_number': 1,
          'tts_start_time': 'invalid',
          'tts_end_time': 1000,
          'duration': 1000,
        };

        expect(() => TranscriptSentence.fromJson(json), throwsA(anything));
      });
    });
  });

  group('TranscriptData', () {
    group('fromJson - Valid Data', () {
      test('should create instance from valid JSON', () {
        final json = [
          {
            'text_eng': 'First sentence',
            'text_kor': '첫번째 문장',
            'slide_number': 1,
            'original_start_time': 0,
            'original_end_time': 0,
            'tts_start_time': 0,
            'tts_end_time': 5000,
          },
          {
            'text_eng': 'Second sentence',
            'text_kor': '두번째 문장',
            'slide_number': 1,
            'original_start_time': 0,
            'original_end_time': 0,
            'tts_start_time': 5000,
            'tts_end_time': 10000,
          },
        ];

        final data = TranscriptData.fromJson(json);

        expect(data.timestamps.length, equals(2));
        expect(data.timestamps[0].textEng, equals('First sentence'));
        expect(data.timestamps[1].textEng, equals('Second sentence'));
      });

      test('should handle empty timestamps array', () {
        final json = [];

        final data = TranscriptData.fromJson(json);

        expect(data.timestamps.length, equals(0));
        expect(data.timestamps, isEmpty);
      });

      test('should handle single timestamp', () {
        final json = [
          {
            'sentence_id': 1,
            'text_eng': 'Only one',
            'text_kor': '단 하나',
            'slide_number': 1,
            'original_start_time': 0,
            'original_end_time': 0,
            'tts_start_time': 0,
            'tts_end_time': 3500,
          },
        ];

        final data = TranscriptData.fromJson(json);

        expect(data.timestamps.length, equals(1));
        expect(data.timestamps.first.textEng, equals('Only one'));
        expect(data.timestamps.first.textKor, equals('단 하나'));
      });

      test('should handle many timestamps', () {
        final timestampsList = List.generate(
          1000,
          (i) => {
            'text_eng': 'Sentence $i',
            'text_kor': '$i 번째 문장',
            'slide_number': i ~/ 10,
            'original_start_time': i * 1000,
            'original_end_time': (i + 1) * 1000,
            'tts_start_time': i * 1000,
            'tts_end_time': (i + 1) * 1000,
          },
        );

        final json = timestampsList;

        final data = TranscriptData.fromJson(json);

        expect(data.timestamps.length, equals(1000));
        expect(data.timestamps[0].textEng, equals('Sentence 0'));
        expect(data.timestamps[999].textEng, equals('Sentence 999'));
        expect(data.timestamps[0].textKor, equals('0 번째 문장'));
        expect(data.timestamps[999].textKor, equals('999 번째 문장'));
      });
    });

    group('fromJson - Invalid Data', () {
      test('should throw when timestamps is not a list', () {
        final json = 'invaild';

        expect(() => TranscriptData.fromJson(json), throwsA(anything));
      });

      test('should throw when timestamp item is invalid', () {
        final json = [
          {
            // Missing required fields
          },
        ];

        expect(() => TranscriptData.fromJson(json), throwsA(anything));
      });
    });
  });
}
