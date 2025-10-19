import 'package:just_audio/just_audio.dart' as ja;
import 'dart:async';
import 'dart:developer' as developer;

/// 오디오 재생 서비스 (just_audio 사용)
class AudioService {
  AudioService() {
    // 재생 위치 변경 리스너
    _player.positionStream.listen((position) {
      developer.log('[AUDIO_SERVICE] onPositionChanged: ${position.inMilliseconds}ms');
      _positionController.add(position);
    });

    // 재생 상태 변경 리스너
    _player.playerStateStream.listen((state) {
      final playerState = _convertToPlayerState(state);
      _stateController.add(playerState);
    });
  }

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();  

  /// just_audio의 PlayerState를 커스텀 PlayerState로 변환
  PlayerState _convertToPlayerState(ja.PlayerState state) {
    if (state.playing) {
      return PlayerState.playing;
    } else if (state.processingState == ja.ProcessingState.completed) {
      return PlayerState.completed;
    } else {
      return PlayerState.paused;
    }
  }

  /// 오디오 파일 로드 및 재생 준비
  /// [path]가 'assets/'로 시작하면 asset으로, '/'로 시작하면 파일로 처리
  Future<void> loadAudio(String path) async {
    try {
      if (path.startsWith('assets/')) {
        // 이미 'assets/'가 포함된 경로
        await _player.setAsset(path);
        developer.log('[AUDIO_SERVICE] Audio loaded from asset: $path');
      } else {
        // 상대 경로 (assets/ 추가)
        await _player.setFilePath('$path');
        developer.log('[AUDIO_SERVICE] Audio loaded from asset: assets/$path');
      }
    } catch (e) {
      developer.log('[AUDIO_SERVICE] Error loading audio: $e');
      rethrow;
    }
  }

  /// 재생
  Future<void> play() async {
    await _player.play();
  }

  /// 일시정지
  Future<void> pause() async {
    await _player.pause();
  }

  /// 특정 위치로 이동
  Future<void> seek(Duration position) async {
    developer.log('[AUDIO_SERVICE] seek called: ${position.inMilliseconds}ms');
    await _player.seek(position);
  }

  /// 현재 재생 위치 가져오기
  Future<Duration?> getCurrentPosition() async {
    return _player.position;
  }

  /// 재생 중인지 확인
  bool get isPlaying => _player.playing;

  /// 오디오 정지
  Future<void> stop() async {
    await _player.stop();
  }

  /// 리소스 정리
  Future<void> dispose() async {
    await _player.dispose();
    await _positionController.close();
    await _stateController.close();
  }

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<PlayerState> get stateStream => _stateController.stream;
}

/// audioplayers 호환을 위한 PlayerState enum
enum PlayerState {
  stopped,
  playing,
  paused,
  completed,
}
