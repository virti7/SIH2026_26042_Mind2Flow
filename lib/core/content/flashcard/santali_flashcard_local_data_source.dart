import 'dart:convert';
import 'package:flutter/services.dart';
import 'santali_flashcard_model.dart';

/// Offline-first bundled reader for Santali visual flashcards.
/// Reads from Flutter rootBundle without network connectivity.
/// Supports both canonical `assets/curriculum/santali/flashcards/`
/// and fallback `assets/prototype_content/flashcards/`.
class SantaliFlashcardLocalDataSource {
  final AssetBundle bundle;

  SantaliFlashcardLocalDataSource({AssetBundle? bundle, String? customRoot})
      : bundle = bundle ?? rootBundle,
        _resolvedRoot = customRoot ?? canonicalRoot;

  static const String canonicalRoot = 'assets/prototype_content/flashcards';

  final String _resolvedRoot;
  String get assetRoot => _resolvedRoot;

  List<CurriculumFlashcard>? _cachedCards;
  List<FlashcardDeck>? _cachedDecks;
  List<FlashcardCategoryMetadata>? _cachedCategories;

  /// Loads and parses the dataset from packaged Flutter assets.
  Future<void> initialize() async {
    if (_cachedCards != null && _cachedDecks != null) return;

    Map<String, dynamic>? assetsJson;
    Map<String, dynamic>? taxonomyJson;

    try {
      final rawAssets = await bundle.loadString('$_resolvedRoot/metadata/assets.json');
      assetsJson = jsonDecode(rawAssets) as Map<String, dynamic>?;

      // Try config/taxonomy.json (canonical dataset layout) first, then fallback to taxonomy.json
      try {
        final rawTax = await bundle.loadString('$_resolvedRoot/config/taxonomy.json');
        taxonomyJson = jsonDecode(rawTax) as Map<String, dynamic>?;
      } catch (_) {
        final rawTax = await bundle.loadString('$_resolvedRoot/taxonomy.json');
        taxonomyJson = jsonDecode(rawTax) as Map<String, dynamic>?;
      }
    } catch (e) {
      throw Exception('Failed to load flashcard curriculum assets from $_resolvedRoot: $e');
    }

    if (assetsJson == null || taxonomyJson == null) {
      throw Exception('Curriculum metadata or taxonomy is empty or invalid.');
    }

    // 2. Parse all flashcard assets
    final rawList = (assetsJson['assets'] as List<dynamic>? ?? const []);
    final cards = <CurriculumFlashcard>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        try {
          cards.add(CurriculumFlashcard.fromJson(item));
        } catch (_) {
          // Gracefully skip corrupted individual record to preserve deck stability
        }
      }
    }
    _cachedCards = cards;

    // 3. Parse taxonomy and construct deck templates
    final categoriesMap = (taxonomyJson['categories'] as Map<String, dynamic>? ?? const {});
    final decks = <FlashcardDeck>[];
    final categories = <FlashcardCategoryMetadata>[];

    for (final catEntry in categoriesMap.entries) {
      final catKey = catEntry.key;
      final catVal = catEntry.value as Map<String, dynamic>;
      final catLabel = (catVal['label'] ?? catKey).toString();

      final categoryDecks = <FlashcardDeck>[];

      if (catVal.containsKey('subcategories') && catVal['subcategories'] is Map) {
        final subMap = catVal['subcategories'] as Map<String, dynamic>;
        for (final subEntry in subMap.entries) {
          final subKey = subEntry.key;
          final subVal = subEntry.value as Map<String, dynamic>;
          final deckId = (subVal['deck'] ?? '${catKey}_$subKey').toString();
          final deckLabel = (subVal['label'] ?? subKey).toString();
          final folder = (subVal['folder'] ?? '$catKey/$subKey').toString();

          final deckCards = cards.where((c) =>
              c.category == catKey && c.subcategory == subKey).toList();

          final deck = FlashcardDeck(
            id: deckId,
            title: deckLabel,
            categoryKey: catKey,
            subcategoryKey: subKey,
            folder: folder,
            cards: deckCards,
          );
          decks.add(deck);
          categoryDecks.add(deck);
        }
      } else {
        final deckId = (catVal['deck'] ?? catKey).toString();
        final folder = (catVal['folder'] ?? catKey).toString();

        final deckCards = cards.where((c) => c.category == catKey).toList();

        final deck = FlashcardDeck(
          id: deckId,
          title: catLabel,
          categoryKey: catKey,
          folder: folder,
          cards: deckCards,
        );
        decks.add(deck);
        categoryDecks.add(deck);
      }

      categories.add(FlashcardCategoryMetadata(
        key: catKey,
        label: catLabel,
        decks: categoryDecks,
      ));
    }

    // Sort decks naturally by deck id prefix (e.g. 01_colours, 02_body_parts, etc.)
    decks.sort((a, b) => a.id.compareTo(b.id));
    _cachedDecks = decks;
    _cachedCategories = categories;
  }

  Future<List<CurriculumFlashcard>> getAllCards() async {
    await initialize();
    return _cachedCards ?? const [];
  }

  Future<List<FlashcardDeck>> getDecks() async {
    await initialize();
    return _cachedDecks ?? const [];
  }

  Future<List<FlashcardCategoryMetadata>> getCategories() async {
    await initialize();
    return _cachedCategories ?? const [];
  }

  Future<FlashcardDeck?> getDeckById(String deckId) async {
    await initialize();
    for (final deck in _cachedDecks ?? const <FlashcardDeck>[]) {
      if (deck.id == deckId) return deck;
    }
    return null;
  }

  Future<CurriculumFlashcard?> getCardById(String cardId) async {
    await initialize();
    for (final card in _cachedCards ?? const <CurriculumFlashcard>[]) {
      if (card.id == cardId) return card;
    }
    return null;
  }
}
