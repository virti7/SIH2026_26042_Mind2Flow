import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/content/santali_audio_player.dart';
import '../../data/smartboard_demo_items.dart';
import '../../data/smartboard_demo_repository.dart';
import '../../data/smartboard_lesson_store.dart';
import '../../models/smartboard_demo_item.dart';
import '../../models/smartboard_item.dart';
import '../../models/smartboard_language.dart';
import '../widgets/smartboard_canvas.dart';

/// MAATRIBHASHA SMARTBOARD — teacher-created classroom board (SIH prototype).
///
/// The Write & Draw board ALWAYS starts blank: the teacher creates all
/// content (strokes, numbers, equations, diagrams) with finger/stylus.
/// Translation RESULT data comes from
/// `assets/prototype_content/smartboard/smartboard_demo.json`
/// via [SmartBoardDemoRepository] — the JSON never paints the input board.
///
/// Prototype flow: teacher writes → Translate → ONE random latency
/// (1500–2150 ms, same mechanism as the Translator prototype) →
/// "Preparing translation..." → exact wait → auto-switch to Santali Board
/// (or in-place populate in Split View) → Ol Chiki + Roman + audio +
/// actual latency badge.
///
/// Preservation rule: the equation line (`5 + 5 = 10`) is stored from ONE
/// shared string and rendered IDENTICALLY on both sides — digits/operators
/// are never altered. Only the number words (five/five/ten) occupy
/// translatable slots.
///
/// Offline only: full-area drawing canvas + bundled Santali audio.
/// No AI handwriting recognition, no ASR, no ONNX, no remote APIs, no TTS.
class SmartBoardScreen extends StatefulWidget {
  const SmartBoardScreen({super.key});

  @override
  State<SmartBoardScreen> createState() => _SmartBoardScreenState();
}

class _SmartBoardScreenState extends State<SmartBoardScreen> {
  // Spec board palette.
  static const _pageBg = Color(0xFFF7F6F1);
  static const _ink = Color(0xFF123B68);
  static const _green = Color(0xFF0B8F61);
  static const _santaliText = Color(0xFF0B2D4F);

  late final SmartBoardCanvasController _canvas;
  late final SmartBoardDemoRepository _demoRepo;
  late final SmartBoardLessonStore _store;
  late final SantaliAudioPlayer _audio;

  int _tab = 0; // 0 = Write & Draw, 1 = Santali Board.
  bool _splitView = false;
  SmartBoardDemoItem? _demo;
  SmartBoardItem? _current;
  bool _loading = true;
  bool _published = false;
  // Prototype translation latency (same mechanism as the Translator
  // prototype): generated ONLY when Translate is pressed, waited exactly
  // once, then displayed as the actual value. Never pre-generated.
  bool _translating = false;
  int _requestId = 0;
  // Actual waited latency per translated item id (badge shows the exact
  // value that was waited for that item — never a second number).
  final Map<String, int> _latencies = {};
  // True only when the JSON-declared audio asset is actually bundled.
  // The JSON path is always kept ready; the button enables itself once the
  // wav is added — no hardcoded paths, no fake asset references.
  bool _audioAvailable = false;

  @override
  void initState() {
    super.initState();
    _canvas = SmartBoardCanvasController();
    _demoRepo = getIt.isRegistered<SmartBoardDemoRepository>()
        ? getIt<SmartBoardDemoRepository>()
        : SmartBoardDemoRepository();
    // Reuse the shared lesson store when available so Today's Board stays
    // consistent; fall back to a local instance otherwise.
    _store = getIt.isRegistered<SmartBoardLessonStore>()
        ? getIt<SmartBoardLessonStore>()
        : SmartBoardLessonStore();
    _audio = getIt.isRegistered<SantaliAudioPlayer>()
        ? getIt<SantaliAudioPlayer>()
        : AudioplayersSantaliAudioPlayer();
    _loadDemo();
  }

  @override
  void dispose() {
    _canvas.dispose();
    super.dispose();
  }

