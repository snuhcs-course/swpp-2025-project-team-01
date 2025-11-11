class TranscriptSentence {
  TranscriptSentence({
    required this.textEng,
    this.textKor,
    required this.slideNumber,
    required this.ttsStartTime,
    required this.ttsEndTime,
    required this.originalStartTime,
    required this.originalEndTime,
  }) : assert(slideNumber >= 0, 'slideNumber must be non-negative'),
       assert(ttsStartTime >= 0, 'startTime must be non-negative'),
       assert(ttsEndTime >= 0, 'endTime must be non-negative'),
       assert(originalStartTime >= 0, 'originalStartTime must be non-negative'),
       assert(originalEndTime >= 0, 'originalEndTime must be non-negative');

  factory TranscriptSentence.fromJson(Map<String, dynamic> json) {
    return TranscriptSentence(
      textEng: json['text_eng'] as String,
      textKor: json['text_kor'] as String?,
      slideNumber: json['slide_number'] as int,
      ttsStartTime: json['tts_start_time'] as int,
      ttsEndTime: json['tts_end_time'] as int,
      originalStartTime: json['original_start_time'] as int,
      originalEndTime: json['original_end_time'] as int,
    );
  }

  final String textEng;
  final String? textKor;
  final int slideNumber;
  final int ttsStartTime; // TTS audio timing
  final int ttsEndTime; // TTS audio timing
  final int originalStartTime; // Original audio timing
  final int originalEndTime; // Original audio timing
}

class TranscriptData {
  TranscriptData({required this.ttsTotalDuration, required this.originalTotalDuration, required this.timestamps});

  factory TranscriptData.fromJson(dynamic json) {
    final List<dynamic> data = json as List<dynamic>;
    final Map<String, dynamic> lastItem = data[data.length - 1] as Map<String, dynamic>;

    return TranscriptData(
      ttsTotalDuration: lastItem['tts_end_time'] as int,
      originalTotalDuration: lastItem['original_end_time'] as int,
      timestamps: data
          .map(
            (item) => TranscriptSentence.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final int ttsTotalDuration;
  final int originalTotalDuration;
  final List<TranscriptSentence> timestamps;
}
