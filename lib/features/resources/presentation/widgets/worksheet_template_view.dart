import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/worksheet_template/worksheet_template.dart';

Color _hex(dynamic v, [Color fallback = Colors.black]) {
  final h = (v ?? '').toString().replaceAll('#', '').trim();
  if (h.length != 6) return fallback;
  final n = int.tryParse('FF$h', radix: 16);
  return n == null ? fallback : Color(n);
}

/// Colours for one render mode, read from the template's `themes`.
class _Theme {
  final Map<String, dynamic> m;
  final bool print;
  _Theme(this.m, this.print);

  Color c(String key, [Color fallback = Colors.black]) => _hex(m[key], fallback);
  Color get ink => c('ink');
  Color get muted => c('muted', Colors.black54);
  Color get accent => c('accent');
  Color get tileBg => c('tile_bg', Colors.white);
  Color get correct => c('correct', Colors.green);
  Color get wrong => c('wrong', Colors.red);

  Map<String, dynamic> block(int i) {
    final list = (m['blocks'] as List?) ?? const [];
    if (list.isEmpty) return const {};
    return Map<String, dynamic>.from(list[i % list.length] as Map);
  }

  List<Color> get blobs =>
      ((m['header_blobs'] as List?) ?? const []).map((e) => _hex(e)).toList();
}

/// Renders a [WorksheetDocument] with a [WorksheetTemplate].
///
/// - Colourful mode (default): interactive — pick options, type blanks,
///   draw matches, trace numbers, and check answers.
/// - [printMode]: the same layout in black & white with empty answer
///   spaces, for paper.
class WorksheetTemplateView extends StatelessWidget {
  final WorksheetTemplate template;
  final WorksheetDocument document;
  final bool printMode;

  const WorksheetTemplateView({
    super.key,
    required this.template,
    required this.document,
    this.printMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _Theme(template.theme(printMode ? 'print' : 'colorful'), printMode);
    final ctx = _Ctx(template, document, theme, interactive: !printMode);
    return Container(
      color: theme.c('page_bg', Colors.white),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(builder: (context, box) {
        final twoCol = box.maxWidth >= template.twoColumnMinWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(ctx),
            const SizedBox(height: 12),
            _InfoCard(ctx),
            const SizedBox(height: 12),
            ..._blockRows(ctx, twoCol),
            _Footer(ctx),
          ],
        );
      }),
    );
  }

  List<Widget> _blockRows(_Ctx ctx, bool twoCol) {
    final rows = <Widget>[];
    final blocks = document.blocks;
    var i = 0;
    while (i < blocks.length) {
      final full = !twoCol || template.spanOf(blocks[i].kind) > 1;
      final nextFits = !full &&
          i + 1 < blocks.length &&
          template.spanOf(blocks[i + 1].kind) == 1;
      if (nextFits) {
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _BlockCard(ctx, i, blocks[i])),
              const SizedBox(width: 12),
              Expanded(child: _BlockCard(ctx, i + 1, blocks[i + 1])),
            ],
          ),
        ));
        i += 2;
      } else {
        rows.add(_BlockCard(ctx, i, blocks[i]));
        i += 1;
      }
      rows.add(const SizedBox(height: 12));
    }
    return rows;
  }
}

class _Ctx {
  final WorksheetTemplate template;
  final WorksheetDocument doc;
  final _Theme theme;
  final bool interactive;
  _Ctx(this.template, this.doc, this.theme, {required this.interactive});

  /// Language display order: source, English, target, then anything else.
  List<String> ordered(Map<String, String> m) {
    final order = <String>[doc.language1, 'en', doc.language2, ...m.keys];
    final seen = <String>{};
    final out = <String>[];
    for (final k in order) {
      if (k.isEmpty || !seen.add(k)) continue;
      final v = m[k];
      if (v != null && v.isNotEmpty && !out.contains(v)) out.add(v);
    }
    return out;
  }

  String firstLabel(String key) {
    final l = ordered(template.label(key));
    return l.isEmpty ? key : l.join(' / ');
  }

  TextStyle get base => AppTypography.bodySmall.copyWith(color: theme.ink);