  /// Loads the translation DATA from JSON. The teacher's physical board
  /// always starts blank — nothing here paints the drawing canvas, and no
  /// result item is created until the teacher presses Translate.
  Future<void> _loadDemo() async {
    SmartBoardDemoItem demo;
    try {
      demo = await _demoRepo.loadDemoItem();
    } catch (_) {
      demo = math5Plus5Demo;
    }
    if (!mounted) return;
    // Verify the JSON-declared audio is actually bundled (it is not yet —
    // reported to the user). Never invent or hardcode a different path.
    var audioAvailable = false;
    if (demo.audioPath.trim().isNotEmpty) {
      try {
        await rootBundle.load(demo.audioPath.trim());
        audioAvailable = true;
      } catch (_) {
        audioAvailable = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _demo = demo;
      _audioAvailable = audioAvailable;
      _loading = false;
    });
  }

  /// Builds the result item for one completed teacher translation.
  ///
  /// The equation line is copied verbatim into both the source side and the
  /// Santali sides — digits/operators are never transformed. Only the
  /// number words occupy translatable slots. Each translation gets a unique
  /// item id so Today's Board history keeps distinct entries.
  SmartBoardItem _staticItem(SmartBoardDemoItem demo) {
    return SmartBoardItem(
      id: '${demo.id}_${DateTime.now().millisecondsSinceEpoch}',
      sourceLanguage: SmartBoardSourceLanguage.english,
      sourceText: demo.sourceLines.join('\n'),
      phraseId: demo.id,
      santaliOlChiki:
          '${demo.equationLine}\n${_demoWordLine(demo, olChiki: true)}',
      santaliRoman:
          '${demo.equationLine}\n${_demoWordLine(demo, olChiki: false)}',
      santaliAudio: demo.audioPath,
      createdAt: DateTime.now(),
    );
  }

  /// Word line for storage: verified words where present, empty slots
  /// otherwise (rendered as pending-verification — never hallucinated).
  static String _demoWordLine(SmartBoardDemoItem demo,
      {required bool olChiki}) {
    final five = olChiki ? demo.santaliFiveOlChiki : demo.santaliFiveRoman;
    final ten = olChiki ? demo.santaliTenOlChiki : demo.santaliTenRoman;
    return [five, five, ten].join('   ');
  }

  // ------------------------------------------------------------------ actions

  /// Prototype Translate flow over the teacher-created board:
  /// generate ONE random latency (1500–2150 ms, same mechanism as the
  /// Translator prototype) ONLY on press → show "Preparing translation..."
  /// → wait exactly that long → publish the JSON-backed result item and
  /// auto-switch to Santali Board (or populate the right panel in Split
  /// View). No OCR/AI, no network, no TTS.
  Future<void> _translate() async {
    final demo = _demo;
    if (demo == null || _loading || _translating) return;
    // Already translated for this board — just reveal the result.
    if (_published && _current != null) {
      setState(() {
        if (!_splitView) _tab = 1;
      });
      return;
    }
    // Generated HERE and only here — never on open, draw, or tab switch.
    final latencyMs = Random().nextInt(651) + 1500;
    final request = ++_requestId;
    setState(() {
      _translating = true;
    });
    await Future<void>.delayed(Duration(milliseconds: latencyMs));
    if (!mounted || request != _requestId) return;
    final item = _staticItem(demo);
    _store.add(item);
    _latencies[item.id] = latencyMs;
    setState(() {
      _current = item;
      _translating = false;
      _published = true;
      // CASE A (tab mode): auto-switch. CASE B (split): stay — both panels
      // remain visible and the right panel populates in place.
      if (!_splitView) _tab = 1;
    });
  }

  Future<void> _playSantali(SmartBoardItem item) async {
    if (item.santaliAudio.trim().isEmpty) {
      _snack('Santali audio not yet prepared for this demo.');
      return;
    }
    try {
      await _audio.playAsset(item.santaliAudio);
    } catch (_) {
      if (mounted) _snack('Could not play Santali audio.');
    }
  }

  void _addToLesson(SmartBoardItem item) {
    _store.markAddedToLesson(item.id);
    setState(() {
      _current = item.copyWith(addedToLesson: true);
    });
  }

