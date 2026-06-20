import 'package:audioplayers/audioplayers.dart';

/// Simple audio service for sound effects using AudioPlayer
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isMuted = false;
  double _volume = 0.7;

  bool get isMuted => _isMuted;
  double get volume => _volume;

  Future<void> playCorrect() async {
    if (_isMuted) return;
    // Play a system sound tone for correct answer
    try {
      await _sfxPlayer.setVolume(_volume);
      await _sfxPlayer.setSource(AssetSource('audio/correct.mp3'));
      await _sfxPlayer.resume();
    } catch (_) {}
  }

  Future<void> playWrong() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.setVolume(_volume);
      await _sfxPlayer.setSource(AssetSource('audio/wrong.mp3'));
      await _sfxPlayer.resume();
    } catch (_) {}
  }

  Future<void> playClick() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.setVolume(_volume * 0.5);
      await _sfxPlayer.setSource(AssetSource('audio/click.mp3'));
      await _sfxPlayer.resume();
    } catch (_) {}
  }

  Future<void> playVictory() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.setVolume(_volume);
      await _sfxPlayer.setSource(AssetSource('audio/victory.mp3'));
      await _sfxPlayer.resume();
    } catch (_) {}
  }

  Future<void> playCountdown() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.setVolume(_volume * 0.6);
      await _sfxPlayer.setSource(AssetSource('audio/tick.mp3'));
      await _sfxPlayer.resume();
    } catch (_) {}
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer.setVolume(0);
    } else {
      _bgmPlayer.setVolume(_volume);
    }
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _bgmPlayer.setVolume(_isMuted ? 0 : _volume);
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
