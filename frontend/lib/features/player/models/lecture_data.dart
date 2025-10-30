class TranscriptMetadata {
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
      totalDuration: json['total_duration'] as int,
      voice: json['voice'] as String,
      speed: (json['speed'] as num).toDouble(),
      languageCode: json['language_code'] as String,
      sampleRate: json['sample_rate'] as int,
    );
  }

  final int totalSentences;
  final int totalDuration;
  final String voice;
  final double speed;
  final String languageCode;
  final int sampleRate;
}

class TranscriptSentence {
  TranscriptSentence({
    required this.sentenceId,
    required this.text,
    this.textKor,
    required this.slideNumber,
    required this.startTime,
    required this.endTime,
    required this.duration,
  }) : assert(sentenceId >= 0, 'sentenceId must be non-negative'),
       assert(slideNumber >= 0, 'slideNumber must be non-negative'),
       assert(startTime >= 0, 'startTime must be non-negative'),
       assert(endTime >= 0, 'endTime must be non-negative'),
       assert(duration >= 0, 'duration must be non-negative');

  factory TranscriptSentence.fromJson(Map<String, dynamic> json) {
    return TranscriptSentence(
      sentenceId: json['sentence_id'] as int,
      text: json['text'] as String,
      textKor: json['text_kor'] as String?,
      slideNumber: json['slide_number'] as int,
      startTime: json['start_time'] as int,
      endTime: json['end_time'] as int,
      duration: json['duration'] as int,
    );
  }

  final int sentenceId;
  final String text;
  final String? textKor;
  final int slideNumber;
  final int startTime;
  final int endTime;
  final int duration;
}

class TranscriptData {
  TranscriptData({required this.metadata, required this.timestamps});

  factory TranscriptData.fromJson(Map<String, dynamic> json) {
    return TranscriptData(
      metadata: TranscriptMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      timestamps: (json['timestamps'] as List)
          .map(
            (item) => TranscriptSentence.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final TranscriptMetadata metadata;
  final List<TranscriptSentence> timestamps;
}
