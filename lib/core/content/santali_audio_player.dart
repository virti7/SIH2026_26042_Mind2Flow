import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Playback failure surfaced to the translator flow (teacher sees a friendly
/// message; technical detail stays in debug logs).
class SantaliAudioPlaybackFailure implements Exception {
  final String message;
  const SantaliAudioPlaybackFailure(this.message);
  @override
  String toString() => 'SantaliAudioPlaybackFailure: $message';
}

/// Minimal playback contract for local Santali prototype audio.
///
/// Only ONE clip plays at a time: starting a new phrase always stops the
/// previous one first (no overlap in the classroom).
abstract class SantaliAudioPlayer {
  /// Plays a bundled asset (e.g.
  /// `assets/prototype_content/translation/audio/santali/open_math_book.mp3`).
  /// Stops any currently playing clip first.
  Future<void> playAsset(String assetPath);

  /// Replays the last played asset without any network/translation call.
  Future<void> replay();

  Future<void> stop();

  /// Preloads the small demo set for fast first playback. Only the
  /// presentation set — never bulk-preloads large libraries.
  Future<void> preload(List<String> assetPaths);

  String? get lastAssetPath;
}

/// audioplayers-backed implementation (local assets only, zero network).
class AudioplayersSantaliAudioPlayer implements SantaliAudioPlayer {
  final AudioPlayer _player;
  String? _lastAsset;

  AudioplayersSantaliAudioPlayer({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  /// audioplayers `AssetSource` wants the path WITHOUT the `assets/` prefix.
  static String toAssetSourcePath(String assetPath) {
    const prefix = 'assets/';
    if (assetPath.startsWith(prefix)) {
      return assetPath.substring(prefix.length);
    }
    return assetPath;
  }

  @override
  String? get lastAssetPath => _lastAsset;

  @override
  Future<void> playAsset(String assetPath) async {
    try {
      // No overlap: stop the previous classroom clip before the new one.
      try {
        await _player.stop();
      } catch (_) {}
      _lastAsset = assetPath;
      await _player.play(AssetSource(toAssetSourcePath(assetPath)));
    } catch (e) {
      debugPrint('[LocalSantaliPrototype] playbackFailed asset=$assetPath '
          'error=$e');
      throw SantaliAudioPlaybackFailure('Could not play Santali audio.');
    }
  }

  @override
  Future<void> replay() async {
    final asset = _lastAsset;
    if (asset == null) {
      throw const SantaliAudioPlaybackFailure(
          'Audio unavailable for this phrase.');
    }
    await playAsset(asset);
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> preload(List<String> assetPaths) async {
    try {
      final cache = AudioCache();
      await cache.loadAll(
          assetPaths.map(toAssetSourcePath).toList());
      debugPrint('[LocalSantaliPrototype] preloaded count=${assetPaths.length}');
    } catch (e) {
      // Preload is best-effort; on-demand play still works.
      debugPrint('[LocalSantaliPrototype] preloadFailed error=$e');
    }
  }
}

/// No-op player for widget/unit tests (records calls, plays nothing).
class NoopSantaliAudioPlayer implements SantaliAudioPlayer {
  final List<String> playLog = [];
  int stopCount = 0;
  String? _last;

  @override
  String? get lastAssetPath => _last;

  @override
  Future<void> playAsset(String assetPath) async {
    stopCount++;
    playLog.add(assetPath);
    _last = assetPath;
  }

  @override
  Future<void> replay() async {
    final asset = _last;
    if (asset == null) {
      throw const SantaliAudioPlaybackFailure(
          'Audio unavailable for this phrase.');
    }
    await playAsset(asset);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> preload(List<String> assetPaths) async {}
}
