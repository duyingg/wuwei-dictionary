import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

final _strokePathCache = <String, Future<List<Path>>>{};

Future<List<Path>> _loadStrokePaths(String assetPath) =>
    _strokePathCache.putIfAbsent(assetPath, () async {
      final source = await rootBundle.loadString(assetPath);
      return parseStrokePaths(source);
    });

class HanziGlyph extends StatelessWidget {
  const HanziGlyph({
    required this.character,
    required this.assetPath,
    super.key,
    this.color,
  });
  final String character;
  final String assetPath;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: character,
        image: true,
        child: FutureBuilder<List<Path>>(
          future: _loadStrokePaths(assetPath),
          builder: (context, snapshot) {
            final strokes = snapshot.data;
            if (strokes == null || strokes.isEmpty) {
              return Center(
                child: Text(character,
                    style: TextStyle(
                        color:
                            color ?? Theme.of(context).colorScheme.onSurface)),
              );
            }
            return CustomPaint(
              painter: _GlyphPainter(
                strokes: strokes,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
            );
          },
        ),
      );
}

class StrokeOrderView extends StatefulWidget {
  const StrokeOrderView({required this.assetPath, super.key});
  final String assetPath;

  @override
  State<StrokeOrderView> createState() => _StrokeOrderViewState();
}

class _StrokeOrderViewState extends State<StrokeOrderView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<Path>? _strokes;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    try {
      final paths = await _loadStrokePaths(widget.assetPath);
      if (!mounted) {
        return;
      }
      setState(() => _strokes = paths);
      _controller.duration = Duration(
        milliseconds: (paths.length * 520).clamp(1200, 16000),
      );
      _controller.repeat();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const Center(child: Text('笔顺资源暂时无法显示'));
    }
    final strokes = _strokes;
    if (strokes == null || strokes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final visible = (_controller.value * strokes.length).floor() + 1;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _StrokePainter(
              strokes: strokes,
              visibleCount: visible,
              gridColor: Theme.of(context).dividerColor,
              completedColor: Theme.of(context).colorScheme.onSurface,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('$visible / ${strokes.length}'),
            ),
          ),
        ),
      ],
    );
  }
}

@visibleForTesting
List<Path> parseStrokePaths(String source) =>
    RegExp(r'<path\s+d="([^"]+)"\s+fill="lightgray"')
        .allMatches(source)
        .map((match) => parseSvgPathData(match.group(1)!))
        .toList(growable: false);

class _StrokePainter extends CustomPainter {
  const _StrokePainter({
    required this.strokes,
    required this.visibleCount,
    required this.gridColor,
    required this.completedColor,
    required this.activeColor,
  });
  final List<Path> strokes;
  final int visibleCount;
  final Color gridColor;
  final Color completedColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final rect = origin & Size.square(side);
    canvas.drawRect(rect, grid..style = PaintingStyle.stroke);
    canvas.drawLine(rect.topLeft, rect.bottomRight, grid);
    canvas.drawLine(rect.topRight, rect.bottomLeft, grid);
    canvas.drawLine(rect.centerLeft, rect.centerRight, grid);
    canvas.drawLine(rect.topCenter, rect.bottomCenter, grid);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    final scale = side / 1024;
    canvas.scale(scale, scale);
    canvas.translate(0, 900);
    canvas.scale(1, -1);

    final guidePaint = Paint()
      ..color = gridColor.withValues(alpha: .38)
      ..style = PaintingStyle.fill;
    for (final path in strokes) {
      canvas.drawPath(path, guidePaint);
    }
    final completedPaint = Paint()
      ..color = completedColor
      ..style = PaintingStyle.fill;
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    for (var index = 0;
        index < visibleCount && index < strokes.length;
        index++) {
      canvas.drawPath(
        strokes[index],
        index == visibleCount - 1 ? activePaint : completedPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) =>
      oldDelegate.visibleCount != visibleCount ||
      oldDelegate.strokes != strokes ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.completedColor != completedColor ||
      oldDelegate.activeColor != activeColor;
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.strokes, required this.color});
  final List<Path> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    final scale = side / 1024;
    canvas.scale(scale, scale);
    canvas.translate(0, 900);
    canvas.scale(1, -1);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final path in strokes) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.color != color;
}
