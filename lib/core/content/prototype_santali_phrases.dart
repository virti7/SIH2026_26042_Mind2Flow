/// Manifest model for the offline Santali classroom-audio prototype.
///
/// Source file: `assets/prototype_content/translation/phrases/santali_demo_phrases.json`
/// (bundled asset, never fetched over the network).
///
/// ```json
/// {
///   "id": "open_math_book",
///   "hindi": "अपनी गणित की किताब खोलो।",
///   "santali": "VERIFIED SANTALI TEXT",
///   "audio": "assets/prototype_content/translation/audio/santali/open_math_book.mp3",
///   "topic": "Mathematics",
///   "context": "Classroom instruction",
///   "variants": ["सब अपनी गणित की किताब खोलो"]
/// }
/// ```
///
/// `santali` is filled with the verified translation and the referenced
/// audio file is placed by the teacher; empty `santali` means the entry is
/// not demo-ready yet (never fabricated).
library;

class SantaliDemoPhrase {
  final String id;
  final String hindi;
  final String santali;
  final String audio;
  final String topic;
  final String context;
  final List<String> variants;

  const SantaliDemoPhrase({
    required this.id,
    required this.hindi,
    required this.santali,
    required this.audio,
    required this.topic,
    required this.context,
    this.variants = const [],
  });

  factory SantaliDemoPhrase.fromJson(Map<String, dynamic> json) {
    return SantaliDemoPhrase(
      id: (json['id'] ?? '').toString(),
      hindi: (json['hindi'] ?? '').toString(),
      santali: (json['santali'] ?? '').toString(),
      audio: (json['audio'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      context: (json['context'] ?? '').toString(),
      variants: ((json['variants'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  bool get isValid => id.isNotEmpty && hindi.isNotEmpty && audio.isNotEmpty;

  /// Demo-ready = verified Santali text present (audio presence is checked
  /// separately against the asset bundle at runtime).
  bool get hasVerifiedText => santali.trim().isNotEmpty;
}