  /// Stacked multilingual lines: first bold, second regular, rest accent.
  Widget lines(Map<String, String> m,
      {double size = 15, TextAlign align = TextAlign.start, bool fill = false}) {
    final texts = ordered(m).map((t) => fill ? doc.fill(t) : t).toList();
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < texts.length; i++)
          Text(texts[i],
              textAlign: align,
              style: base.copyWith(
                fontSize: i == 0 ? size : size - 2,
                fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                color: i >= 2 ? theme.accent : theme.ink,
              )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header, student info, footer
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final _Ctx ctx;
  const _Header(this.ctx);

  @override
  Widget build(BuildContext context) {
    final t = ctx.theme;
    final styles = {
      'title': ctx.base.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
      'subtitle': ctx.base.copyWith(fontSize: 16, color: t.muted),
      'heading': ctx.base.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
      'heading_accent': ctx.base
          .copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: t.accent),
    };
    final lines = <Widget>[];
    for (final raw in (ctx.template.header['lines'] as List?) ?? const []) {
      final line = Map<String, dynamic>.from(raw as Map);
      final text = ctx.doc
          .fill((line['text'] ?? '').toString())
          .trim()
          .replaceAll(RegExp(r'\s*·\s*$'), '');
      if (text.isEmpty) continue;
      lines.add(Text(text,
          textAlign: TextAlign.center,
          style: styles[line['style']] ?? ctx.base));
    }
    final blobs = t.blobs;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.c('header_bg', Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: t.print ? Border.all(color: t.ink, width: 1.2) : null,
      ),
      child: Stack(
        children: [
          if (blobs.isNotEmpty)
            Positioned(left: -40, top: -40, child: _blob(blobs.first)),
          if (blobs.length > 1)
            Positioned(right: -40, top: -40, child: _blob(blobs[1])),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: lines),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color c) => Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _InfoCard extends StatelessWidget {
  final _Ctx ctx;
  const _InfoCard(this.ctx);

  @override
  Widget build(BuildContext context) {
    final info = ctx.template.studentInfo;
    List<Widget> column(String side) => [
          for (final raw in (info[side] as List?) ?? const [])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Field(ctx, Map<String, dynamic>.from(raw as Map)),
            ),
        ];
    return _Panel(
      ctx,
      bg: ctx.theme.c('info_bg', Colors.white),
      border: ctx.theme.c('info_border'),
      child: _TwoSides(left: column('left'), right: column('right')),
    );
  }
}

class _Footer extends StatelessWidget {
  final _Ctx ctx;
  const _Footer(this.ctx);

  @override
  Widget build(BuildContext context) {
    final f = ctx.template.footer;
    Map<String, dynamic> side(String k) =>
        f[k] is Map ? Map<String, dynamic>.from(f[k] as Map) : {};
    return _Panel(
      ctx,
      bg: ctx.theme.c('footer_bg', Colors.white),
      border: ctx.theme.c('footer_border'),
      child: _TwoSides(
        left: [_Field(ctx, side('left'))],
        right: [_Field(ctx, side('right'))],
      ),
    );
  }
}

class _TwoSides extends StatelessWidget {
  final List<Widget> left;
  final List<Widget> right;
  const _TwoSides({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      if (box.maxWidth < 420) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...left, ...right]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 3,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: left)),
          const SizedBox(width: 20),
          Expanded(
              flex: 2,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: right)),
        ],
      );
    });
  }
}

/// A multilingual label with a dotted blank line, a date blank or values.
class _Field extends StatelessWidget {
  final _Ctx ctx;
  final Map<String, dynamic> field;
  const _Field(this.ctx, this.field);

