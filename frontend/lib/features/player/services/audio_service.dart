import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;

/// 오디오 재생 서비스 (just_audio 사용)
class AudioService {
  AudioService({ja.AudioPlayer? player}) : _player = player ?? ja.AudioPlayer();

  final ja.AudioPlayer _player;
  String? _currentAudioPath;
  Duration? get duration => _player.duration;

  /// 오디오 파일 로드 및 재생 준비
  /// [path]가 'assets/'로 시작하면 asset으로, '/'로 시작하면 파일로 처리
  Future<void> loadAudio(String path) async {
    try {
      ja.AudioSource source;
      if (path.startsWith('assets/')) {
        source = ja.AudioSource.asset(path);
      } else {
        source = ja.AudioSource.file(path);
      }

      await _player.setAudioSource(source);
      _currentAudioPath = path;
    } catch (e) {
      rethrow;
    }
  }

  /// 오디오 소스 전환 (재생 위치 유지)
  /// [newPath]: 새로운 오디오 파일 경로
  /// [targetPositionMs]: 이동할 위치 (밀리초)
  Future<void> switchAudio(String newPath, int targetPositionMs) async {
    if (_currentAudioPath == newPath) {
      // 같은 오디오면 위치만 이동
      await seek(Duration(milliseconds: targetPositionMs));
      return;
    }

    try {
      // 현재 재생 상태 저장
      final wasPlaying = _player.playing;

      // 새 오디오 로드
      if (newPath.startsWith('assets/')) {
        await _player.setAsset(newPath);
      } else {
        await _player.setFilePath(newPath);
      }
      _currentAudioPath = newPath;

      // 지정된 위치로 이동
      await _player.seek(Duration(milliseconds: targetPositionMs));

      // 재생 상태 복원
      if (wasPlaying) {
        await _player.play();
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

  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<ja.PlayerState> get stateStream => _player.playerStateStream;
}