  void _restore(SmartBoardItem item) {
    setState(() {
      _current = item;
      if (!_splitView) _tab = 1;
    });
  }

  /// Toolbar Clear: confirm first when the board has content.
  Future<void> _confirmClearBoard() async {
    if (!_canvas.hasContent) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear board?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This removes the current drawing. Translated items in '
          "Today's Board are kept.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD94A4A),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _canvas.clear();
  }

  /// New Board starts another item: clears the teacher's drawing and the
  /// current result/translation state, returns to Write & Draw — while
  /// Today's Board history is kept. Any in-flight translation is dropped.
  void _newBoard() {
    _requestId++;
    _canvas.clear();
    setState(() {
      _current = null;
      _published = false;
      _translating = false;
      _tab = 0;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _santaliText),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'MAATRIBHASHA SMARTBOARD',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _santaliText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EF),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: const Color(0xFFB8E0CC), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Offline Ready',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF087A54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // No page-level scroll view: the Write & Draw tab must never scroll,
      // so vertical drags always reach the canvas.
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _buildPrimaryTabs(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _splitView
                  ? _buildSplitView()
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _buildWriteDrawTab(),
                        _buildSantaliTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------- primary tabs

  Widget _buildPrimaryTabs() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFFD9E0E7), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                    child:
                        _primaryTab(label: 'Write & Draw', index: 0)),
                Expanded(
                  child: _primaryTab(
                    label: 'Santali Board',
                    index: 1,
                    done: _current != null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _splitViewToggle(),
      ],
    );
  }

  /// Compact Split View control next to the tabs (never dominant).
  Widget _splitViewToggle() {
    return InkWell(
      onTap: () => setState(() => _splitView = !_splitView),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: _splitView ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _splitView ? _ink : const Color(0xFFD9E0E7),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.splitscreen_rounded,
              size: 18,
              color: _splitView ? Colors.white : _santaliText,
            ),
            const SizedBox(width: 6),
            Text(
              _splitView ? 'Split View ✓' : 'Split View',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _splitView ? Colors.white : _santaliText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryTab({
    required String label,
    required int index,
    bool done = false,
  }) {
    final active = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? _ink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : _santaliText,
              ),
            ),
            if (done) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: active ? Colors.white : _green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------- write & draw
  //
  // Deliberately NOT scrollable: source label, hint, Expanded BLANK white
  // canvas (teacher-created strokes only — never preloaded), toolbar,
  // compact history strip. Drawing gestures can never be stolen by a
  // scroll view.

  Widget _buildWriteDrawTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSourceLabel(),
          _buildBoardHint(),
          const SizedBox(height: 8),
          Expanded(
            child: _buildBlankBoard(),
          ),
          if (_translating) ...[
            const SizedBox(height: 8),
            _preparingBanner(),
          ],
          const SizedBox(height: 8),
          _buildBoardToolbar(),
          const SizedBox(height: 8),
          _buildTodayBoardStrip(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- split view
  //
  // ONE shared drawing state: the left panel owns the single canvas
  // (controller lives in this State, so toggling Split View never erases
  // the teacher's strokes). The right panel only renders translation data.

  Widget _buildSplitView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT — teacher's actual board + write tools.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSourceLabel(),
                _buildBoardHint(),
                const SizedBox(height: 8),
                Expanded(child: _buildBlankBoard()),
                if (_translating) ...[
                  const SizedBox(height: 8),
                  _preparingBanner(),
                ],
                const SizedBox(height: 8),
                _buildBoardToolbar(),
              ],
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFD9E0E7),
          ),
          // RIGHT — Santali translation board.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSplitRightHeader(),
                const SizedBox(height: 8),
                Expanded(child: _buildSplitRightBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitRightHeader() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E0E7), width: 1),
      ),
      child: Text(
        'Santali Board',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _santaliText,
        ),
      ),
    );
  }

  Widget _buildSplitRightBody() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E0E7), width: 1),
      ),
      child: SingleChildScrollView(
        child: _santaliPanelContent(),
      ),
    );
  }

  /// Small caption OUTSIDE the canvas (never inside the drawing surface,
  /// so it cannot be mistaken for teacher content). Hidden once the
  /// teacher has drawn something.
  Widget _buildBoardHint() {
    return AnimatedBuilder(
      animation: _canvas,
      builder: (context, _) {
        if (_canvas.hasContent || _loading) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Write or draw here',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8291A5),
            ),
          ),
        );
      },
    );
  }

  /// Status shown while the generated latency elapses. No result, no
  /// latency value, no audio — the teacher's board stays intact.
  Widget _preparingBanner() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E0E7), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 10),
          Text(
            'Preparing translation...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _santaliText,
            ),
          ),
        ],
      ),
    );
  }

  /// Fixed source indicator for the static math demo (no selector).
  Widget _buildSourceLabel() {
    return Row(
      children: [
        Text(
          'Source: English',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _santaliText,
          ),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB8E0CC), width: 1),
          ),
          child: Text(
            'Output: Santali',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF087A54),
            ),
          ),
        ),
        IconButton(
          tooltip: 'New Board',
          onPressed: _newBoard,
          icon: const Icon(Icons.add_rounded, color: _santaliText),
        ),
      ],
    );
  }

  /// Blank classroom board: white, teacher-created strokes only.
  /// Nothing is ever preloaded here — no equation, no phrase, no drawing.
  /// The JSON supplies translation RESULT data only; it never paints this
  /// canvas. The canvas itself is unchanged (full-size, finger/stylus
  /// friendly, non-clipping).
  Widget _buildBlankBoard() {
    return SmartBoardCanvas(controller: _canvas);
  }

  /// Bottom toolbar: Pen / Highlighter / Eraser + Undo / Redo / Clear,
  /// with Translate pinned right. All touch targets ≥ 48px.
  Widget _buildBoardToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E0E7), width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _canvas,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toolButton(
                    label: 'Pen',
                    icon: Icons.edit_rounded,
                    tool: SmartBoardTool.pen,
                  ),
                  _toolButton(
                    label: 'Highlighter',
                    icon: Icons.highlight_rounded,
                    tool: SmartBoardTool.highlighter,
                  ),
                  _toolButton(
                    label: 'Eraser',
                    icon: Icons.cleaning_services_rounded,
                    tool: SmartBoardTool.eraser,
                  ),
                  const SizedBox(width: 6),
                  _iconToolButton(
                    tooltip: 'Undo',
                    icon: Icons.undo_rounded,
                    enabled: _canvas.canUndo,
                    onTap: _canvas.undo,
                  ),
                  _iconToolButton(
                    tooltip: 'Redo',
                    icon: Icons.redo_rounded,
                    enabled: _canvas.canRedo,
                    onTap: _canvas.redo,
                  ),
                  _iconToolButton(
                    tooltip: 'Clear',
                    icon: Icons.delete_outline_rounded,
                    enabled: _canvas.hasContent,
                    onTap: _confirmClearBoard,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed:
                  (_loading || _translating) ? null : _translate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Translate →',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton({
    required String label,
    required IconData icon,
    required SmartBoardTool tool,
  }) {
    final active = _canvas.tool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _canvas.setTool(tool),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: active ? _ink : _pageBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? _ink : const Color(0xFFD9E0E7),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? Colors.white : _santaliText),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _santaliText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconToolButton({
    required String tooltip,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      iconSize: 22,
      color: _santaliText,
      disabledColor: const Color(0xFFB6C0CC),
      icon: Icon(icon),
    );
  }

  /// Compact horizontal "Today's Board" strip (fixed height — no vertical
  /// scroll, so drawing gestures stay safe).
  Widget _buildTodayBoardStrip() {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final items = _store.items;
        return Container(
          height: 92,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9E0E7), width: 1),
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's\nBoard",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _santaliText,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '${items.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF087A54),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: items.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Translated lines will appear here.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        itemBuilder: (context, i) =>
                            _historyStripCard(i + 1, items[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _historyStripCard(int number, SmartBoardItem item) {
    final selected = _current?.id == item.id;
    final preview = item.sourceText.split('\n').first;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _restore(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 210,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F5EF) : _pageBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB8E0CC)
                  : const Color(0xFFD9E0E7),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '$number.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _santaliText,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _santaliText,
                      ),
                    ),
                    Text(
                      'Santali${item.addedToLesson ? ' • In lesson' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _playSantali(item),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.volume_up_outlined,
                    color: _green,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- santali board
  //
  // This tab has no canvas, so vertical scrolling here is safe. The result
  // appears ONLY after the teacher presses Translate and the generated
  // latency elapses — never pre-existing, never premature.

  Widget _buildSantaliTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSourceOutputIndicator(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFFD9E0E7), width: 1),
            ),
            child: _santaliPanelContent(),
          ),
          const SizedBox(height: 18),
          _buildTodayBoard(),
        ],
      ),
    );
  }

  /// Shared Santali panel body (tab mode + split-view right panel):
  /// loading → preparing (no result, no latency value) → waiting (no
  /// translation yet) → result with the ACTUAL generated latency.
  Widget _santaliPanelContent() {
    if (_loading || _demo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_translating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 12),
          Text(
            _current == null
                ? 'Waiting for translation...'
                : 'Preparing translation...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _santaliText,
            ),
          ),
        ],
      );
    }
    final item = _current;
    if (item == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.translate_rounded,
            size: 40,
            color: Color(0xFFB6C0CC),
          ),
          const SizedBox(height: 12),
          Text(
            'Waiting for translation...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _santaliText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Write on the board, then tap Translate →',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      );
    }
    return _demoResult(item);
  }

  /// Fixed source/output indicator for the static demo. Display only.
  Widget _buildSourceOutputIndicator() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E0E7), width: 1),
      ),
      child: Row(
        children: [
          _ioLabel('SOURCE', 'English'),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded,
              size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          _ioLabel('OUTPUT', 'Santali'),
        ],
      ),
    );
  }

  Widget _ioLabel(String caption, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$caption ',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _santaliText,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------- static demo result
  //
  // The equation line is rendered from ONE shared string on both sides, so
  // digits/operators stay visually identical by construction. Only the
  // number words occupy translatable slots.

  Widget _demoResult(SmartBoardItem item) {
    final demo = _demo ?? math5Plus5Demo;
    final added = item.addedToLesson;
    // Exact waited latency for THIS item (badge only — never a range,
    // never a second number, never shown while preparing).
    final itemLatency = _latencies[item.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _boardLabel('ORIGINAL'),
        const SizedBox(height: 6),
        _equationText(demo.equationLine),
        const SizedBox(height: 4),
        _wordsSourceText(demo),
        const SizedBox(height: 20),
        _boardLabel('SANTALI — OL CHIKI'),
        const SizedBox(height: 8),
        // Equation preserved byte-for-byte: same string as ORIGINAL.
        _equationText(demo.equationLine),
        const SizedBox(height: 10),
        _wordSlotsRow(demo, olChiki: true),
        const SizedBox(height: 16),
        _boardLabel('ROMAN SANTALI'),
        const SizedBox(height: 8),
        // Equation preserved byte-for-byte: same string as ORIGINAL.
        _equationText(demo.equationLine),
        const SizedBox(height: 10),
        _wordSlotsRow(demo, olChiki: false),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              // Audio path comes from smartboard_demo.json (never
              // hardcoded); enabled only while the file is bundled.
              onPressed:
                  _audioAvailable ? () => _playSantali(item) : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                'Play Santali',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD9E0E7),
                disabledForegroundColor: const Color(0xFF8291A5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
            ElevatedButton.icon(
              onPressed: added ? null : () => _addToLesson(item),
              icon: Icon(
                added ? Icons.check_circle_rounded : Icons.add_rounded,
                size: 22,
              ),
              label: Text(
                added ? "Added to Today's Lesson" : '+ Add to Lesson',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: added ? _ink : Colors.white,
                foregroundColor: added ? Colors.white : _ink,
                disabledBackgroundColor: _ink,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: added
                      ? BorderSide.none
                      : const BorderSide(color: _ink, width: 1.5),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        if (!_audioAvailable) ...[
          const SizedBox(height: 8),
          Text(
            'Santali audio not yet prepared for this demo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
        // Actual generated latency ONLY — shown after the result is
        // visible, using the exact value that was waited for THIS item.
        // Never a range, never a second number, never shown while preparing.
        if (itemLatency != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: const Color(0xFFB8E0CC), width: 1),
              ),
              child: Text(
                '⚡ ${(itemLatency / 1000).toStringAsFixed(2)}s',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF087A54),
                ),
              ),
            ),
          ),
        ],
        if (added) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: _green),
              const SizedBox(width: 6),
              Text(
                "✓ Added to Today's Lesson",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Equation line, identical widget on ORIGINAL and SANTALI sides.
  Widget _equationText(String equation) {
    return Text(
      equation,
      style: GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: _santaliText,
        height: 1.4,
      ),
    );
  }

  Widget _wordsSourceText(SmartBoardDemoItem demo) {
    return Text(
      demo.numberWords.join('   '),
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: _santaliText,
        height: 1.4,
      ),
    );
  }

  /// Translated word slots in visual order: five, five, ten.
  /// Empty slots render as pending-verification — never invented words.
  Widget _wordSlotsRow(SmartBoardDemoItem demo, {required bool olChiki}) {
    final slots = [
      _WordSlot(
          english: 'five',
          olChiki: olChiki,
          word: olChiki
              ? demo.santaliFiveOlChiki
              : demo.santaliFiveRoman),
      _WordSlot(
          english: 'five',
          olChiki: olChiki,
          word: olChiki
              ? demo.santaliFiveOlChiki
              : demo.santaliFiveRoman),
      _WordSlot(
          english: 'ten',
          olChiki: olChiki,
          word:
              olChiki ? demo.santaliTenOlChiki : demo.santaliTenRoman),
    ];
    return Wrap(
      spacing: 28,
      runSpacing: 12,
      children: slots.map(_wordSlot).toList(),
    );
  }

  Widget _wordSlot(_WordSlot slot) {
    if (slot.word.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '···',
            style: GoogleFonts.poppins(
              fontSize: slot.olChiki ? 30 : 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB6C0CC),
              height: 1.4,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: const Color(0xFFFCD34D), width: 1),
            ),
            child: Text(
              "'${slot.english}' — pending verification",
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      slot.word,
      style: GoogleFonts.poppins(
        fontSize: slot.olChiki ? 30 : 22,
        fontWeight: FontWeight.w700,
        fontStyle: slot.olChiki ? FontStyle.normal : FontStyle.italic,
        color: slot.olChiki ? _santaliText : const Color(0xFF087A54),
        height: 1.4,
      ),
    );
  }

  Widget _boardLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: const Color(0xFF64748B),
      ),
    );
  }

  // ---------------------------------------------------------- today's board

  Widget _buildTodayBoard() {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final items = _store.items;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD9E0E7), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Today's Board",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _santaliText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${items.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF087A54),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                Text(
                  'Nothing on the board yet — tap Translate → to publish the demo.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                )
              else
                ...items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return _historyRow(i + 1, item);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _historyRow(int number, SmartBoardItem item) {
    final selected = _current?.id == item.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _restore(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F5EF) : _pageBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB8E0CC)
                  : const Color(0xFFD9E0E7),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '$number.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _santaliText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.sourceText.split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _santaliText,
                      ),
                    ),
                    Text(
                      'Santali${item.addedToLesson ? ' • In today\'s lesson' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Play Santali',
                onPressed: () => _playSantali(item),
                icon: const Icon(
                  Icons.volume_up_outlined,
                  color: _green,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translatable number-word slot for the static math demo.
class _WordSlot {
  final String english;
  final bool olChiki;
  final String word;

  const _WordSlot({
    required this.english,
    required this.olChiki,
    required this.word,
  });
}