  @override
  Widget build(BuildContext context) {
    final labels = ctx.ordered(stringMap(field['labels']));
    final values = ctx.ordered(stringMap(field['values'])).map(ctx.doc.fill).toList();
    final dateBlank = (field['date_blank'] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < labels.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(labels[i],
                    style: ctx.base.copyWith(
                        fontSize: 13,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400)),
              ),
              const SizedBox(width: 8),
              if (field['blank'] == true)
                Expanded(child: _DottedLine(color: ctx.theme.muted))
              else if (dateBlank.isNotEmpty)
                Flexible(
                    child: Text(dateBlank,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: ctx.base.copyWith(fontSize: 13)))
              else if (i < values.length)
                Flexible(
                    child: Text(values[i],
                        style: ctx.base.copyWith(
                            fontSize: 13,
                            fontWeight:
                                i == 0 ? FontWeight.w700 : FontWeight.w400))),
            ],
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final _Ctx ctx;
  final Color bg;
  final Color border;
  final Widget child;
  const _Panel(this.ctx,
      {required this.bg, required this.border, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: ctx.theme.print ? 1.2 : 1.4),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Blocks
// ---------------------------------------------------------------------------

class _BlockCard extends StatelessWidget {
  final _Ctx ctx;
  final int index;
  final WorksheetBlock block;
  const _BlockCard(this.ctx, this.index, this.block);

  @override
  Widget build(BuildContext context) {
    final style = ctx.theme.block(index);
    final badge = _hex(style['badge'], Colors.black);
    final outlined = style['badge_outline'] == true;
    final heading = ctx.template.blockHeadings[block.kind];
    final prompt = block.prompt.isNotEmpty ? block.prompt : stringMap(heading);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _hex(style['bg'], Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _hex(style['border'], Colors.black),
            width: ctx.theme.print ? 1.2 : 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: outlined ? Colors.white : badge,
                  shape: BoxShape.circle,
                  border: outlined
                      ? Border.all(color: ctx.theme.ink, width: 2)
                      : null,
                ),
                child: Text('${index + 1}',
                    style: ctx.base.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: outlined ? ctx.theme.ink : Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(child: ctx.lines(prompt, size: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _body(badge),
        ],
      ),
    );
  }

  Widget _body(Color accent) {
    final key = ValueKey('${index}_${block.kind}');
    switch (block.kind) {
      case 'mcq':
        return _McqBody(key: key, ctx: ctx, block: block, accent: accent);
      case 'fill_blank':
        return _FillBlankBody(key: key, ctx: ctx, block: block, accent: accent);
      case 'order_match':
        final slots = block.slots;
        final answer = block.orderAnswer;
        return _MatchBody(
          key: key,
          ctx: ctx,
          accent: accent,
          left: [for (final s in slots) ctx.lines(s, size: 14, align: TextAlign.center)],
          right: block.values,
          isCorrect: (l, r) =>
              l < answer.length && answer[l] == block.values[r],
        );
      case 'match_pairs':
        final ans = block.pairAnswer;
        return _MatchBody(
          key: key,
          ctx: ctx,
          accent: accent,
          left: [
            for (final l in block.left)
              Text(l,
                  textAlign: TextAlign.center,
                  style: ctx.base.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
          ],
          right: block.right,
          isCorrect: (l, r) => ans[block.left[l]] == block.right[r],
        );
      case 'trace':
        return _TraceBody(key: key, ctx: ctx, block: block, accent: accent);
      default:
        return _WriteBody(key: key, ctx: ctx, block: block, accent: accent);
    }
  }
}

/// Check / Reset buttons plus the result message (interactive mode only).
class _CheckRow extends StatelessWidget {
  final _Ctx ctx;
  final bool? result;
  final VoidCallback onCheck;
  final VoidCallback onReset;
  const _CheckRow(this.ctx,
      {required this.result, required this.onCheck, required this.onReset});

  @override
  Widget build(BuildContext context) {
    if (!ctx.interactive) return const SizedBox.shrink();
    final t = ctx.theme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.tonalIcon(
            onPressed: onCheck,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(ctx.firstLabel('check')),
          ),
          TextButton(onPressed: onReset, child: Text(ctx.firstLabel('reset'))),
          if (result != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(result! ? Icons.celebration_rounded : Icons.refresh_rounded,
                    size: 18, color: result! ? t.correct : t.wrong),
                const SizedBox(width: 4),
                Text(ctx.firstLabel(result! ? 'correct' : 'try_again'),
                    style: ctx.base.copyWith(
                        color: result! ? t.correct : t.wrong,
                        fontWeight: FontWeight.w700)),
              ],
            ),
        ],
      ),
    );
  }
}

