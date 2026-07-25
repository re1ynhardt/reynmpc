import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../backend/audio_backend.dart';
import '../models/track.dart';

enum PlayerRepeatMode { off, all, one }

/// Управляет реальным воспроизведением (just_audio) и очередью треков.
/// Получает URL для проигрывания через [AudioBackend.resolveStreamUrl],
/// поэтому логика плеера полностью независима от источника данных.
class PlayerController extends ChangeNotifier {
  PlayerController(this._backend) {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
      notifyListeners();
    });
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _player.durationStream.listen((d) {
      _playerDuration = d;
      notifyListeners();
    });
  }

  final AudioBackend _backend;
  final AudioPlayer _player = AudioPlayer();

  List<Track> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  // Реальная длительность текущего потока по данным just_audio. У треков,
  // загруженных вручную (без корректных метаданных), Track.duration может
  // быть нулевым, хотя сам файл проигрывается нормально — в этом случае
  // ориентируемся на то, что знает сам плеер, а не на метаданные.
  Duration? _playerDuration;
  double _volume = 0.8;
  bool _shuffle = false;
  PlayerRepeatMode _repeatMode = PlayerRepeatMode.off;

  Track? get currentTrack => (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration {
    final fromPlayer = _playerDuration;
    if (fromPlayer != null && fromPlayer > Duration.zero) return fromPlayer;
    return currentTrack?.duration ?? Duration.zero;
  }
  double get volume => _volume;
  bool get shuffle => _shuffle;
  PlayerRepeatMode get repeatMode => _repeatMode;
  List<Track> get queue => _queue;
  bool get hasTrack => currentTrack != null;

  /// Запускает воспроизведение конкретного трека из списка (плейлист/поиск),
  /// сохраняя остальной список как очередь для "следующий/предыдущий".
  Future<void> playFromList(List<Track> list, int index) async {
    _queue = List.of(list);
    _currentIndex = index;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final track = currentTrack;
    if (track == null) return;
    _isLoading = true;
    _playerDuration = null;
    notifyListeners();
    try {
      final url = await _backend.resolveStreamUrl(track);
      await _player.setUrl(url);
      await _player.setVolume(_volume);
      _applyLoopMode();
      await _player.play();
    } catch (e) {
      debugPrint('Ошибка воспроизведения: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (currentTrack == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_shuffle) {
      _currentIndex = (_queue.length == 1) ? 0 : _randomIndexExcluding(_currentIndex);
    } else if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else if (_repeatMode == PlayerRepeatMode.all) {
      _currentIndex = 0;
    } else {
      return;
    }
    await _playCurrent();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    // Если прослушали больше 3 секунд — сначала перематываем в начало трека,
    // как это делает Spotify.
    if (_position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == PlayerRepeatMode.all) {
      _currentIndex = _queue.length - 1;
    } else {
      await seek(Duration.zero);
      return;
    }
    await _playCurrent();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void cycleRepeatMode() {
    _repeatMode = PlayerRepeatMode.values[(_repeatMode.index + 1) % PlayerRepeatMode.values.length];
    _applyLoopMode();
    notifyListeners();
  }

  /// Отдаём зацикливание одного трека нативному LoopMode плеера, а не
  /// вручную через seek()+play() в _onTrackCompleted(). Ручной вариант
  /// приводил к гонке: play() мог уйти в just_audio раньше, чем seek(0)
  /// реально откатывал позицию, плеер почти сразу получал новый
  /// ProcessingState.completed и снова вызывал play() — из-за этого
  /// пауза "перебивалась" следующим витком цикла и не срабатывала.
  void _applyLoopMode() {
    _player.setLoopMode(_repeatMode == PlayerRepeatMode.one ? LoopMode.one : LoopMode.off);
  }

  void _onTrackCompleted() {
    // Повтор одного трека теперь обрабатывается нативно через LoopMode.one —
    // ProcessingState.completed в этом режиме вообще не будет приходить.
    if (_repeatMode == PlayerRepeatMode.one) return;
    next();
  }

  int _randomIndexExcluding(int exclude) {
    final rnd = DateTime.now().millisecondsSinceEpoch % _queue.length;
    return rnd == exclude ? (rnd + 1) % _queue.length : rnd;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
