import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Active demo scenario for the Live Classroom Translator prototype.
///
/// The prototype does NOT match recognized Hindi text against anything.
/// After final ASR, the bloc shows the ASR transcript as Hindi and uses the
/// ACTIVE demo below as the Santali output + audio. `activeDemoId` selects
/// which configured scenario is demonstrated — it is explicit configuration,
/// never derived from the spoken sentence.
///
/// Source: `assets/prototype_content/translation/santali_demo_translation.json`
/// ```json
/// {
///   "activeDemoId": "sun_east",
///   "demos": [
///     {
///       "id": "sun_east",
///       "hindi": "सूरज पूरब से निकलता है।",
///       "santali": "VERIFIED_SANTALI_TEXT",
///       "audio": "assets/prototype_content/translation/audio/santali/suraj_purab_se_nikalta_hai.mp3"
///     }
///   ]
/// }

class SantaliDemoScenario {
  final String id;
  final String hindi;
  final String santali;
  final String audio;

  const SantaliDemoScenario({
    required this.id,
    required this.hindi,
    required this.santali,
    required this.audio,
  });

  factory SantaliDemoScenario.fromJson(Map<String, dynamic> json) {
    return SantaliDemoScenario(
      id: (json['id'] ?? '').toString(),
      hindi: (json['hindi'] ?? '').toString(),
      santali: (json['santali'] ?? '').toString(),
      audio: (json['audio'] ?? '').toString(),
    );
  }

  bool get isValid => id.isNotEmpty && audio.isNotEmpty;

  /// Demo-ready = verified Santali text configured (audio presence is
  /// checked separately against the asset bundle at runtime).
  bool get hasVerifiedText => santali.trim().isNotEmpty;
}

/// Loads the demo scenario config from the asset bundle. Zero network use.
class PrototypeDemoTranslationRepository {
  static const configPath =
      'assets/prototype_content/translation/santali_demo_translation.json';

  final AssetBundle bundle;
  final List<SantaliDemoScenario>? seedDemos;
  final String? seedActiveId;
  final Set<String>? availableAssetsOverride;

  List<SantaliDemoScenario>? _demos;
  String? _activeId;
  Set<String>? _availableAssets;

  PrototypeDemoTranslationRepository({
    AssetBundle? bundle,
    this.seedDemos,
    this.seedActiveId,
    this.availableAssetsOverride,
  }) : bundle = bundle ?? rootBundle;

  Future<void> load() async {
    if (_demos != null) return;
    if (seedDemos != null) {
      _demos = seedDemos!.where((d) => d.isValid).toList();
      _activeId = seedActiveId ?? (_demos!.isEmpty ? null : _demos!.first.id);
    } else {
      try {
        final raw = await bundle.loadString(configPath);
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final demos = (decoded['demos'] as List?) ?? const [];
          _demos = demos
              .whereType<Map>()
              .map((e) => SantaliDemoScenario.fromJson(
                  Map<String, dynamic>.from(e)))
              .where((d) => d.isValid)
              .toList();
          final active = (decoded['activeDemoId'] ?? '').toString();
          _activeId = _demos!.any((d) => d.id == active)
              ? active
              : (_demos!.isEmpty ? null : _demos!.first.id);
        } else {
          _demos = const [];
          _activeId = null;
        }
      } catch (e) {
        debugPrint('[LocalSantaliPrototype] demoConfigLoadFailed error=$e');
        _demos = const [];
        _activeId = null;
      }
    }
    _availableAssets = await _readAvailableAssets();
  }

  Future<Set<String>> _readAvailableAssets() async {
    if (availableAssetsOverride != null) {
      return Set<String>.from(availableAssetsOverride!);
    }
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      return manifest
          .listAssets()
          .where((p) =>
              p.startsWith(
                  'assets/prototype_content/translation/audio/santali/') &&
              (p.endsWith('.mp3') || p.endsWith('.wav')))
          .toSet();
    } catch (e) {
      debugPrint('[LocalSantaliPrototype] assetIndexFailed error=$e');
      return const {};
    }
  }

  /// The currently demonstrated scenario, or null when no demo data exists.
  Future<SantaliDemoScenario?> activeDemo() async {
    await load();
    if (_demos == null || _demos!.isEmpty) return null;
    for (final d in _demos!) {
      if (d.id == _activeId) return d;
    }
    return _demos!.first;
  }

  Future<List<SantaliDemoScenario>> allDemos() async {
    await load();
    return List<SantaliDemoScenario>.from(_demos ?? const []);
  }

  /// True when the demo audio asset is bundled (supports .mp3/.wav).
  Future<bool> audioExists(SantaliDemoScenario demo) async {
    await load();
    return _availableAssets!.contains(demo.audio);
  }

  /// Startup check: logs missing demo audio, never crashes.
  Future<List<String>> validateAssets() async {
    await load();
    final missing = <String>[];
    for (final d in _demos ?? const <SantaliDemoScenario>[]) {
      if (d.id == _activeId && !_availableAssets!.contains(d.audio)) {
        missing.add(d.audio);
        debugPrint('[LocalSantaliPrototype] missingAsset=${d.audio} '
            'demoId=${d.id}');
      }
    }
    return missing;
  }
}