Widget _tile(_Ctx ctx,
    {required Widget child,
    Color? border,
    double borderWidth = 1.2,
    Color? fill,
    VoidCallback? onTap,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12)}) {
  return Material(
    color: fill ?? ctx.theme.tileBg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
          color: border ?? (ctx.theme.print ? ctx.theme.ink : const Color(0xFFE3D9CC)),
          width: borderWidth),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: ctx.interactive ? onTap : null,
      child: Padding(padding: padding, child: child),
    ),
  );
}

// ---- Multiple choice -------------------------------------------------------

class _McqBody extends StatefulWidget {
  final _Ctx ctx;
  final WorksheetBlock block;
  final Color accent;
  const _McqBody(
      {super.key, required this.ctx, required this.block, required this.accent});

  @override
  State<_McqBody> createState() => _McqBodyState();
}

class _McqBodyState extends State<_McqBody> {
  int? _selected;
  bool? _result;

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final options = widget.block.options;
    final visual = widget.block.visual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visual.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(visual,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 4)),
          ),
        // Two options per row (plain Rows: this sits inside IntrinsicHeight).
        for (var i = 0; i < options.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < options.length ? 10 : 0),
            child: Row(
              children: [
                Expanded(child: _option(i, options[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < options.length
                      ? _option(i + 1, options[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        _CheckRow(ctx,
            result: _result,
            onCheck: () => setState(() => _result = _selected != null &&
                options[_selected!] == widget.block.answer),
            onReset: () => setState(() {
                  _selected = null;
                  _result = null;
                })),
      ],
    );
  }

  Widget _option(int i, String text) {
    final ctx = widget.ctx;
    final selected = _selected == i;
    Color? border;
    if (selected) {
      border = _result == null
          ? widget.accent
          : (_result! ? ctx.theme.correct : ctx.theme.wrong);
    }
    return _tile(
      ctx,
      border: border,
      borderWidth: selected ? 2.2 : 1.2,
      onTap: () => setState(() {
        _selected = i;
        _result = null;
      }),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ctx.theme.ink, width: 1.6),
            ),
            alignment: Alignment.center,
            child: selected
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: border ?? widget.accent, shape: BoxShape.circle))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: ctx.base.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ---- Fill in the blank -----------------------------------------------------

class _FillBlankBody extends StatefulWidget {
  final _Ctx ctx;
  final WorksheetBlock block;
  final Color accent;
  const _FillBlankBody(
      {super.key, required this.ctx, required this.block, required this.accent});

  @override
  State<_FillBlankBody> createState() => _FillBlankBodyState();
}

class _FillBlankBodyState extends State<_FillBlankBody> {
  late final List<TextEditingController> _inputs = List.generate(
      widget.block.sequence.where((s) => s == null).length,
      (_) => TextEditingController());
  bool? _result;

  @override
  void dispose() {
    for (final c in _inputs) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final seq = widget.block.sequence;
    final big = ctx.base.copyWith(fontSize: 34, fontWeight: FontWeight.w800);
    var blank = 0;
    final parts = <Widget>[];
    for (var i = 0; i < seq.length; i++) {
      if (i > 0) parts.add(Text(',', style: big));
      if (seq[i] != null) {
        parts.add(Text(seq[i]!, style: big));
      } else {
        final idx = blank++;
        parts.add(_blankBox(idx, big));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tile(
          ctx,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (final p in parts)
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: p),
              ],
            ),
          ),
        ),
        _CheckRow(ctx,
            result: _result,
            onCheck: () {
              final answers = widget.block.answers;
              var ok = answers.length == _inputs.length;
              for (var i = 0; ok && i < _inputs.length; i++) {
                ok = _inputs[i].text.trim() == answers[i];
              }
              setState(() => _result = ok);
            },
            onReset: () => setState(() {
                  for (final c in _inputs) {
                    c.clear();
                  }
                  _result = null;
                })),
      ],
    );
  }

  Widget _blankBox(int idx, TextStyle big) {
    final ctx = widget.ctx;
    final color = _result == null
        ? widget.accent
        : (_result! ? ctx.theme.correct : ctx.theme.wrong);
    return CustomPaint(
      painter: _DashedRectPainter(color: ctx.theme.print ? ctx.theme.ink : color),
      child: SizedBox(
        width: 96,
        height: 72,
        child: ctx.interactive
            ? Center(
                child: TextField(
                  controller: _inputs[idx],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: big.copyWith(color: color),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isCollapsed: true,
                  ),
                  onChanged: (_) {
                    if (_result != null) setState(() => _result = null);
                  },
                ),
              )
            : null,
      ),
    );
  }
}

