import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// 오디오 재생 서비스
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _stateController = StreamController<PlayerState>.broadcast();
  String? _currentAssetPath;

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<PlayerState> get stateStream => _stateController.stream;

  AudioService() {
    // AudioContext 설정 (Android에서 중요)
    _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );

    // 재생 위치 변경 리스너
    _player.onPositionChanged.listen((position) {
      _positionController.add(position);
    });

    // 재생 상태 변경 리스너
    _player.onPlayerStateChanged.listen((state) {
      _stateController.add(state);
    });
  }

  /// 오디오 파일 로드 및 재생 준비
  Future<void> loadAudio(String assetPath) async {
    _currentAssetPath = assetPath;
    await _player.setVolume(1.0);
    await _player.setSource(AssetSource(assetPath));
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  /// 재생
  Future<void> play() async {
    if (_player.state == PlayerState.stopped || _player.state == PlayerState.completed) {
      if (_currentAssetPath != null) {
        await _player.play(AssetSource(_currentAssetPath!));
      }
    } else if (_player.state == PlayerState.paused) {
      await _player.resume();
    }
  }

  /// 일시정지
  Future<void> pause() async {
    await _player.pause();
  }

  /// 특정 위치로 이동
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// 현재 재생 위치 가져오기
  Future<Duration?> getCurrentPosition() async {
    return await _player.getCurrentPosition();
  }

  /// 재생 중인지 확인
  bool get isPlaying => _player.state == PlayerState.playing;

  /// 리소스 정리
  void dispose() {
    _player.dispose();
    _positionController.close();
    _stateController.close();
  }
}
