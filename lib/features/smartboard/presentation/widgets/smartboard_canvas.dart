import 'dart:math' as math;

import 'package:flutter/material.dart';

/// MAATRIBHASHA SMARTBOARD — classroom whiteboard tools.
///
/// Pen = default handwriting/diagram ink.
/// Highlighter = wide translucent overlay.
/// Eraser = stroke-based (removes whole strokes it touches).
enum SmartBoardTool {
  pen,
  highlighter,
  eraser,
}

/// One freehand stroke on the classroom board.
class SmartBoardStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  SmartBoardStroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

/// Controller for the classroom board canvas.
///
/// Owns strokes + undo/redo stacks. Lives in the SmartBoard screen state so
/// switching between Write & Draw ↔ Santali Board never erases the board —
/// only explicit Clear / New Board does. Undo/redo history is fully
/// independent of translation data.
class SmartBoardCanvasController extends ChangeNotifier {
  final List<SmartBoardStroke> _strokes = [];
  final List<SmartBoardStroke> _redoStack = [];

  SmartBoardTool tool = SmartBoardTool.pen;

  /// Default classroom pen ink (dark navy).
  static const Color penInk = Color(0xFF123B68);
  static const double penWidth = 3.5;

  /// Highlighter: wide + translucent classroom accent (dark green wash).
  static const Color highlighterInk = Color(0x590B8F61);
  static const double highlighterWidth = 16.0;

  /// Stroke-eraser hit radius (logical px).
  static const double eraserRadius = 22.0;

  List<SmartBoardStroke> get strokes =>
      List<SmartBoardStroke>.unmodifiable(_strokes);

  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasContent => _strokes.isNotEmpty;

  void setTool(SmartBoardTool value) {
    if (tool == value) return;
    tool = value;
    _finishOpenStroke();
    notifyListeners();
  }

  SmartBoardStroke? _open;

  void _finishOpenStroke() {
    _open = null;
  }

  void startStroke(Offset point) {
    _redoStack.clear();
    _open = SmartBoardStroke(
      points: [point],
      color: tool == SmartBoardTool.highlighter ? highlighterInk : penInk,
      width: tool == SmartBoardTool.highlighter
          ? highlighterWidth
          : penWidth,
    );
    _strokes.add(_open!);
    notifyListeners();
  }

  void appendPoint(Offset point) {
    final open = _open;
    if (open == null) return;
    // Drop duplicate consecutive points to keep the path cheap.
    if (open.points.isNotEmpty && open.points.last == point) return;
    open.points.add(point);
    notifyListeners();
  }

  void endStroke() {
    _finishOpenStroke();
  }

  /// Stroke-based eraser: removes every stroke touched by [point].
  /// Returns true when at least one stroke was removed.
  bool eraseAt(Offset point) {
    _finishOpenStroke();
    final before = _strokes.length;
    _strokes.removeWhere(
      (stroke) => _strokeHit(stroke, point, eraserRadius),
    );
    final removed = _strokes.length != before;
    if (removed) {
      // A destructive edit invalidates the redo stack.
      _redoStack.clear();
      notifyListeners();
    }
    return removed;
  }

  static bool _strokeHit(
      SmartBoardStroke stroke, Offset point, double tolerance) {
    final pts = stroke.points;
    if (pts.isEmpty) return false;
    final hitWidth = tolerance + stroke.width / 2;
    if (pts.length == 1) {
      return (pts.first - point).distance <= hitWidth;
    }
    for (var i = 0; i < pts.length - 1; i++) {
      if (_distToSegment(point, pts[i], pts[i + 1]) <= hitWidth) return true;
    }
    return false;
  }

  static double _distToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) /
            (dx * dx + dy * dy))
        .clamp(0.0, 1.0);
    final cx = a.dx + t * dx;
    final cy = a.dy + t * dy;
    return math.sqrt(
        (p.dx - cx) * (p.dx - cx) + (p.dy - cy) * (p.dy - cy));
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _finishOpenStroke();
    _redoStack.add(_strokes.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _strokes.add(_redoStack.removeLast());
    notifyListeners();
  }

  void clear() {
    if (_strokes.isEmpty && _redoStack.isEmpty) return;
    _finishOpenStroke();
    _strokes.clear();
    _redoStack.clear();
    notifyListeners();
  }
}

class _BoardPainter extends CustomPainter {
  final List<SmartBoardStroke> strokes;

  _BoardPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
  }

  /// Simple smoothed freehand stroke: midpoint quadratic path with round
  /// caps/joins. Cheap enough for classroom use, no brush physics.
  void _paintStroke(Canvas canvas, SmartBoardStroke stroke) {
    final pts = stroke.points;
    if (pts.isEmpty) return;
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (pts.length == 1) {
      canvas.drawCircle(
        pts.first,
        stroke.width / 2,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill,
      );
      return;
    }
    if (pts.length == 2) {
      canvas.drawLine(pts[0], pts[1], paint);
      return;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}

/// Full-area interactive classroom board canvas.
///
/// * Fills whatever space the parent gives it (use inside `Expanded`) —
///   never a fixed small height.
/// * Raw [Listener] pointer events (down/move/up/cancel) instead of gesture
///   recognisers, so page scroll views cannot steal strokes and there is no
///   gesture-arena delay. Works with finger, stylus and mouse alike.
/// * Coordinates are converted per-event against this widget's own RenderBox
///   (via [boardKey]), so strokes land correctly after resizes and
///   orientation changes, edge to edge.
/// * [ClipRect] (square) clips only true overflow — strokes near edges and
///   corners stay fully visible.
class SmartBoardCanvas extends StatefulWidget {
  final SmartBoardCanvasController controller;

  const SmartBoardCanvas({super.key, required this.controller});

  @override
  State<SmartBoardCanvas> createState() => _SmartBoardCanvasState();
}

class _SmartBoardCanvasState extends State<SmartBoardCanvas> {
  final GlobalKey _boardKey = GlobalKey();
  bool _drawing = false;
  bool _erasing = false;

  Offset? _toLocal(Offset globalPosition) {
    final box =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(globalPosition);
  }

  void _onDown(PointerDownEvent event) {
    final local = _toLocal(event.position);
    if (local == null) return;
    if (widget.controller.tool == SmartBoardTool.eraser) {
      _erasing = true;
      widget.controller.eraseAt(local);
    } else {
      _drawing = true;
      widget.controller.startStroke(local);
    }
  }

  void _onMove(PointerMoveEvent event) {
    final local = _toLocal(event.position);
    if (local == null) return;
    if (_erasing) {
      widget.controller.eraseAt(local);
    } else if (_drawing) {
      widget.controller.appendPoint(local);
    }
  }

  void _onUp(PointerUpEvent event) {
    _drawing = false;
    _erasing = false;
    widget.controller.endStroke();
  }

  void _onCancel(PointerCancelEvent event) {
    _drawing = false;
    _erasing = false;
    widget.controller.endStroke();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _boardKey,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E0E7), width: 1),
      ),
      child: ClipRect(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onCancel,
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _BoardPainter(widget.controller.strokes),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ),
    );
  }
}