// ---- Written answer --------------------------------------------------------

class _WriteBody extends StatefulWidget {
  final _Ctx ctx;
  final WorksheetBlock block;
  final Color accent;
  const _WriteBody(
      {super.key, required this.ctx, required this.block, required this.accent});

  @override
  State<_WriteBody> createState() => _WriteBodyState();
}

class _WriteBodyState extends State<_WriteBody> {
  final TextEditingController _input = TextEditingController();
  bool? _result;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final visual = widget.block.visual;
    final answer = widget.block.answer;
    final color = _result == null
        ? widget.accent
        : (_result! ? ctx.theme.correct : ctx.theme.wrong);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visual.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(visual,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 4)),
          ),
        CustomPaint(
          painter: _DashedRectPainter(color: ctx.theme.print ? ctx.theme.ink : color),
          child: SizedBox(
            height: 60,
            child: ctx.interactive
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: TextField(
                        controller: _input,
                        style: ctx.base.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: color),
                        decoration: InputDecoration(
                          hintText: ctx.firstLabel('answer_hint'),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isCollapsed: true,
                        ),
                        onChanged: (_) {
                          if (_result != null) setState(() => _result = null);
                        },
                      ),
                    ),
                  )
                : null,
          ),
        ),
        if (answer.isNotEmpty)
          _CheckRow(ctx,
              result: _result,
              onCheck: () => setState(() => _result =
                  _input.text.trim().toLowerCase() == answer.toLowerCase()),
              onReset: () => setState(() {
                    _input.clear();
                    _result = null;
                  })),
      ],
    );
  }
}

// ---- Matching (order + pairs) ----------------------------------------------

class _MatchBody extends StatefulWidget {
  final _Ctx ctx;
  final Color accent;
  final List<Widget> left;
  final List<String> right;
  final bool Function(int left, int right) isCorrect;

  const _MatchBody({
    super.key,
    required this.ctx,
    required this.accent,
    required this.left,
    required this.right,
    required this.isCorrect,
  });

  @override
  State<_MatchBody> createState() => _MatchBodyState();
}

class _MatchBodyState extends State<_MatchBody> {
  final GlobalKey _paintKey = GlobalKey();
  late final List<GlobalKey> _leftDots =
      List.generate(widget.left.length, (_) => GlobalKey());
  late final List<GlobalKey> _rightDots =
      List.generate(widget.right.length, (_) => GlobalKey());
  final Map<int, int> _links = {};
  int? _pendingLeft;
  bool? _result;
  bool _checked = false;

  void _tapLeft(int i) => setState(() {
        _pendingLeft = _pendingLeft == i ? null : i;
        _checked = false;
        _result = null;
      });

  void _tapRight(int r) {
    final l = _pendingLeft;
    if (l == null) return;
    setState(() {
      _links.removeWhere((k, v) => v == r);
      _links[l] = r;
      _pendingLeft = null;
      _checked = false;
      _result = null;
    });
  }

