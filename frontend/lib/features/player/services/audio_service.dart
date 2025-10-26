import 'package:just_audio/just_audio.dart' as ja;

/// 오디오 재생 서비스 (just_audio 사용)
class AudioService {
  AudioService({ja.AudioPlayer? player}) : _player = player ?? ja.AudioPlayer();

  final ja.AudioPlayer _player;

  /// 오디오 파일 로드 및 재생 준비
  /// [path]가 'assets/'로 시작하면 asset으로, '/'로 시작하면 파일로 처리
  Future<void> loadAudio(String path) async {
    try {
      if (path.startsWith('assets/')) {
        // 이미 'assets/'가 포함된 경로
        await _player.setAsset(path);
      } else {
        await _player.setFilePath(path);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 재생
  Future<void> play() => _player.play();

  /// 일시정지
  Future<void> pause() => _player.pause();

  /// 특정 위치로 이동
  Future<void> seek(Duration position) => _player.seek(position);

  /// 재생 속도 변경
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// 리소스 정리
  Future<void> dispose() => _player.dispose();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<ja.PlayerState> get stateStream => _player.playerStateStream;
}
