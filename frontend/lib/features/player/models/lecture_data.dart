// 강의 데이터 모델

class LectureMetadata {
  final String lectureId;
  final String subjectId;
  final String title;
  final String weekLabel;
  final int durationSec;
  final int slides;

  LectureMetadata({
    required this.lectureId,
    required this.subjectId,
    required this.title,
    required this.weekLabel,
    required this.durationSec,
    required this.slides,
  });

  factory LectureMetadata.fromJson(Map<String, dynamic> json) {
    return LectureMetadata(
      lectureId: json['lectureId'] as String,
      subjectId: json['subjectId'] as String,
      title: json['title'] as String,
      weekLabel: json['weekLabel'] as String,
      durationSec: json['durationSec'] as int,
      slides: json['slides'] as int,
    );
  }
}

class TranscriptMetadata {
  final int totalSentences;
  final double totalDuration;
  final String voice;
  final double speed;
  final String languageCode;
  final int sampleRate;

  TranscriptMetadata({
    required this.totalSentences,
    required this.totalDuration,
    required this.voice,
    required this.speed,
    required this.languageCode,
    required this.sampleRate,
  });

  factory TranscriptMetadata.fromJson(Map<String, dynamic> json) {
    return TranscriptMetadata(
      totalSentences: json['total_sentences'] as int,
      totalDuration: (json['total_duration'] as num).toDouble(),
      voice: json['voice'] as String,
      speed: (json['speed'] as num).toDouble(),
      languageCode: json['language_code'] as String,
      sampleRate: json['sample_rate'] as int,
    );
  }
}

class TranscriptSentence {
  final int sentenceId;
  final String text;
  final int slideNumber;
  final double startTime;
  final double endTime;
  final double duration;

  TranscriptSentence({
    required this.sentenceId,
    required this.text,
    required this.slideNumber,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  factory TranscriptSentence.fromJson(Map<String, dynamic> json) {
    return TranscriptSentence(
      sentenceId: json['sentence_id'] as int,
      text: json['text'] as String,
      slideNumber: json['slide_number'] as int,
      startTime: (json['start_time'] as num).toDouble(),
      endTime: (json['end_time'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
    );
  }
}

class TranscriptData {
  final TranscriptMetadata metadata;
  final List<TranscriptSentence> timestamps;

  TranscriptData({
    required this.metadata,
    required this.timestamps,
  });

  factory TranscriptData.fromJson(Map<String, dynamic> json) {
    return TranscriptData(
      metadata: TranscriptMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      timestamps: (json['timestamps'] as List)
          .map((item) => TranscriptSentence.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