  Color _lineColor(int l, int r) {
    if (!_checked) return widget.accent;
    return widget.isCorrect(l, r) ? widget.ctx.theme.correct : widget.ctx.theme.wrong;
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final rows = widget.left.length > widget.right.length
        ? widget.left.length
        : widget.right.length;
    final dotColor = ctx.theme.print ? ctx.theme.ink : widget.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ctx.interactive)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(ctx.firstLabel('tap_to_match'),
                style: ctx.base.copyWith(fontSize: 12, color: ctx.theme.muted)),
          ),
        CustomPaint(
          key: _paintKey,
          foregroundPainter: _LinksPainter(
            host: _paintKey,
            left: _leftDots,
            right: _rightDots,
            links: Map.of(_links),
            color: _lineColor,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: i < widget.left.length
                              ? _tile(
                                  ctx,
                                  border: _pendingLeft == i ? widget.accent : null,
                                  borderWidth: _pendingLeft == i ? 2.4 : 1.2,
                                  onTap: () => _tapLeft(i),
                                  child: Center(child: widget.left[i]),
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(
                          width: 26,
                          child: i < widget.left.length
                              ? Center(child: _dot(_leftDots[i], dotColor))
                              : null,
                        ),
                        const SizedBox(width: 30),
                        SizedBox(
                          width: 26,
                          child: i < widget.right.length
                              ? Center(child: _dot(_rightDots[i], dotColor))
                              : null,
                        ),
                        Expanded(
                          flex: 4,
                          child: i < widget.right.length
                              ? _tile(
                                  ctx,
                                  onTap: () => _tapRight(i),
                                  child: Center(
                                    child: Text(widget.right[i],
                                        textAlign: TextAlign.center,
                                        style: ctx.base.copyWith(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _CheckRow(ctx,
            result: _result,
            onCheck: () => setState(() {
                  _checked = true;
                  _result = _links.length == widget.left.length &&
                      _links.entries.every((e) => widget.isCorrect(e.key, e.value));
                }),
            onReset: () => setState(() {
                  _links.clear();
                  _pendingLeft = null;
                  _checked = false;
                  _result = null;
                })),
      ],
    );
  }

  Widget _dot(Key key, Color color) => Container(
        key: key,
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _LinksPainter extends CustomPainter {
  final GlobalKey host;
  final List<GlobalKey> left;
  final List<GlobalKey> right;
  final Map<int, int> links;
  final Color Function(int l, int r) color;

  _LinksPainter({
    required this.host,
    required this.left,
    required this.right,
    required this.links,
    required this.color,
  });

  Offset? _center(GlobalKey key, RenderBox hostBox) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero), ancestor: hostBox);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hostBox = host.currentContext?.findRenderObject();
    if (hostBox is! RenderBox) return;
    for (final e in links.entries) {
      final a = _center(left[e.key], hostBox);
      final b = _center(right[e.value], hostBox);
      if (a == null || b == null) continue;
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color(e.key, e.value)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinksPainter old) => true;
}

// ---- Tracing ---------------------------------------------------------------

class _TraceBody extends StatefulWidget {
  final _Ctx ctx;
  final WorksheetBlock block;
  final Color accent;
  const _TraceBody(
      {super.key, required this.ctx, required this.block, required this.accent});

  @override
  State<_TraceBody> createState() => _TraceBodyState();
}

class _TraceBodyState extends State<_TraceBody> {
  final Set<int> _traced = {};

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final items = widget.block.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ctx.interactive)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(ctx.firstLabel('tap_to_trace'),
                style: ctx.base.copyWith(fontSize: 12, color: ctx.theme.muted)),
          ),
        _tile(
          ctx,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                Flexible(
                  child: GestureDetector(
                    onTap: ctx.interactive
                        ? () => setState(() =>
                            _traced.contains(i) ? _traced.remove(i) : _traced.add(i))
                        : null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Stack(
                        children: [
                          Text(items[i],
                              style: TextStyle(
                                fontSize: 78,
                                fontWeight: FontWeight.w300,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 1.6
                                  ..color = ctx.theme.print
                                      ? ctx.theme.ink
                                      : ctx.theme.muted,
                              )),
                          if (_traced.contains(i))
                            Text(items[i],
                                style: TextStyle(
                                  fontSize: 78,
                                  fontWeight: FontWeight.w300,
                                  color: widget.accent,
                                )),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(10)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) => old.color != color;
}

class _DottedLine extends StatelessWidget {
  final Color color;
  const _DottedLine({required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(double.infinity, 12), painter: _DotsPainter(color));
}

class _DotsPainter extends CustomPainter {
  final Color color;
  _DotsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawCircle(Offset(x, size.height - 1), 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.color != color;
}
